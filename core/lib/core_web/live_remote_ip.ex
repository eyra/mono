defmodule CoreWeb.Plug.LiveRemoteIp do
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

defmodule CoreWeb.LiveRemoteIp do
  @moduledoc "A LiveView helper that automatically sets the current remote_ip from a session variable."

  defmacro __using__(_opts \\ nil) do
    quote do
      @before_compile CoreWeb.LiveRemoteIp
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defoverridable mount: 3

      def mount(params, %{"remote_ip" => remote_ip} = session, socket) do
        super(params, session, socket |> assign(remote_ip: remote_ip))
      end
    end
  end
end
