defmodule Helexia.Release do
  defmodule SocialProtection.Release do
    @moduledoc """

    Used for executing DB release tasks when run in production without Mix installed.
    """
    require Logger

    @app :helexia

    def migrate do
      load_app()

      for repo <- repos() do
        {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
      end
    end

    def rollback(repo, version) do
      load_app()
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
    end

    def seed do
      for {app, repo, seed_files} <- seeds() do
        Logger.info("Running seeds for #{inspect(repo)}")

        for seed_file <- seed_files do
          Logger.info("Running #{inspect(seed_file)}")
          {:ok, _, _} = Ecto.Migrator.with_repo(repo, &eval_seed(app, &1, seed_file))
        end
      end
    end

    def setup(seed_file) when is_binary(seed_file) do
      Logger.info("Running setup seeds")

      Application.load(@app)

      {:ok, _, _} = Ecto.Migrator.with_repo(Helexia.Repo, &eval_seed(@app, &1, seed_file))
    end

    defp eval_seed(app, repo, seed_file) do
      app
      |> build_seeds_path(repo, seed_file)
      |> Code.eval_file()
    end

    defp seeds do
      [
        {:helexia, Helexia.Repo,
         [
           "seeds"
         ]}
      ]
    end

    defp build_seeds_path(app, repo, seed_file) do
      repo_underscore =
        repo
        |> Module.split()
        |> List.last()
        |> Macro.underscore()

      :code.priv_dir(app)

      path = Path.join([:code.priv_dir(app), repo_underscore, "#{seed_file}.exs"])

      if !File.regular?(path),
        do: raise("Seeds file #{IO.ANSI.red()}#{inspect(path)}#{IO.ANSI.reset()} not found.")

      path
    end

    defp repos do
      Application.fetch_env!(@app, :ecto_repos)
    end

    defp load_app do
      # Many platforms require SSL when connecting to the database
      Application.ensure_all_started(:ssl)
      Application.ensure_loaded(@app)
    end
  end
end
