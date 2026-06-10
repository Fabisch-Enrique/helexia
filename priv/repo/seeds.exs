defmodule Helexia.Seeds do
  @moduledoc """

  Seeds module
  """

  require Logger

  Logger.configure(level: :info)
  env = Application.compile_env(:helexia, :env)

  if env != :test do
    prod_blacklist = []

    [
      "pilots.exs",
      "members.exs"
    ]
    |> Enum.reject(&(&1 in prod_blacklist and env == :prod))
    |> Enum.each(fn file ->
      Code.require_file("#{:code.priv_dir(:helexia)}/repo/seeds/#{file}", __DIR__)
    end)
  else
    """

    [Seeds] Skipping seeds for: #{env} Environment
    """
    |> Logger.warning()
  end

  Logger.configure(level: :debug)
end
