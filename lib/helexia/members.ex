defmodule Helexia.Members do
  use Helexia.Schema

  alias Helexia.Repo
  alias Helexia.Members.Member

  def list_team_by_level(level) do
    from(t in Member,
      where: t.level == ^level,
      order_by: [asc: t.display_order]
    )
    |> Repo.all()
  end
end
