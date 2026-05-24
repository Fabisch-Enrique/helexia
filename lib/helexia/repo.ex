defmodule Helexia.Repo do
  use Ecto.Repo,
    otp_app: :helexia,
    adapter: Ecto.Adapters.Postgres
end
