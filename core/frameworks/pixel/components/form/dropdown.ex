defmodule Frameworks.Pixel.Form.Dropdown do
  @moduledoc false
  use Surface.Component

  alias Frameworks.Pixel.Form.Field

  alias Phoenix.LiveView.JS

  import Frameworks.Pixel.FormHelpers

  import Phoenix.HTML.Form, only: [input_id: 2, input_name: 2, input_value: 2]

  prop(field, :atom, required: true)
  prop(options, :list, required: true)
  prop(selected_option, :atom)
  prop(target, :any, required: true)
  prop(placeholder, :string, default: "")
  prop(label_text, :string)
  prop(label_color, :css_class, default: "text-grey1")
  prop(background, :atom, default: :light)
  prop(disabled, :boolean, default: false)
  prop(reserve_error_space, :boolean, default: true)
  prop(debounce, :string, default: "1000")
  prop(value, :any, default: nil)

  data(form, :form, from_context: {Surface.Components.Form, :form})

  # Under some conditions a Frameworks.Pixel.Form.DateInput has its value reset to original value when using Phoenix.HTML.Form.input_value/2.
  # By inserting the value directly it always keeps the correct value.
  defp value(form, %{value: nil, field: field}), do: input_value(form, field)
  defp value(_form, %{value: value}), do: value

  defp item_text_color(%{id: id}, selected_option) do
    if id == selected_option do
      "text-primary"
    else
      "text-grey1"
    end
  end

  def render(%{field: field, form: form, background: background} = assigns) do
    field_id = String.to_atom(input_id(form, field))
    field_name = input_name(form, field)
    field_value = value(form, assigns)
    error = field_error_message(assigns, form)
    error? = error != nil
    border_color = get_border_color({false, error?, background})
    options_id = "#{field_id}-options"

    ~F"""
    <Field
      field={field_id}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      error={error}
      reserve_error_space={@reserve_error_space}
      js_click={JS.show(to: "##{options_id}")
      |> JS.hide(to: "#dropdown-img")
      |> JS.show(to: "#dropup-img")}
      js_click_away={JS.hide(to: "##{options_id}")
      |> JS.show(to: "#dropdown-img")
      |> JS.hide(to: "#dropup-img")}
    >
      <div class="relative">
        <input
          readonly
          type="text"
          id={field_id}
          name={field_name}
          value={field_value}
          placeholder={@placeholder}
          class={"text-grey1 text-bodymedium font-body pl-3 focus:outline-none whitespace-pre-wrap w-full border-2 border-solid rounded h-44px cursor-pointer #{border_color}"}
          phx-target={@target}
        />
        <div class="absolute z-20 right-0 top-0 h-44px flex flex-col justify-center">
          <div id="dropdown-img">
            <img class="mr-3" src="/images/icons/dropdown.svg" alt="Dropdown">
          </div>
          <div id="dropup-img" class="hidden">
            <img class="mr-3" src="/images/icons/dropup.svg" alt="Dropup">
          </div>
        </div>
        <div id={options_id} class="absolute z-20 left-0 top-48px bg-black bg-opacity-20 w-full hidden">
          <div class="bg-white shadow-2xl rounded">
            <div class="max-h-dropdown overflow-y-scroll py-4">
              <div class="flex flex-col items-left">
                <div :for={option <- @options} class="flex-shrink-0">
                  <div
                    class="cursor-pointer hover:bg-grey5 px-8 h-10 flex flex-col justify-center"
                    phx-click={JS.hide(to: "##{options_id}")
                    |> JS.push("select-option", value: option, target: @target)}
                  >
                    <div class={"text-button font-button whitespace-nowrap #{item_text_color(option, @selected_option)}"}>
                      {option.label}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Field>
    """
  end
end
