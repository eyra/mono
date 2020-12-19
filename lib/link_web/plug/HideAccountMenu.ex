defmodule LinkWeb.Plug.HideAccountMenu do
  @moduledoc """
  This plug ensures that there are no account menu items visible.
  """
  import Plug.Conn

  def init(default), do: default

  def call(conn, _params) do
    assign(conn, :hide_account_menu, true)
  end
end
