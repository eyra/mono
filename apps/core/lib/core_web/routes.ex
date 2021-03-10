defmodule CoreWeb.Routes do
  alias Plug.Conn
  alias CoreWeb.Dependencies.Resolver

  def path_provider(conn) do
    Resolver.resolve(conn, "path_provider")
  end

  def static_path(conn, asset) do
    path_provider(conn).static_path(conn, asset)
  end

  def live_path(conn, view) do
    path_provider(conn).live_path(conn, view)
  end

  def live_path(conn, view, id) do
    path_provider(conn).live_path(conn, view, id)
  end

  def path(conn, controller, view) do
    path_provider(conn).path(conn, controller, view)
  end

  def path(conn, controller, view, id, opts \\ []) do
    path_provider(conn).path(conn, controller, view, id, opts)
  end

  def live_url(conn, view, id) do
    Phoenix.Router.Helpers.url(nil, conn) <> live_path(conn, view, id)
  end

  def url(conn, controller, view) do
    Phoenix.Router.Helpers.url(nil, conn) <> path(conn, controller, view)
  end

  def url(%Conn{} = conn, controller, view, id) do
    Phoenix.Router.Helpers.url(nil, conn) <> path(conn, controller, view, id)
  end
end
