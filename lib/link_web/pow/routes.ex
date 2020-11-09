defmodule LinkWeb.Pow.Routes do
  use Pow.Phoenix.Routes
  alias LinkWeb.Router.Helpers, as: Routes

  @impl true
  def after_sign_in_path(conn), do: Routes.study_path(conn, :index)
end
