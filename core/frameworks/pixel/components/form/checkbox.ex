defmodule Frameworks.Pixel.Form.Checkbox do
  @moduledoc false
  use Surface.Component

  import Phoenix.HTML.Form, only: [input_value: 2]
  import Frameworks.Pixel.FormHelpers

  prop(field, :atom, required: true)
  prop(label_text, :string)
  prop(label_color, :css_class, default: "text-grey1")
  prop(accent, :atom, default: :primary)
  prop(background, :atom, default: :light)

  defp check_value(form, field) do
    case input_value(form, field) do
      nil -> false
      value -> value
    end
  end

  defp default_border_color(:primary), do: "border-grey3"
  defp default_border_color(accent), do: "border-#{accent}"

  defp check_icon(variant), do: "check_#{variant}"
  defp active_bg_color(accent), do: "bg-#{accent}"
  defp inactive_bg_color(_), do: "bg-opacity-0"

  def render(assigns) do
    ~F"""
    <Context
      get={Surface.Components.Form, form: form}
    >
      <div
        class="flex flex-row mb-3 gap-5 sm:gap-3 cursor-pointer items-center"
        x-data={"{ active: #{check_value(form, @field)} }"}
        x-on:click={"active = !active, $parent.focus = '#{@field}'"}
        phx-click="toggle"
        phx-value-checkbox={@field}
        phx-target={target(form)}
      >
        <div
          class="flex-shrink-0 w-6 h-6 rounded"
          x-bind:class={"{ '#{active_bg_color(@accent)}': active, '#{inactive_bg_color(@background)} border-2 #{border_color(assigns, form, default_border_color(@accent))}': !active }"}
        >
          <img x-show="active" src={"/images/icons/#{check_icon(@background)}.svg"} alt={"#{@field} is selected"}/>
        </div>
        <div
          class="mt-0.5 text-title6 font-title6 leading-snug"
          x-bind:class={"{'#{@label_color}': active || #{not field_has_error?(assigns, form)}, 'text-warning': !active && #{field_has_error?(assigns, form)} }"}
        >
          {@label_text}
        </div>
      </div>
    </Context>
    """
  end

  defmacro __using__(_opts) do
    quote do
      def handle_event(
            "toggle",
            %{"checkbox" => checkbox},
            %{assigns: %{entity: entity}} = socket
          ) do
        field = String.to_existing_atom(checkbox)

        new_value =
          case Map.get(entity, field) do
            nil -> true
            value -> not value
          end

        attrs = %{field => new_value}

        {
          :noreply,
          socket
          |> save(entity, :auto_save, attrs)
        }
      end
    end
  end
end
