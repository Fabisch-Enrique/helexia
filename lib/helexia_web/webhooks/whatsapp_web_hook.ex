defmodule HelexiaWeb.Webhooks.WhatsappWebHook do
  use HelexiaWeb, :controller

  alias Helexia.Workers.WhatsappWorker

  def config, do: Application.fetch_env!(:helexia, Helexia.Chat.Whatsapp)
  def config(key), do: config() |> Keyword.fetch!(key)

  def verify(conn, params) do
    expected_token = config(:whatsapp_webhook_verify_token)

    case params do
      %{
        "hub.mode" => "subscribe",
        "hub.challenge" => challenge,
        "hub.verify_token" => ^expected_token
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

    with :ok <- verify_signature(conn, raw_body),
         {:ok, _job} <-
           payload
           |> then(&%{"payload" => &1})
           |> WhatsappWorker.new()
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
    app_secret = config(:whatsapp_secret)

    expected =
      "sha256=" <> Base.encode16(:crypto.mac(:hmac, :sha256, app_secret, raw_body), case: :lower)

    supplied =
      conn
      |> get_req_header("x-hub-signature-256")
      |> List.first()

    expected
    |> secure_compare(supplied)
    |> case do
      true ->
        :ok

      false ->
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
