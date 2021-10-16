defmodule CoreWeb.UI.ContentTag do
  @moduledoc """
    Label with a pill formed background.
  """
  use CoreWeb.UI.Component

  defviewmodel(
    type: nil,
    text: nil,
    size: "L"
  )

  prop(vm, :map, required: true)

  def bg_color(%{type: :delete}), do: "bg-delete"
  def bg_color(%{type: :warning}), do: "bg-warning"
  def bg_color(%{type: :success}), do: "bg-success"
  def bg_color(%{type: :primary}), do: "bg-primary"
  def bg_color(%{type: :secondary}), do: "bg-secondary"
  def bg_color(%{type: :tertiary}), do: "bg-tertiary"
  def bg_color(%{type: type}), do: "bg-#{type}"

  def text_color(%{type: :tertiary}), do: "text-grey1"
  def text_color(_), do: "text-white"

  def class(%{size: "S"}), do: "px-2 py-2px font-caption text-captionsmall md:text-caption"
  def class(_), do: "px-2 py-3px text-caption font-caption"

  def render(assigns) do
    ~H"""
    <div class="flex flex-row justify-center">
      <div class="{{bg_color(@vm)}} {{text_color(@vm)}} flex-wrap text-center rounded-full {{class(@vm)}}" >
        {{text(@vm)}}
      </div>
    </div>
    """
  end
end
