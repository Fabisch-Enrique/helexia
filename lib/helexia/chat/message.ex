defmodule Helexia.Chat.Message do
  use Helexia.Schema

  alias Helexia.Chat.Conversation

  @sender_types ~w(visitor agent system)
  @directions ~w(visitor_to_agent agent_to_visitor)
  @statuses ~w(pending sent delivered read failed)

  schema "chat_messages" do
    field :public_id, Ecto.UUID
    field :body, :string

    field :status, :string
    field :direction, :string
    field :sender_type, :string

    field :client_message_id, Ecto.UUID
    field :provider_message_id, :string
    field :provider_context_message_id, :string

    field :error_reason, :string
    field :provider_payload, :map

    field :sent_at, :utc_datetime_usec
    field :read_at, :utc_datetime_usec
    field :delivered_at, :utc_datetime_usec

    belongs_to :conversation, Conversation

    timestamps(type: :utc_datetime_usec)
  end

  def visitor_changeset(message, attrs) do
    message
    |> cast(attrs, [
      :public_id,
      :conversation_id,
      :body,
      :client_message_id,
      :sender_type,
      :direction,
      :status
    ])
    |> update_change(:body, &String.trim/1)
    |> validate_required([
      :public_id,
      :conversation_id,
      :body,
      :client_message_id,
      :sender_type,
      :direction,
      :status
    ])
    |> validate_length(:body, min: 1, max: 2_000)
    |> validate_inclusion(:sender_type, @sender_types)
    |> validate_inclusion(:direction, @directions)
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:client_message_id)
  end

  def agent_changeset(message, attrs) do
    message
    |> cast(attrs, [
      :public_id,
      :conversation_id,
      :body,
      :provider_message_id,
      :provider_context_message_id,
      :provider_payload,
      :sender_type,
      :direction,
      :status,
      :sent_at
    ])
    |> update_change(:body, &String.trim/1)
    |> validate_required([
      :public_id,
      :conversation_id,
      :body,
      :provider_message_id,
      :sender_type,
      :direction,
      :status
    ])
    |> validate_length(:body, min: 1, max: 2_000)
    |> unique_constraint(:provider_message_id)
  end
end
