defmodule Helexia.Members.Member do
  @moduledoc """

  Members Schema
  """
  use Helexia.Schema

  @required_fields ~w(name email title image_url)a
  @fields ~w(name slug title email image_url status expertise display_order level )a

  typed_schema "members" do
    field :slug, :string
    field :name, :string
    field :email, :string
    field :title, :string
    field :level, :integer
    field :image_url, :string
    field :display_order, :integer
    field :expertise, {:array, :string}
    field :status, :string, default: "active"

    timestamps(type: :utc_datetime)
  end

  def_crud([:create, :get, :modify, :delete])

  defbyq([
    :id,
    :email,
    :title,
    :display_order,
    {:name, :search},
    {:inserted_at, :date}
  ])

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @fields)
    |> cast_slug(:title)
    |> validate_required(@required_fields)
    |> unique_constraint(:email, name: "users_email_index", message: "email is already taken")
  end
end
