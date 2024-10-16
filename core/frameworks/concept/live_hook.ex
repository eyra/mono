defmodule Frameworks.Concept.LiveHook do
  @type live_view_module :: atom()
  @type params :: map()
  @type session :: map()
  @type socket :: Phoenix.LiveView.Socket.t()

  @callback on_mount(live_view_module(), params(), session(), socket()) ::
              {:cont | :halt, socket()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Frameworks.Concept.LiveHook

      import Phoenix.LiveView,
        only: [attach_hook: 4, connected?: 1, get_connect_params: 1, redirect: 2]

      import Phoenix.Component, only: [assign: 2]

      def optional_apply(socket, live_view_module, function) do
        Frameworks.Utility.Module.optional_apply(live_view_module, function, [socket], socket)
      end

      def optional_apply(socket, live_view_module, function, args) when is_list(args) do
        Frameworks.Utility.Module.optional_apply(live_view_module, function, args, socket)
      end
    end
  end
end
