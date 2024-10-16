defmodule CoreWeb.Live.Hook.RemoteIp do
  @moduledoc "A Live Hook that injects the remote_ip from a session variable."
  use Frameworks.Concept.LiveHook

  @impl true
  def on_mount(_live_view_module, _params, %{"remote_ip" => remote_ip}, socket) do
    {:cont, socket |> assign(remote_ip: remote_ip)}
  end
end

defmodule CoreWeb.Plug.RemoteIp do
  @moduledoc "A Plug that sets a session variable to the current remote ip."
  import Plug.Conn, only: [put_session: 3]

  def init(options) do
    options
  end

  def call(%{remote_ip: remote_ip} = conn, _opts) do
    remote_ip = to_string(:inet_parse.ntoa(remote_ip))
    put_session(conn, :remote_ip, remote_ip)
  end
end
