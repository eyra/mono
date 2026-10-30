defmodule MicaWeb.Meta do
  import Plug.Conn

  def fetch_meta_info(conn, _opts) do
    assign(conn, :bundle_title, bundle_title())
  end

  def bundle_title(%{assigns: %{bundle_title: bundle_title}} = _conn) do
    bundle_title
  end

  def bundle_title, do: Mica.SaaS.module().title()
end
