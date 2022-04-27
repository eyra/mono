defmodule Frameworks.Pixel.Selector.Checkbox do
  @moduledoc false
  use Frameworks.Pixel.Component

  prop(item, :map, required: true)
  prop(multiselect?, :boolean, default: true)
  prop(background, :atom, default: :light)

  defviewmodel(
    value: nil,
    background: :light
  )

  def font(false), do: "text-title6 font-title6"
  def font(true), do: "text-label font-label"

  def text_color(%{accent: :tertiary}), do: "text-grey6"
  def text_color(_), do: "text-grey1"

  def check_active_icon(%{accent: :tertiary}), do: "check_active_tertiary"
  def check_active_icon(_), do: "check_active"

  def check_icon(%{accent: :tertiary}), do: "check_tertiary"
  def check_icon(_), do: "check"

  def render(assigns) do
    ~F"""
    <div class="flex flex-row gap-3 items-center">
      <div class="flex-shrink-0">
        <img x-show="active" src={"/images/icons/#{check_active_icon(@item)}.svg"} alt={"#{value(@item)} is selected"}/>
        <img x-show="!active" src={"/images/icons/#{check_icon(@item)}.svg"} alt={"Select #{value(@item)}"}/>
      </div>
      <div class={" select-none mt-1 #{font(@multiselect?)} #{text_color(@item)} leading-5"}>
        {value(@item)}
      </div>
    </div>
    """
  end
end
