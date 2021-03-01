defmodule GreenLight.Live do
  @moduledoc """
  The Live module enables automatic authorization checks for LiveViews.
  """
  @callback get_authorization_context(
              Phoenix.LiveView.unsigned_params() | :not_mounted_at_router,
              session :: map,
              socket :: Socket.t()
            ) :: integer
  @optional_callbacks get_authorization_context: 3

  defmacro __using__(auth_module) do
    quote do
      @greenlight_authmodule unquote(auth_module)
      @behaviour GreenLight.Live
      @before_compile GreenLight.Live
      import Phoenix.LiveView.Helpers

      def render(%{authorization_failed: true} = var!(assigns)) do
        ~L"<h1>Access Denied</h1>"
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      if Module.defines?(__MODULE__, {:get_authorization_context, 3}) do
        defp access_allowed?(params, session, socket) do
          @greenlight_authmodule.can_access?(
            socket,
            get_authorization_context(params, session, socket),
            __MODULE__
          )
        end
      else
        defp access_allowed?(_params, session, socket) do
          @greenlight_authmodule.can_access?(socket, __MODULE__)
        end
      end

      defoverridable mount: 3

      def mount(params, session, socket) do
        if access_allowed?(params, session, socket) do
          super(params, session, socket)
        else
          {:ok, assign(socket, authorization_failed: true)}
        end
      end
    end
  end
end
