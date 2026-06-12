defmodule HelexiaWeb.ChatChannel do
  use HelexiaWeb, :channel

  alias Helexia.Chat

  @impl true
  def join("website_chat:" <> conversation_id, _params, socket) do
    socket_id = socket.assigns.conversation_id

    socket_id
    |> id_is_same?(conversation_id)
    |> case do
      true ->
        Phoenix.PubSub.subscribe(Helexia.PubSub, Chat.topic(conversation_id))
        {:ok, socket}

      false ->
        {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info({:chat_message_updated, message}, socket) do
    push(socket, "message_updated", %{
      body: message.body,
      id: message.public_id,
      status: message.status,
      sender_type: message.sender_type,
      inserted_at: message.inserted_at,
      client_message_id: message.client_message_id
    })

    {:noreply, socket}
  end

  def id_is_same?(socket_id, conversation_id), do: match?(^socket_id, conversation_id)
end
