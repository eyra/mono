defmodule Frameworks.Pixel.Dropdown.OptionView do
  use CoreWeb.UI.Component

  prop(index, :integer, required: true)
  prop(label, :string, required: true)
  prop(id, :string)
  prop(target, :any)

  defp button(%{index: index, label: label, target: target}) do
    %{
      action: %{type: :send, event: "option_click", item: index, target: target},
      face: %{type: :plain, label: label}
    }
  end

  def render(assigns) do
    ~F"""
    <div class="cursor-pointer hover:bg-grey5 px-8 h-10 whitespace-nowrap">
      <DynamicButton vm={button(assigns)} />
    </div>
    """
  end
end
