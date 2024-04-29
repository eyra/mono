defmodule CoreWeb.LiveTimezone do
  defmacro __using__(_opts \\ nil) do
    import Phoenix.LiveView, only: [connected?: 1, get_connect_params: 1]

    quote do
      def update_timezone(socket, session) do
        timezone =
          case {connected?(socket), get_connect_params(socket)} do
            {true, %{"timezone" => timezone}} -> timezone
            _ -> session["timezone"]
          end

        assign(socket, timezone: timezone)
      end
    end
  end
end
