defmodule Systems.Test.RoutedLiveViewBuilder do
  alias Frameworks.Concept.LiveContext
  alias Systems.Test

  def view_model(%Test.RoutedModel{title: title, children: children, modal: modal}, _assigns) do
    %{
      title: title,
      child_elements: build_child_elements(children),
      modal: modal
    }
  end

  defp build_child_elements(children) do
    Enum.map(children, fn %{id: id, title: title, namespace: namespace, items: items} ->
      context =
        LiveContext.new(%{
          user_state_namespace: namespace
        })

      LiveNest.Element.prepare_live_view(
        id,
        Test.EmbeddedLiveView,
        vm: %{
          id: id,
          title: title,
          items: items
        },
        live_context: context
      )
    end)
  end
end
