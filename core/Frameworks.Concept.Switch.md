# `Frameworks.Concept.Switch`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/concept/switch.ex#L1)

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

---

*Consult [api-reference.md](api-reference.md) for complete listing*
