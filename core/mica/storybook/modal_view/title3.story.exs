defmodule Storybook.Frameworks.Pixel.ModalView.Title3 do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.ModalView.title3/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Modal title taken from the element option :title (used by the :max style)",
        attributes: %{modal: modal("Data donation preview")}
      }
    ]
  end

  # The title component only reads the :title option; the element's function is never called.
  defp modal(title) do
    element =
      LiveNest.Element.prepare_component(:storybook_modal, fn _assigns -> nil end, title: title)

    %LiveNest.Modal{style: :max, visible: true, element: element, options: []}
  end
end
