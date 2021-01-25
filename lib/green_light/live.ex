defmodule GreenLight.Live do
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
      defoverridable mount: 3

      if Module.defines?(__MODULE__, {:get_authorization_context, 3}) do
        defp check_access_allowed(params, session, socket) do
          if @greenlight_authmodule.can_access?(
               get_user(socket, session),
               get_authorization_context(params, session, socket),
               __MODULE__
             ) do
            {:ok, socket}
          else
            {:error, :unauthorized}
          end
        end
      else
        defp check_access_allowed(_params, session, socket) do
          if @greenlight_authmodule.can_access?(get_user(socket, session), __MODULE__) do
            {:ok, socket}
          else
            {:error, :unauthorized}
          end
        end
      end

      def mount(params, session, socket) do
        user = get_user(socket, session)
        socket = assign(socket, current_user: user)

        case check_access_allowed(params, session, socket) do
          {:ok, socket} -> super(params, session, socket)
          _ -> {:ok, assign(socket, authorization_failed: true)}
        end
      end
    end
  end
end
