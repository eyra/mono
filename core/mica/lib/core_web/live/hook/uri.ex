defmodule CoreWeb.Live.Hook.Uri do
  @moduledoc "A LiveView helper that automatically sets the current locale from a session variable."
  use Frameworks.Concept.LiveHook

  @impl true
  def mount(live_view_module, _params, _session, socket) do
    {
      :cont,
      socket
      |> assign(
        uri: nil,
        uri_origin: nil,
        uri_path: nil
      )
      |> handle_uri(live_view_module)
    }
  end

  defp handle_uri(socket, live_view_module) do
    attach_hook(socket, :handle_uri, :handle_params, fn params, uri, socket ->
      parsed_uri = URI.parse(uri)
      uri_origin = "#{parsed_uri.scheme}://#{parsed_uri.authority}"

      uri_path =
        case parsed_uri.query do
          nil -> parsed_uri.path
          query -> "#{parsed_uri.path}?#{query}"
        end

      socket =
        assign(socket,
          params: params,
          uri: uri,
          uri_origin: uri_origin,
          uri_path: uri_path
        )

      socket = optional_apply(socket, live_view_module, :handle_uri)

      {:cont, socket}
    end)
  end
end
