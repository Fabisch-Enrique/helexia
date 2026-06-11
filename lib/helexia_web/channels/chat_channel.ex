defmodule HelexiaWeb.ChatChannel do
  use HelexiaWeb, :channel

  alias Helexia.Chat

  @impl true
  def join(
        "website_chat:" <> conversation_id,
        _params,
        socket
      ) do
    if socket.assigns.conversation_id ==
         conversation_id do
      Phoenix.PubSub.subscribe(
        MyApp.PubSub,
        Chat.topic(conversation_id)
      )

      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(
        {:chat_message_updated, message},
        socket
      ) do
    push(socket, "message_updated", %{
      id: message.public_id,
      client_message_id: message.client_message_id,
      body: message.body,
      sender_type: message.sender_type,
      status: message.status,
      inserted_at: message.inserted_at
    })

    {:noreply, socket}
  end
end
