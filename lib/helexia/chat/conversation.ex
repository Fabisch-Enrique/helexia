defmodule Helexia.Chat.Conversation do
  use Helexia.Schema

  alias Helexia.Chat.Message

  @statuses ~w(open waiting closed)

  schema "chat_conversations" do
    field :public_id, Ecto.UUID
    field :visitor_token_hash, :binary

    field :visitor_name, :string
    field :visitor_email, :string

    field :status, :string
    field :conversation_code, :string
    field :agent_phone, :string

    field :last_message_at, :utc_datetime_usec
    field :closed_at, :utc_datetime_usec

    has_many :messages, Message

    timestamps(type: :utc_datetime_usec)
  end

  def create_changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [
      :status,
      :public_id,
      :agent_phone,
      :visitor_name,
      :visitor_email,
      :last_message_at,
      :conversation_code,
      :visitor_token_hash
    ])
    |> validate_required([
      :public_id,
      :visitor_token_hash,
      :conversation_code,
      :agent_phone,
      :status
    ])
    |> validate_inclusion(:status, @statuses)
    |> validate_length(:visitor_name, max: 120)
    |> validate_format(
      :visitor_email,
      ~r/^[^\s]+@[^\s]+$/,
      allow_nil: true
    )
    |> unique_constraint(:public_id)
    |> unique_constraint(:conversation_code)
  end
end
