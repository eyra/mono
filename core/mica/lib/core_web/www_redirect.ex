defmodule CoreWeb.WWWRedirect do
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, _options) do
    if www_domain?(conn) do
      conn
      |> Phoenix.Controller.redirect(external: bare_url(conn))
      |> halt()
    else
      conn
    end
  end

  defp bare_url(%{scheme: scheme, host: host, request_path: request_path}),
    do: "#{scheme}://#{String.replace(host, "www.", "")}#{request_path}"

  defp www_domain?(%{host: "www." <> _bare_domain}), do: true
  defp www_domain?(_), do: false
end
