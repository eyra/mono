defmodule LinkWeb.Pow.Routes do
  @moduledoc """
  Contains implementation for specific pow callbacks
  """
  use Pow.Phoenix.Routes
  alias LinkWeb.Router.Helpers, as: Routes

  @impl true
  def after_sign_in_path(conn), do: Routes.study_path(conn, :index)
  def after_sign_out_path(conn), do: Routes.static_path(conn, "/")
end
