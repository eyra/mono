defmodule CoreWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use CoreWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      use CoreWeb, :verified_routes
      import Core.AuthTestHelpers
      import Core.TestHelpers
      import CoreWeb.ConnCase
      import Phoenix.ConnTest
      # Import conveniences for testing with connections
      import Plug.Conn

      alias Core.Factories

      # The default endpoint for testing
      @endpoint CoreWeb.Endpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Core.Repo)

    if !tags[:async] do
      Sandbox.mode(Core.Repo, {:shared, self()})
    end

    conn = CoreWeb.ConnCase.build_conn()

    {:ok, conn: conn}
  end

  def build_conn, do: Phoenix.ConnTest.build_conn(:get, "https://eyra.co", nil)
end
