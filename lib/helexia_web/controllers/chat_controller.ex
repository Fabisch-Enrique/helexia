defmodule HelexiaWeb.ChatController do
  use HelexiaWeb, :controller

  alias Helexia.Chat

  # action_fallback HelexiaWeb.FallbackController

  def create_conversation(conn, params) do
    agent_phone = "+254701161418"
    # System.fetch_env!("WHATSAPP_AGENT_PHONE")

    attrs = %{
      visitor_name: blank_to_nil(params["name"]),
      visitor_email: blank_to_nil(params["email"]),
      agent_phone: agent_phone
    }

    case Chat.create_conversation(attrs) do
      {:ok, conversation, visitor_token} ->
        json(conn, %{
          data: %{
            conversation_id: conversation.public_id,
            visitor_token: visitor_token,
            conversation_code: conversation.conversation_code
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: "Unable to start conversation",
          details: translate_errors(changeset)
        })
    end
  end

  def show(conn, %{
        "id" => public_id
      }) do
    with {:ok, visitor_token} <-
           extract_bearer_token(conn),
         {:ok, conversation} <-
           Chat.get_authorized_conversation(
             public_id,
             visitor_token
           ) do
      messages =
        Chat.list_messages(conversation)

      json(conn, %{
        data: %{
          conversation: %{
            id: conversation.public_id,
            code: conversation.conversation_code,
            status: conversation.status
          },
          messages: Enum.map(messages, &serialize_message/1)
        }
      })
    else
      _ ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Conversation not found"})
    end
  end

  def create_message(conn, %{
        "conversation_id" => public_id,
        "body" => body,
        "client_message_id" => client_message_id
      }) do
    with {:ok, visitor_token} <-
           extract_bearer_token(conn),
         {:ok, conversation} <-
           Chat.get_authorized_conversation(
             public_id,
             visitor_token
           ),
         {:ok, message} <-
           Chat.create_visitor_message(
             conversation,
             %{
               body: body,
               client_message_id: client_message_id
             }
           ) do
      conn
      |> put_status(:created)
      |> json(%{
        data: serialize_message(message)
      })
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: "Invalid message",
          details: translate_errors(changeset)
        })

      _ ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Conversation not found"})
    end
  end

  defp serialize_message(message) do
    %{
      id: message.public_id,
      client_message_id: message.client_message_id,
      body: message.body,
      sender_type: message.sender_type,
      status: message.status,
      inserted_at: message.inserted_at
    }
  end

  defp extract_bearer_token(conn) do
    case get_req_header(
           conn,
           "authorization"
         ) do
      ["Bearer " <> token]
      when byte_size(token) > 20 ->
        {:ok, token}

      _ ->
        {:error, :missing_token}
    end
  end

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(value) do
    case String.trim(value) do
      "" -> nil
      cleaned -> cleaned
    end
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(
      changeset,
      fn {message, _opts} -> message end
    )
  end
end
