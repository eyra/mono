defmodule CoreWeb.LiveUri do
  @moduledoc "A LiveView helper that automatically sets the current locale from a session variable."

  @callback handle_uri(Socket.t()) :: Socket.t()

  defmacro __using__(_opts \\ nil) do
    quote do
      @behaviour CoreWeb.LiveUri

      import Phoenix.LiveView, only: [assign: 3]

      def handle_params(
            _unsigned_params,
            _uri,
            %{assigns: %{authorization_failed: true}} = socket
          ) do
        # skip handling params if authorization already has already failed to prevent errors
        {:noreply, socket}
      end

      def handle_params(unsigned_params, uri, socket) do
        parsed_uri = URI.parse(uri)
        uri_origin = "#{parsed_uri.scheme}://#{parsed_uri.authority}"

        uri_path =
          case parsed_uri.query do
            nil -> parsed_uri.path
            query -> "#{parsed_uri.path}?#{query}"
          end

        {
          :noreply,
          socket
          |> assign(:params, unsigned_params)
          |> assign(:uri, uri)
          |> assign(:uri_origin, uri_origin)
          |> assign(:uri_path, uri_path)
          |> handle_uri()
        }
      end
    end
  end
end
