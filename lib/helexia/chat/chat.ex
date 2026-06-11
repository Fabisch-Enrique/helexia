defmodule Helexia.Chat do
  use Helexia.Schema

  alias Ecto.Multi
  alias Helexia.Repo
  alias Helexia.Chat.{Conversation, Message}
  alias Helexia.Workers.WhatsappMessageWorker

  @pubsub MyApp.PubSub

  def create_conversation(attrs) do
    visitor_token =
      :crypto.strong_rand_bytes(32)
      |> Base.url_encode64(padding: false)

    token_hash = hash_token(visitor_token)

    conversation_attrs =
      attrs
      |> Map.put(:public_id, Ecto.UUID.generate())
      |> Map.put(:visitor_token_hash, token_hash)
      |> Map.put(:conversation_code, generate_code())
      |> Map.put(:status, "open")
      |> Map.put(:last_message_at, DateTime.utc_now())

    case %Conversation{}
         |> Conversation.create_changeset(conversation_attrs)
         |> Repo.insert() do
      {:ok, conversation} ->
        {:ok, conversation, visitor_token}

      error ->
        error
    end
  end

  def get_authorized_conversation(public_id, visitor_token)
      when is_binary(public_id) and is_binary(visitor_token) do
    token_hash = hash_token(visitor_token)

    from(c in Conversation,
      where:
        c.public_id == ^public_id and
          c.visitor_token_hash == ^token_hash
    )
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      conversation -> {:ok, conversation}
    end
  end

  def get_authorized_conversation(_, _),
    do: {:error, :not_found}

  def list_messages(%Conversation{id: id}) do
    from(m in Message,
      where: m.conversation_id == ^id,
      order_by: [asc: m.inserted_at],
      limit: 100
    )
    |> Repo.all()
  end

  def create_visitor_message(
        %Conversation{} = conversation,
        attrs
      ) do
    now = DateTime.utc_now()

    message_attrs = %{
      public_id: Ecto.UUID.generate(),
      conversation_id: conversation.id,
      client_message_id: Map.fetch!(attrs, :client_message_id),
      body: Map.fetch!(attrs, :body),
      sender_type: "visitor",
      direction: "visitor_to_agent",
      status: "pending"
    }

    Multi.new()
    |> Multi.insert(
      :message,
      Message.visitor_changeset(
        %Message{},
        message_attrs
      )
    )
    |> Multi.update_all(
      :conversation,
      from(c in Conversation,
        where: c.id == ^conversation.id
      ),
      set: [
        last_message_at: now,
        status: "open",
        updated_at: now
      ]
    )
    |> Multi.run(:job, fn _repo, %{message: message} ->
      message.id
      |> then(&%{"message_id" => &1})
      |> WhatsAppMessageWorker.new()
      |> Oban.insert()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{message: message}} ->
        broadcast_message(message)
        {:ok, message}

      {:error, :message, changeset, _} ->
        recover_duplicate_message(changeset)

      {:error, step, reason, _} ->
        {:error, {step, reason}}
    end
  end

  def get_message_for_delivery!(id) do
    Message
    |> Repo.get!(id)
    |> Repo.preload(:conversation)
  end

  def mark_message_sent(
        %Message{} = message,
        provider_message_id,
        provider_payload
      ) do
    now = DateTime.utc_now()

    message
    |> Ecto.Changeset.change(%{
      status: "sent",
      provider_message_id: provider_message_id,
      provider_payload: provider_payload,
      sent_at: now,
      error_reason: nil
    })
    |> Repo.update()
    |> tap_success(&broadcast_message/1)
  end

  def mark_message_failed(
        %Message{} = message,
        reason
      ) do
    message
    |> Ecto.Changeset.change(%{
      status: "failed",
      error_reason: inspect(reason)
    })
    |> Repo.update()
    |> tap_success(&broadcast_message/1)
  end

  def create_agent_reply(attrs) do
    with {:ok, conversation} <-
           resolve_conversation_for_reply(attrs) do
      now = DateTime.utc_now()

      changeset =
        Message.agent_changeset(
          %Message{},
          %{
            public_id: Ecto.UUID.generate(),
            conversation_id: conversation.id,
            body: attrs.body,
            provider_message_id: attrs.provider_message_id,
            provider_context_message_id: attrs.context_message_id,
            provider_payload: attrs.raw_payload,
            sender_type: "agent",
            direction: "agent_to_visitor",
            status: "sent",
            sent_at: now
          }
        )

      Multi.new()
      |> Multi.insert(:message, changeset)
      |> Multi.update_all(
        :conversation,
        from(c in Conversation,
          where: c.id == ^conversation.id
        ),
        set: [
          last_message_at: now,
          status: "open",
          updated_at: now
        ]
      )
      |> Repo.transaction()
      |> case do
        {:ok, %{message: message}} ->
          broadcast_message(message)
          {:ok, message}

        {:error, :message, changeset, _} ->
          if duplicate_provider_message?(changeset) do
            {:ok, :duplicate}
          else
            {:error, changeset}
          end

        {:error, step, reason, _} ->
          {:error, {step, reason}}
      end
    end
  end

  def update_provider_status(provider_message_id, status) do
    case Repo.get_by(
           Message,
           provider_message_id: provider_message_id
         ) do
      nil ->
        {:ok, :ignored}

      message ->
        attrs = status_attributes(status)

        message
        |> Ecto.Changeset.change(attrs)
        |> Repo.update()
        |> tap_success(&broadcast_message/1)
    end
  end

  defp resolve_conversation_for_reply(%{
         context_message_id: context_id
       })
       when is_binary(context_id) do
    from(c in Conversation,
      join: m in Message,
      on: m.conversation_id == c.id,
      where: m.provider_message_id == ^context_id,
      limit: 1
    )
    |> Repo.one()
    |> case do
      nil -> {:error, :conversation_not_found}
      conversation -> {:ok, conversation}
    end
  end

  defp resolve_conversation_for_reply(%{body: body}) do
    case Regex.run(
           ~r/\[WEB-([A-Z0-9]+)\]/,
           body,
           capture: :all_but_first
         ) do
      [code] ->
        case Repo.get_by(
               Conversation,
               conversation_code: code
             ) do
          nil -> {:error, :conversation_not_found}
          conversation -> {:ok, conversation}
        end

      _ ->
        {:error, :missing_conversation_reference}
    end
  end

  defp status_attributes("delivered") do
    %{
      status: "delivered",
      delivered_at: DateTime.utc_now()
    }
  end

  defp status_attributes("read") do
    %{
      status: "read",
      delivered_at: DateTime.utc_now(),
      read_at: DateTime.utc_now()
    }
  end

  defp status_attributes("failed") do
    %{status: "failed"}
  end

  defp status_attributes(_), do: %{}

  defp broadcast_message(%Message{} = message) do
    message = Repo.preload(message, :conversation)

    Phoenix.PubSub.broadcast(
      @pubsub,
      topic(message.conversation.public_id),
      {:chat_message_updated, message}
    )
  end

  def topic(public_id),
    do: "website_chat:#{public_id}"

  def hash_token(token) do
    :crypto.hash(:sha256, token)
  end

  defp generate_code do
    :crypto.strong_rand_bytes(5)
    |> Base.encode32(case: :upper, padding: false)
  end

  defp recover_duplicate_message(changeset) do
    if duplicate_client_message?(changeset) do
      client_message_id =
        Ecto.Changeset.get_field(
          changeset,
          :client_message_id
        )

      {:ok,
       Repo.get_by!(
         Message,
         client_message_id: client_message_id
       )}
    else
      {:error, changeset}
    end
  end

  defp duplicate_client_message?(changeset) do
    Enum.any?(
      changeset.errors,
      fn
        {:client_message_id, {_message, metadata}} ->
          metadata[:constraint] == :unique

        _ ->
          false
      end
    )
  end

  defp duplicate_provider_message?(changeset) do
    Enum.any?(
      changeset.errors,
      fn
        {:provider_message_id, {_message, metadata}} ->
          metadata[:constraint] == :unique

        _ ->
          false
      end
    )
  end

  defp tap_success({:ok, value} = result, callback) do
    callback.(value)
    result
  end

  defp tap_success(result, _callback), do: result
end
