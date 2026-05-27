defmodule Helexia.Repo.Migrations.CreateTableMembers do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    create table(:members) do
      add :name, :string
      add :slug, :string
      add :title, :string
      add :level, :integer
      add :image_url, :string
      add :display_order, :integer
      add :email, :citext, null: false
      add :status, :string, default: "active"
      add :expertise, {:array, :string}, default: ["advisory"]

      timestamps(type: :utc_datetime)
    end

    create(index(:members, [:display_order, :level, :title, :slug, :email, :name]))
    create unique_index(:members, [:email])
  end
end
