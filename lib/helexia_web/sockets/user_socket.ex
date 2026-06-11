defmodule HelexiaWeb.UserSocket do
  use Phoenix.Socket

  channel "website_chat:*",
          HelexiaWeb.ChatChannel

  @impl true
  def connect(params, socket, _connect_info) do
    with %{
           "conversation_id" => conversation_id,
           "visitor_token" => visitor_token
         } <- params,
         {:ok, _conversation} <-
           Helexia.Chat.get_authorized_conversation(
             conversation_id,
             visitor_token
           ) do
      {:ok,
       assign(socket,
         conversation_id: conversation_id,
         visitor_token: visitor_token
       )}
    else
      _ -> :error
    end
  end

  @impl true
  def id(_socket), do: nil
end
