defmodule CoreWeb.Meta do
  import Plug.Conn

  def fetch_meta_info(conn, _opts) do
    config = config()

    bundle_title = Keyword.get(config, :bundle_title, "Eyra Next")
    bundle = Keyword.get(config, :bundle, :eyra)

    conn
    |> assign(:bundle_title, bundle_title)
    |> assign(:bundle, bundle)
  end

  defp config, do: Application.get_env(:core, :meta, [])

  def bundle_title(%{assigns: %{bundle_title: bundle_title}} = _conn) do
    bundle_title
  end

  def bundle_title do
    Keyword.get(config(), :bundle_title, "Eyra Next")
  end

  def bundle(%{assigns: %{bundle: bundle}} = _conn) do
    bundle
  end

  def bundle do
    Keyword.get(config(), :bundle, :eyra)
  end
end
