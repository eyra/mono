defmodule Frameworks.Pixel.Form.Field do
  @moduledoc false
  use Surface.Component
  import Frameworks.Pixel.FormHelpers

  alias Phoenix.LiveView.JS
  alias Frameworks.Pixel.Spacing
  alias Frameworks.Pixel.Text.FormFieldLabel

  prop(field, :atom, required: true)
  prop(label_text, :string)
  prop(label_color, :css_class, default: "text-grey1")
  prop(background, :atom, required: true)
  prop(change, :event)
  prop(read_only, :boolean, default: false)
  prop(error, :any)
  prop(reserve_error_space, :boolean, default: true)
  prop(extra_space, :boolean, default: true)

  prop(js_click, :map, default: %JS{})
  prop(js_click_away, :map, default: %JS{})

  slot(default)

  def render(%{field: field} = assigns) do
    label_id = "#{field}_label"
    error_space_id = "#{field}_error_space"
    error_message_id = "#{field}_error_message"

    ~F"""
    <div
      phx-click={@js_click
      |> JS.hide(to: "##{error_message_id}")
      |> set_field_color(@field, {true, @error != nil, @background})}
      phx-click-away={@js_click_away
      |> JS.show(to: "##{error_message_id}")
      |> set_field_color(@field, {false, @error != nil, @background})}
    >
      <div :if={@label_text}>
        <FormFieldLabel
          :if={@label_text}
          id={label_id}
          color={get_text_color({false, @error != nil, @background})}
        >
          {@label_text}
        </FormFieldLabel>
        <Spacing value="XXS" />
      </div>
      <#slot />
    </div>
    <Spacing :if={@extra_space} value="XXS" />
    <div
      id={error_space_id}
      class={if @reserve_error_space do
        "h-18px"
      end}
    >
      <div id={error_message_id} class="text-warning text-caption font-caption">
        {@error}
      </div>
    </div>
    """
  end
end
