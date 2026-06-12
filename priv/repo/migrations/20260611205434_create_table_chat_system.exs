defmodule Helexia.Repo.Migrations.CreateChatSystem do
  use Ecto.Migration

  def change do
    create table(:chat_conversations) do
      add :visitor_name, :string
      add :visitor_email, :string
      add :public_id, :uuid, null: false
      add :visitor_token_hash, :binary, null: false

      add :status, :string,
        null: false,
        default: "open"

      add :conversation_code, :string, null: false
      add :agent_phone, :string, null: false

      add :last_message_at, :utc_datetime_usec
      add :closed_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(
             :chat_conversations,
             [:public_id]
           )

    create unique_index(
             :chat_conversations,
             [:conversation_code]
           )

    create index(
             :chat_conversations,
             [:visitor_token_hash]
           )

    create index(
             :chat_conversations,
             [:status, :last_message_at]
           )

    create table(:chat_messages) do
      add :public_id, :uuid, null: false

      add :conversation_id,
          references(
            :chat_conversations,
            on_delete: :delete_all
          ),
          null: false

      add :body, :text, null: false

      add :sender_type, :string, null: false
      add :direction, :string, null: false

      add :status, :string,
        null: false,
        default: "pending"

      add :client_message_id, :uuid

      add :provider_message_id, :string
      add :provider_context_message_id, :string

      add :provider_payload, :map
      add :error_reason, :text

      add :sent_at, :utc_datetime_usec
      add :delivered_at, :utc_datetime_usec
      add :read_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(
             :chat_messages,
             [:public_id]
           )

    create unique_index(
             :chat_messages,
             [:client_message_id],
             where: "client_message_id IS NOT NULL"
           )

    create unique_index(
             :chat_messages,
             [:provider_message_id],
             where: "provider_message_id IS NOT NULL"
           )

    create index(
             :chat_messages,
             [:conversation_id, :inserted_at]
           )
  end
end
