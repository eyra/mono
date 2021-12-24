defmodule CoreWeb.UI.Navigation.MenuItem do
  @moduledoc """
    Item that can be used in Menu or Navbar
  """
  use Frameworks.Pixel.Component

  defviewmodel(
    menu_id: nil,
    id: nil,
    action: nil,
    title: nil,
    active?: false,
    counter: nil,
    icon: [name: nil, size: :small]
  )

  alias Frameworks.Pixel.Navigation.Button

  prop(vm, :any, required: true)
  prop(text_color, :css_class, default: "text-grey1")
  prop(path_provider, :any, required: true)
  prop(size, :atom, default: :wide)

  defp icon_rect(:large), do: "h-8 sm:h-12"
  defp icon_rect(:small), do: "w-6 h-6"

  defp icon_filename(name, :narrow), do: "#{name}_narrow"
  defp icon_filename(name, :wide), do: "#{name}_wide"
  defp icon_filename(name, true), do: "#{name}_active"
  defp icon_filename(name, _), do: "#{name}"

  defp item_height(:large), do: "h-12"
  defp item_height(:small), do: "h-10"

  defp counter_color(0), do: "bg-success"
  defp counter_color(_), do: "bg-secondary"

  defp bg_color(%{active: true}, :wide), do: "bg-grey4"
  defp bg_color(_, _), do: ""

  defp hover(%{title: title}, :wide) when not is_nil(title), do: "hover:bg-grey4 px-4"
  defp hover(_, _), do: ""

  defp gap(:narrow), do: "gap-y-3"
  defp gap(:wide), do: "gap-3"

  def render(assigns) do
    ~F"""
      <Button id={"#{menu_id(@vm)}_#{id(@vm)}"} vm={action(@vm)} >
        <div class={"flex flex-row items-center justify-start rounded-full focus:outline-none #{gap(@size)} #{bg_color(@vm, @size)} #{hover(@vm, @size)} #{item_height(icon_size(@vm))}"}>
          <div :if={has_icon?(@vm) && icon_size(@vm) == :large}>
            <div class="flex flex-col items-center justify-center">
              <div>
                <img class={icon_rect(icon_size(@vm))} src={@path_provider.static_path(@socket, "/images/icons/#{ icon_filename(icon_name(@vm), @size) }.svg")} alt="#{icon_name(@vm)}" />
              </div>
            </div>
          </div>
          <div :if={has_icon?(@vm) && icon_size(@vm) == :small}>
            <div class="flex flex-col items-center justify-center">
              <div>
                <img class={icon_rect(icon_size(@vm))} src={@path_provider.static_path(@socket, "/images/icons/#{ icon_filename(icon_name(@vm), active?(@vm)) }.svg")} alt="" />
              </div>
            </div>
          </div>
          <div :if={has_title?(@vm) && @size == :wide}>
            <div class="flex flex-col items-center justify-center">
              <div class={"text-button font-button #{@text_color} mt-1px"} >
                {title(@vm)}
              </div>
            </div>
          </div>
          <div :if={has_counter?(@vm) && @size == :wide} class="flex-grow"></div>
          <div :if={has_counter?(@vm) && @size == :wide}>
            <div class="flex flex-col items-center justify-center">
              <div class={"px-6px rounded-full #{counter_color(counter(@vm))}"} >
                <div class="text-captionsmall font-caption text-white mt-2px" >
                  {counter(@vm)}
                </div>
              </div>
            </div>
          </div>
        </div>
      </Button>
    """
  end
end
