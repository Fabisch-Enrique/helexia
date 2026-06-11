defmodule HelexiaWeb.Workers.WhatsappWorker do
  use Oban.Worker,
    queue: :whatsapp_webhooks,
    max_attempts: 10

  alias Helexia.Chat
  alias Helexia.PayloadParser

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"payload" => payload}
      }) do
    payload
    |> PayloadParser.events()
    |> Enum.each(&process_event/1)

    :ok
  end

  defp process_event(
         %{
           type: :incoming_text
         } = event
       ) do
    case Chat.create_agent_reply(event) do
      {:ok, _message} ->
        :ok

      {:error, :missing_conversation_reference} ->
        :ok

      {:error, :conversation_not_found} ->
        :ok

      {:error, reason} ->
        raise "Webhook processing failed: " <>
                inspect(reason)
    end
  end

  defp process_event(%{
         type: :message_status,
         provider_message_id: id,
         status: status
       })
       when is_binary(id) do
    Chat.update_provider_status(id, status)
    :ok
  end

  defp process_event(_), do: :ok
end
