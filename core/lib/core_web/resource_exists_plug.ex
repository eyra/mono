defmodule CoreWeb.ResourceExistsPlug do
  @moduledoc """
  A plug that checks if a resource exists before continuing.

  If the resource doesn't exist, redirects to /not_found.
  This separates existence checking (404) from authorization (403).

  ## Usage in router

      pipeline :assignment_exists do
        plug CoreWeb.ResourceExistsPlug, param: "id", fetch: {Assignment.Public, :get}
      end

      scope "/assignment/:id" do
        pipe_through [:browser, :assignment_exists]
        live "/", Assignment.CrewPage
      end
  """

  import Plug.Conn
  use CoreWeb, :verified_routes

  def init(opts), do: opts

  def call(conn, opts) do
    param = Keyword.fetch!(opts, :param)
    {module, function} = Keyword.fetch!(opts, :fetch)

    id = conn.params[param]

    case apply(module, function, [id]) do
      nil ->
        conn
        |> Phoenix.Controller.redirect(to: ~p"/not_found")
        |> halt()

      _resource ->
        conn
    end
  end
end
