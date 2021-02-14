defmodule LinkWeb.Pow.Routes do
  @moduledoc """
  Contains implementation for specific pow callbacks
  """
  use Pow.Phoenix.Routes
  alias LinkWeb.Router.Helpers, as: Routes

  @impl true
  def after_sign_in_path(conn), do: Routes.live_path(conn, LinkWeb.Dashboard)

  @impl true
  def after_sign_out_path(conn), do: Routes.live_path(conn, LinkWeb.Index)

  @impl true
  def user_not_authenticated_path(conn), do: Routes.live_path(conn, LinkWeb.User.Signin)
end
