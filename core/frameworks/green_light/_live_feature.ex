defmodule Frameworks.GreenLight.LiveFeature do
  @callback get_authorization_context(
              Phoenix.LiveView.unsigned_params() | :not_mounted_at_router,
              session :: map,
              socket :: Phoenix.Socket.t()
            ) :: integer | struct

  @optional_callbacks get_authorization_context: 3

  defmacro __using__(_opts) do
    quote do
      @behaviour Frameworks.GreenLight.LiveFeature

      def mount(params, session, %{assigns: %{authorization_failed: true}} = socket) do
        {:ok, socket}
      end

      def render(%{authorization_failed: true}) do
        raise Frameworks.GreenLight.AccessDeniedError, "Authorization failed for #{__MODULE__}"
      end
    end
  end
end
