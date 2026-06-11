defmodule HelexiaWeb.Webhooks.WhatsappWebHook do
  use HelexiaWeb, :controller

  alias Helexia.Workers.WhatsAppWebhookWorker

  def verify(conn, params) do
    expected_token =
      System.fetch_env!("WHATSAPP_WEBHOOK_VERIFY_TOKEN")

    case params do
      %{
        "hub.mode" => "subscribe",
        "hub.verify_token" => ^expected_token,
        "hub.challenge" => challenge
      } ->
        send_resp(conn, 200, challenge)

      _ ->
        send_resp(conn, 403, "Verification failed")
    end
  end

  def receive(conn, payload) do
    raw_body =
      conn.private[:raw_body] ||
        Jason.encode!(payload)

    with :ok <-
           verify_signature(conn, raw_body),
         {:ok, _job} <-
           payload
           |> then(&%{"payload" => &1})
           |> WhatsAppWebhookWorker.new()
           |> Oban.insert() do
      send_resp(conn, 200, "EVENT_RECEIVED")
    else
      {:error, :invalid_signature} ->
        send_resp(conn, 401, "Invalid signature")

      {:error, _reason} ->
        send_resp(conn, 500, "Unable to enqueue webhook")
    end
  end

  defp verify_signature(conn, raw_body) do
    app_secret =
      System.fetch_env!("META_APP_SECRET")

    expected =
      "sha256=" <>
        Base.encode16(
          :crypto.mac(
            :hmac,
            :sha256,
            app_secret,
            raw_body
          ),
          case: :lower
        )

    supplied =
      conn
      |> get_req_header("x-hub-signature-256")
      |> List.first()

    if secure_compare(expected, supplied) do
      :ok
    else
      {:error, :invalid_signature}
    end
  end

  defp secure_compare(expected, supplied)
       when is_binary(expected) and
              is_binary(supplied) and
              byte_size(expected) ==
                byte_size(supplied) do
    Plug.Crypto.secure_compare(
      expected,
      supplied
    )
  end

  defp secure_compare(_, _), do: false
end
