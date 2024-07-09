defmodule CoreWeb.LiveTimezone do
  import Phoenix.LiveView, only: [connected?: 1, get_connect_params: 1]

  def update_timezone(socket, _session) do
    timezone =
      case {connected?(socket), get_connect_params(socket)} do
        {true, %{"timezone" => timezone}} -> timezone
        _ -> "Europe/Amsterdam"
      end

    Phoenix.Component.assign(socket, timezone: timezone)
  end

  defmacro __using__(_opts \\ nil) do
    quote do
      @before_compile CoreWeb.LiveTimezone
      import CoreWeb.LiveTimezone
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defoverridable mount: 3

      @impl true
      def mount(params, session, socket) do
        super(params, session, socket |> update_timezone(session))
      end
    end
  end
end
