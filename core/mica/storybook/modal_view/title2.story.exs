defmodule Storybook.Frameworks.Pixel.ModalView.Title2 do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.ModalView.title2/1

  def variations do
    [
      %Variation{
        id: :left,
        description: "Modal title taken from the element option :title",
        attributes: %{modal: modal("Assignment settings")}
      },
      %Variation{
        id: :centered,
        description: "Centred modal title",
        attributes: %{modal: modal("Thank you for participating!"), centered?: true}
      }
    ]
  end

  defp modal(title) do
    element = LiveNest.Element.prepare_component(:storybook_modal, nil, title: title)
    %LiveNest.Modal{style: :page, visible: true, element: element, options: []}
  end
end
