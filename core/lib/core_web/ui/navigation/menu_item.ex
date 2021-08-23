defmodule CoreWeb.UI.Navigation.MenuItem do
  @moduledoc """
    Item that can be used in Menu or Navbar
  """
  use EyraUI.Component

  defviewmodel(
    id: nil,
    action: nil,
    title: nil,
    active?: false,
    counter: nil,
    icon: [name: nil, size: :small]
  )

  alias EyraUI.Navigation.Button

  prop(vm, :any, required: true)
  prop(text_color, :css_class, default: "text-grey1")
  prop(path_provider, :any, required: true)

  defp icon_rect(:large), do: "w-8 h-8 sm:w-12 sm:h-12"
  defp icon_rect(:small), do: "w-6 h-6"

  defp icon_filename(name, true), do: "#{name}_active"
  defp icon_filename(name, _), do: "#{name}"

  defp item_height(:large), do: "h-12"
  defp item_height(:small), do: "h-10"

  defp counter_color(0), do: "bg-success"
  defp counter_color(_), do: "bg-secondary"

  defp needs_hover?(vm), do: has_title?(vm)

  def render(assigns) do
    ~H"""
      <Button id={{id(@vm)}} vm={{ action(@vm)}} >
        <div class="flex flex-row items-center gap-3 justify-start rounded-full focus:outline-none {{ if active?(@vm) do "bg-grey4" end }} {{ if needs_hover?(@vm) do "hover:bg-grey4 px-4" end }} {{ item_height(icon_size(@vm)) }}">
          <div :if={{ has_icon?(@vm) }}>
            <div class="flex flex-col items-center justify-center">
              <div>
                <img class={{ icon_rect(icon_size(@vm)) }} src={{ @path_provider.static_path(@socket, "/images/icons/#{ icon_filename(icon_name(@vm), active?(@vm)) }.svg") }} />
              </div>
            </div>
          </div>
          <div :if={{ has_title?(@vm) }}>
            <div class="flex flex-col items-center justify-center">
              <div class="text-button font-button {{@text_color}} mt-1px" >
                {{ title(@vm) }}
              </div>
            </div>
          </div>
          <div class="flex-grow"></div>
          <div :if={{ has_counter?(@vm) }}>
            <div class="flex flex-col items-center justify-center">
              <div class="px-6px rounded-full {{counter_color(counter(@vm))}}" >
                <div class="text-captionsmall font-caption text-white mt-2px" >
                  {{ counter(@vm) }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </Button>
    """
  end
end
