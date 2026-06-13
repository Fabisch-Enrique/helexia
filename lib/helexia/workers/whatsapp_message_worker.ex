defmodule Helexia.Workers.WhatsappMessageWorker do
  use Oban.Worker,
    queue: :whatsapp,
    max_attempts: 8,
    unique: [
      fields: [:worker, :args],
      keys: [:message_id],
      period: :infinity,
      states: [
        :available,
        :scheduled,
        :executing,
        :retryable,
        :suspended,
        :completed
      ]
    ]

  alias Helexia.Chat
  alias Helexia.Chat.WhatsApp

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message_id" => message_id}}) do
    message =
      Chat.get_message_for_delivery!(message_id)

    case message.status do
      status
      when status in ["sent", "delivered", "read"] ->
        :ok

      _ ->
        deliver(message)
    end
  end

  defp deliver(message) do
    with {:ok, result} <- WhatsApp.send_visitor_message(message),
         {:ok, _message} <-
           Chat.mark_message_sent(message, result.provider_message_id, result.provider_payload) do
      :ok
    else
      {:error, reason} ->
        Chat.mark_message_failed(message, reason)
        {:error, reason}
    end
  end
end
