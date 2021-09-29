defmodule EyraUI.Selector.Checkbox do
  @moduledoc false
  use EyraUI.Component

  prop(item, :map, required: true)

  defviewmodel(
    value: nil,
    background: :light
  )

  def text_color(%{accent: :tertiary}), do: "text-grey6"
  def text_color(_), do: "text-grey1"

  def check_active_icon(%{accent: :tertiary}), do: "check_active_tertiary"
  def check_active_icon(_), do: "check_active"

  def check_icon(%{accent: :tertiary}), do: "check_tertiary"
  def check_icon(_), do: "check"

  def render(assigns) do
    ~H"""
    <div class="flex flex-row gap-3 items-center">
      <div>
        <img x-show="active" src="/images/icons/{{check_active_icon(@item)}}.svg" alt="{{ value(@item) }} is selected"/>
        <img x-show="!active" src="/images/icons/{{check_icon(@item)}}.svg" alt="Select {{ value(@item) }}"/>
      </div>
      <div class=" text-label font-label select-none mt-1 {{ text_color(@item) }}">
        {{ value(@item) }}
      </div>
    </div>
    """
  end
end
