defmodule Sqlite.DbConnection.App do
  @moduledoc false
  use Application

  def start(_, _) do
    children = [
      {Sqlite.DbConnection.SqlitexServerPool, {}}
    ]

    opts = [strategy: :one_for_one, name: Sqlite.DbConnection.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
