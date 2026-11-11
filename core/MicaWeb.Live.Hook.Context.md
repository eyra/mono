# `MicaWeb.Live.Hook.Context`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/live/hook/context.ex#L1)

LiveView hook that automatically extracts dependencies from live context.

## Usage

Declare dependencies in your embedded live view by implementing `dependencies/0`:

    defmodule MyApp.MyView do
      use MicaWeb, :embedded_live_view

      def dependencies(), do: [:assignment_id, :current_user]

      def get_model(:not_mounted_at_router, _session, %{assigns: %{assignment_id: id}}) do
        # assignment_id is available from context!
        Assignment.Public.get!(id)
      end

      def mount(:not_mounted_at_router, _session, socket) do
        # socket.assigns.assignment_id and socket.assigns.current_user are available!
        {:ok, socket}
      end
    end

## How it works

1. The Context hook is automatically added to embedded_live_view (runs before Model hook)
2. Checks if the view implements `dependencies/0`
3. Extracts context from session (stored under "live_context" key)
4. For each declared dependency, calls `Frameworks.Concept.LiveContext.retrieve/3`
5. Assigns the result to socket.assigns with the dependency name

## Context Readiness

The hook checks if context can provide all dependencies via `ready?/2`.
If not ready, dependencies are not extracted and a warning is logged.

# `on_mount`

on_mount callback that extracts dependencies from context.

## Parameters

- live_view_module: The LiveView module that may implement dependencies/0

---

*Consult [api-reference.md](api-reference.md) for complete listing*
