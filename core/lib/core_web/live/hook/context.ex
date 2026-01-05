defmodule CoreWeb.Live.Hook.Context do
  @moduledoc """
  LiveView hook that automatically extracts dependencies from live context.

  ## Usage

  Declare dependencies in your embedded live view by implementing `dependencies/0`:

      defmodule MyApp.MyView do
        use CoreWeb, :embedded_live_view

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
  """

  import Phoenix.Component
  require Logger

  alias Frameworks.Concept.LiveContext
  alias Frameworks.UserState

  @session_key "live_context"

  @doc """
  on_mount callback that extracts dependencies from context.

  ## Parameters

  - live_view_module: The LiveView module that may implement dependencies/0
  """
  def on_mount(live_view_module, _params, session, socket) when is_atom(live_view_module) do
    # Check if module declares dependencies
    dependencies =
      Frameworks.Utility.Module.optional_apply(live_view_module, :dependencies, [])

    case dependencies do
      nil ->
        # No dependencies declared, skip context extraction
        {:cont, socket}

      deps when is_list(deps) ->
        extract_dependencies(live_view_module, deps, session, socket)
    end
  end

  defp extract_dependencies(live_view_module, dependencies, session, socket) do
    case Map.get(session, @session_key) do
      nil ->
        Logger.debug("[Context Hook] No live context found in session")
        {:cont, socket}

      context ->
        extract_from_context(live_view_module, context, dependencies, socket)
    end
  end

  defp extract_from_context(live_view_module, context, dependencies, socket) do
    if LiveContext.ready?(context, dependencies) do
      socket = assign_dependencies(context, dependencies, socket)
      {:cont, socket}
    else
      missing = LiveContext.missing_dependencies(context, dependencies)
      available = Map.keys(context.data)

      Logger.warning("""
      [Context Hook] Missing dependencies for #{inspect(live_view_module)}

        Missing:   #{inspect(missing)}
        Available: #{inspect(available)}

      The ViewBuilder that creates this view must include these dependencies in LiveContext.extend/2.
      """)

      {:cont, socket}
    end
  end

  defp assign_dependencies(context, dependencies, socket) do
    socket =
      Enum.reduce(dependencies, socket, fn dep, sock ->
        assign_dependency(context, dep, sock)
      end)

    # Store dependencies and context for ContextObserver to use later
    socket
    |> assign(:__context_dependencies__, dependencies)
    |> assign(:live_context, context)
  end

  # User state dependency: {:user_state, keys} extracts multiple keys into user_state container
  defp assign_dependency(context, {:user_state, keys}, socket) when is_list(keys) do
    current_user_state = Map.get(socket.assigns, :user_state, %{})

    user_state =
      Enum.reduce(keys, current_user_state, fn key, acc ->
        value = UserState.extract_scoped_value(context, key, socket)
        Map.put(acc, key, value)
      end)

    assign(socket, :user_state, user_state)
  end

  # User state dependency: {:user_state, key} extracts single key into user_state container
  defp assign_dependency(context, {:user_state, key}, socket) when is_atom(key) do
    current_user_state = Map.get(socket.assigns, :user_state, %{})
    value = UserState.extract_scoped_value(context, key, socket)
    user_state = Map.put(current_user_state, key, value)
    assign(socket, :user_state, user_state)
  end

  # Regular atom dependency
  defp assign_dependency(context, dep, socket) when is_atom(dep) do
    value = LiveContext.retrieve(context, dep, socket)
    assign(socket, dep, value)
  end
end
