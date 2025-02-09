defmodule Sqlite.Ecto3.Mixfile do
  use Mix.Project

  def project do
    [app: :sqlite_ecto3,
     version: "2.4.0",
     name: "Sqlite.Ecto3",
     elixir: "~> 1.4",
     deps: deps(),
     elixirc_paths: elixirc_paths(Mix.env),

     # testing
     build_per_environment: false,
     test_paths: test_paths(),
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [
       coveralls: :test,
       "coveralls.detail": :test,
       "coveralls.html": :test,
       "coveralls.circle": :test
     ],

     # hex
     description: description(),
     package: package(),

     # docs
     docs: [main: Sqlite.Ecto3]]
  end

  # Configuration for the OTP application
  def application do
    [extra_applications: [:logger],
     mod: {Sqlite.DbConnection.App, []}]
  end

  # Dependencies
  defp deps do
    [{:connection, "~> 1.0"},
     {:credo, "~> 0.10", only: [:dev, :test]},
     {:db_connection, "~> 2.0"},
     {:decimal, "~> 1.5"},
     {:excoveralls, "~> 0.9", only: :test},
     {:ex_doc, "~> 0.20", runtime: false, only: :docs},
     {:ecto, "~> 3.1"},
     {:ecto_sql, "~> 3.1"},
     {:postgrex, "~> 0.13", optional: true},
     {:sbroker, "~> 1.0"},
     {:sqlitex, "~> 1.6"}]
  end

  defp description, do: "SQLite3 adapter for Ecto3"

  defp package do
    [licenses: ["MIT"],
      links: %{"Github" => "https://github.com/futpib/sqlite_ecto3"}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/sqlite_db_connection/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths, do: ["integration/sqlite", "test"]
end
