defmodule EyraUI.Navigation.MenuItem do
  @moduledoc """
    Vertical stacked menu used on the side
  """
  use Surface.Component

  alias EyraUI.Navigation.Button

  defmodule ViewModel do
    defstruct [:id, :title, :icon, :action, :active]

    @type icon :: atom

    @type action :: %{
            method: atom,
            info: any,
            overlay: boolean
          }

    @type t :: %__MODULE__{
            id: binary,
            title: binary,
            icon: icon,
            action: action,
            active: boolean
          }
  end

  prop(view_model, :any, required: true)
  prop(text_color, :css_class, default: "text-grey1")
  prop(path_provider, :any, required: true)

  defp icon_size(%{icon: %{size: :large}}), do: "w-12 h-12"
  defp icon_size(_), do: "w-6 h-6"

  defp icon_filename(%{icon: %{name: name}, active: true}), do: "#{name}_active"
  defp icon_filename(%{icon: %{name: name}}), do: name
  defp icon_filename(_), do: "?"

  defp has_icon?(%{icon: nil}), do: false
  defp has_icon?(%{icon: _}), do: true
  defp has_icon?(_), do: false

  defp has_title?(%{title: nil}), do: false
  defp has_title?(%{title: _}), do: true
  defp has_title?(_), do: false

  defp item_size(%{icon: %{size: :large}}), do: "h-12"
  defp item_size(_), do: "h-10"

  defp data_method(%{action: %{method: method}}), do: method
  defp data_method(_), do: :get

  defp needs_hover?(view_model), do: has_title?(view_model)

  defp show_overlay_after_click?(%{action: %{overlay: overlay}}), do: overlay
  defp show_overlay_after_click?(_), do: false

  def render(assigns) do
    ~H"""
      <Button id={{@view_model.id}} action={{@view_model.action}} method={{data_method(@view_model)}} overlay="$parent.overlay = {{ show_overlay_after_click?(@view_model) }}" >
        <div class="flex flex-row items-center justify-start rounded-full focus:outline-none {{ if @view_model.active do "bg-grey4" end }} {{ if needs_hover?(@view_model) do "hover:bg-grey4 px-4" end }} {{ item_size(@view_model) }}">
          <div :if={{ has_icon?(@view_model) }}>
            <div class="flex flex-col items-center justify-center">
              <div>
                <img class={{ icon_size(@view_model) }} src={{ @path_provider.static_path(@socket, "/images/icons/#{ icon_filename(@view_model) }.svg") }} />
              </div>
            </div>
          </div>
          <div :if={{ has_title?(@view_model) && has_icon?(@view_model) }} class="ml-3">
          </div>
          <div :if={{ has_title?(@view_model) }}>
            <div class="flex flex-col items-center justify-center">
              <div class="text-button font-button {{@text_color}} mt-1px" >
                {{ @view_model.title }}
              </div>
            </div>
          </div>
        </div>
      </Button>
    """
  end
end
