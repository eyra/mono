defmodule Frameworks.Concept.Switch do
  @moduledoc """
  Base module for system switches that handle signal routing.

  Provides helper functions for dispatching updates to LiveViews:
  - `update_routed/3` - Updates a routed LiveView page (mounted at router)
  - `update_embedded/3` - Updates an embedded LiveView (nested within other LiveViews)

  ## Usage

      defmodule Systems.MySystem.Switch do
        use Frameworks.Concept.Switch

        alias Systems.Observatory

        @impl true
        def intercept({:my_entity, _action}, %{from_pid: from_pid}) do
          update_routed(MySystem.ContentPage, %{id: :singleton}, from_pid)
          update_embedded(MySystem.SomeView, Observatory.SingletonModel.instance(), from_pid)
          :ok
        end
      end
  """

  defmacro __using__(_opts) do
    quote do
      use Frameworks.Signal.Handler

      defp update_routed(live_view, %{id: id} = model, from_pid) do
        dispatch!({:routed, live_view}, %{id: id, model: model, from_pid: from_pid})
      end

      defp update_embedded(live_view, %{id: id} = model, from_pid) do
        dispatch!({:embedded, live_view}, %{id: id, model: model, from_pid: from_pid})
      end
    end
  end
end
