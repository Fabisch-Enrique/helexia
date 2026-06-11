defmodule Helexia.Chat.WhatsApp do
  use VCUtils.HTTPClient

  require Logger

  alias Helexia.Chat.Message

  def send_visitor_message(%Message{} = message) do
    config = config!()

    body = """
    [WEB-#{message.conversation.conversation_code}]
    #{visitor_label(message.conversation)}

    #{message.body}

    Reply directly to this WhatsApp message so the response returns to the correct website visitor.
    """

    request_body = %{
      type: "text",
      text: %{
        body: body,
        preview_url: false
      },
      to: config.agent_phone,
      recipient_type: "individual",
      messaging_product: "whatsapp"
    }

    url =
      "#{config.graph_url}/#{config.api_version}/" <>
        "#{config.phone_number_id}/messages"

    headers = [
      {"authorization", "Bearer #{config.access_token}"},
      {"content-type", "application/json"}
    ]

    case Req.post(
           url,
           json: request_body,
           headers: headers,
           receive_timeout: 15_000,
           retry: false
         ) do
      {:ok, %{status: status, body: response}}
      when status in 200..299 ->
        provider_message_id =
          get_in(
            response,
            ["messages", Access.at(0), "id"]
          )

        if is_binary(provider_message_id) do
          {:ok,
           %{
             provider_message_id: provider_message_id,
             provider_payload: response
           }}
        else
          {:error, :missing_provider_message_id}
        end

      {:ok, %{status: status, body: response}} ->
        Logger.warning("WhatsApp rejected message status=#{status}")

        {:error, {:whatsapp_error, status, response}}

      {:error, reason} ->
        {:error, {:transport_error, reason}}
    end
  end

  defp visitor_label(conversation),
    do:
      conversation.visitor_name ||
        "Anonymous website visitor"

  defp config! do
    config =
      Application.fetch_env!(
        :my_app,
        __MODULE__
      )

    %{
      graph_url:
        Keyword.get(
          config,
          :graph_url,
          "https://graph.facebook.com"
        ),
      api_version: Keyword.fetch!(config, :api_version),
      phone_number_id: Keyword.fetch!(config, :phone_number_id),
      access_token: Keyword.fetch!(config, :access_token),
      agent_phone: normalize_phone(Keyword.fetch!(config, :agent_phone))
    }
  end

  def normalize_phone(phone) do
    String.replace(phone, ~r/[^\d]/, "")
  end
end
