defmodule Frameworks.Pixel.Form do
  @moduledoc false
  use CoreWeb, :html

  import Frameworks.Pixel.ImagePreview

  import Phoenix.HTML
  # , only: [input_id: 2, input_name: 2, input_value: 2]
  import Phoenix.HTML.Form

  import Frameworks.Pixel.FormHelpers

  alias Phoenix.LiveView.JS

  attr(:field, :atom, required: true)
  attr(:label_text, :string)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, required: true)
  attr(:read_only, :boolean, default: false)
  attr(:errors, :list, default: [])
  attr(:error_message, :string, default: nil)
  attr(:reserve_error_space, :boolean, default: true)
  attr(:extra_space, :boolean, default: true)
  attr(:active?, :boolean, default: false)

  slot(:inner_block, required: true)

  def field(%{field: field, active?: active?, background: background, errors: errors} = assigns) do
    label_id = "#{field}_label"
    error_space_id = "#{field}_error_space"
    error_message_id = "#{field}_error_message"

    idle_text_color =
      if Enum.empty?(errors) do
        "text-grey1"
      else
        "text-warning"
      end

    active_text_color =
      if background == :light do
        "text-primary"
      else
        "text-tertiary"
      end

    current_text_color =
      if active? do
        active_text_color
      else
        idle_text_color
      end

    label_color = get_text_color({false, Enum.count(errors) > 0, background})

    assigns =
      assign(assigns, %{
        label_id: label_id,
        label_color: label_color,
        error_space_id: error_space_id,
        error_message_id: error_message_id,
        current_text_color: current_text_color,
        idle_text_color: idle_text_color,
        active_text_color: active_text_color
      })

    ~H"""
    <div id={"field-#{@field}"} data-field-id={@field} phx-hook="Field">
      <div>
        <%= if @label_text do %>
          <div>
            <div
              id={@label_id}
              class={"field-label mt-0.5 text-title6 font-title6 leading-snug #{@current_text_color}"}
              idle-class={@idle_text_color}
              active-class={@active_text_color}
            >
              <%= @label_text %>
            </div>
            <.spacing value="XXS" />
          </div>
        <% end %>
        <%= render_slot(@inner_block) %>
      </div>
      <%= if @extra_space do %>
        <.spacing value="XXS" />
      <% end %>
      <div id={@error_space_id} class={ if @reserve_error_space do "h-18px" end} >
        <%= for {msg, _opts} <- @errors do %>
            <div
              id={@error_message_id}
              class={"text-caption font-caption text-warning"}
              idle-class="text-warning"
              active-class="text-warning"
            >
              <%= msg %>
            </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Under some conditions a Frameworks.Pixel.Form.DateInput has its value reset to original value when using Phoenix.HTML.Form.input_value/2.
  # By inserting the value directly it always keeps the correct value.
  defp value(form, %{value: nil, field: field}), do: input_value(form, field)
  defp value(_form, %{value: value}), do: value

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:active_field, :string, default: nil)
  attr(:type, :string, required: true)
  attr(:placeholder, :string, default: "")
  attr(:label_text, :string)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:disabled, :boolean, default: false)
  attr(:reserve_error_space, :boolean, default: true)
  attr(:debounce, :string, default: "1000")
  attr(:value, :any, default: nil)
  attr(:maxlength, :string, default: "1000")

  def input(
        %{form: form, field: field, active_field: active_field, background: background} = assigns
      ) do
    errors = form[field].errors
    field_id = String.to_atom(input_id(form, field))
    active? = Atom.to_string(field_id) == active_field

    idle_border_color =
      if Enum.empty?(errors) do
        "border-grey3"
      else
        "border-warning"
      end

    active_border_color =
      if background == :light do
        "border-primary"
      else
        "border-tertiary"
      end

    current_border_color =
      if active? do
        active_border_color
      else
        idle_border_color
      end

    assigns =
      assign(assigns, %{
        field_id: field_id,
        field_name: input_name(form, field),
        field_value: value(form, assigns),
        target: target(form),
        current_border_color: current_border_color,
        idle_border_color: idle_border_color,
        active_border_color: active_border_color,
        errors: errors,
        active?: active?
      })

    ~H"""
    <.field
      field={@field_id}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      reserve_error_space={@reserve_error_space}
      errors={@errors}
      active?={@active?}
    >
      <%= if @disabled do %>
        <input
          type={@type}
          id={@field_id}
          name={@field_name}
          value={@field_value}
          placeholder={@placeholder}
          class="text-grey3 bg-white placeholder-grey3 text-bodymedium font-body pl-3 w-full disabled:border-grey3 border-2 border-solid focus:outline-none rounded h-44px"
          disabled
        />
      <% else %>
        <input
          type={@type}
          id={@field_id}
          name={@field_name}
          value={@field_value}
          min="0"
          placeholder={@placeholder}
          maxlength={@maxlength}
          class={"field-input text-grey1 text-bodymedium font-body pl-3 w-full border-2 border-solid focus:outline-none rounded h-44px #{@current_border_color}"}
          idle-class={@idle_border_color}
          active-class={@active_border_color}
          phx-target={@target}
          phx-debounce={@debounce}
        />
      <% end %>
    </.field>
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:active_field, :string, default: nil)
  attr(:label_text, :string)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:reserve_error_space, :boolean, default: true)
  attr(:debounce, :string, default: "1000")

  def number_input(assigns) do
    ~H"""
    <.input
      form={@form}
      field={@field}
      active_field={@active_field}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      reserve_error_space={@reserve_error_space}
      debounce={@debounce}
      type="number"
    />
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:active_field, :string, default: nil)
  attr(:label_text, :string, default: nil)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:placeholder, :string, default: "")
  attr(:reserve_error_space, :boolean, default: true)
  attr(:debounce, :string, default: "1000")
  attr(:maxlength, :string, default: "1000")

  def text_input(assigns) do
    ~H"""
    <.input
      form={@form}
      field={@field}
      active_field={@active_field}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      placeholder={@placeholder}
      reserve_error_space={@reserve_error_space}
      debounce={@debounce}
      maxlength={@maxlength}
      type="text"
    />
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:active_field, :string, default: nil)
  attr(:label_text, :string)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)

  def url_input(assigns) do
    ~H"""
    <.input
      form={@form}
      field={@field}
      active_field={@active_field}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      type="url"
    />
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:active_field, :string, default: nil)
  attr(:label_text, :string)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)

  def password_input(assigns) do
    ~H"""
    <.input
      form={@form}
      field={@field}
      active_field={@active_field}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      type="password"
    />
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:active_field, :string, default: nil)
  attr(:label_text, :string)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:disabled, :boolean, default: false)
  attr(:value, :string)

  def date_input(assigns) do
    ~H"""
    <.input
      form={@form}
      field={@field}
      active_field={@active_field}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      type="date"
      disabled={@disabled}
      debounce={""}
      value={@value}
    />
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:active_field, :string, default: nil)
  attr(:label_text, :string)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)

  def email_input(assigns) do
    ~H"""
    <.input
      form={@form}
      field={@field}
      active_field={@active_field}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      type="email"
    />
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:active_field, :string, default: nil)
  attr(:label_text, :string)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:debounce, :string, default: "1000")

  def text_area(
        %{form: form, field: field, active_field: active_field, background: background} = assigns
      ) do
    errors = form[field].errors
    field_id = String.to_atom(input_id(form, field))
    active? = Atom.to_string(field_id) == active_field

    idle_border_color =
      if Enum.empty?(errors) do
        "border-grey3"
      else
        "border-warning"
      end

    active_border_color =
      if background == :light do
        "border-primary"
      else
        "border-tertiary"
      end

    current_border_color =
      if active? do
        active_border_color
      else
        idle_border_color
      end

    assigns =
      assign(assigns, %{
        field_id: field_id,
        field_name: input_name(form, field),
        field_value: html_escape(input_value(form, field) || ""),
        target: target(form),
        current_border_color: current_border_color,
        idle_border_color: idle_border_color,
        active_border_color: active_border_color,
        errors: errors,
        active?: active?
      })

    ~H"""
    <.field
      field={@field_id}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      errors={@errors}
      active?={@active?}
      extra_space={false}
    >
      <textarea
        id={@field_id}
        name={@field_name}
        class={"field-input text-grey1 text-bodymedium font-body pl-3 pt-2 w-full h-64 border-2 focus:outline-none rounded #{@current_border_color}"}
        idle-class={@idle_border_color}
        active-class={@active_border_color}
        phx-target={@target}
        phx-debounce={@debounce}
      ><%= @field_value %></textarea>
    </.field>
    """
  end

  attr(:static_path, :any, required: true)
  attr(:label_text, :string, default: nil)
  attr(:label_color, :string, default: "text-grey1")
  attr(:photo_url, :string, required: true)
  attr(:uploads, :any, required: true)
  attr(:primary_button_text, :string, required: true)
  attr(:secondary_button_text, :string, required: true)

  def photo_input(assigns) do
    ~H"""
    <%= if @label_text do %>
      <Text.title6><%= @label_text %></Text.title6>
    <% end %>
    <div class="flex flex-row items-center">
      <.image_preview
        image_url={@photo_url}
        placeholder={@static_path.("/images/profile_photo_default.svg")}
        shape="w-image-preview-circle sm:w-image-preview-circle-sm h-image-preview-circle sm:h-image-preview-circle-sm rounded-full"
      />
      <.spacing value="S" direction="l" />
      <div class="flex-wrap">
        <%= if @photo_url do %>
          <Button.secondary_label label={@secondary_button_text} field={@uploads.photo.ref} />
        <% else %>
          <Button.primary_label label={@primary_button_text} field={@uploads.photo.ref} />
        <% end %>
        <%= live_file_input(@uploads.photo, class: "hidden") %>
      </div>
    </div>
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:label_text, :string)
  attr(:label_color, :string, default: "text-grey1")
  attr(:accent, :atom, default: :primary)
  attr(:background, :atom, default: :light)

  def checkbox(%{form: form, field: field, background: background, accent: accent} = assigns) do
    error? = field_has_error?(assigns, form)

    check_value =
      case input_value(form, field) do
        nil -> false
        value -> value
      end

    assigns =
      assign(assigns, %{
        check_value: check_value,
        check_icon: "check_#{background}",
        active_bg_color: "bg-#{accent}",
        inactive_bg_color: "bg-opacity-0",
        error?: error?,
        border_color: get_border_color({false, error?, background}),
        target: target(form)
      })

    ~H"""
    <div
      class="flex flex-row mb-3 gap-5 sm:gap-3 cursor-pointer items-center"
      x-data={"{ active: #{@check_value} }"}
      x-on:click={"active = !active, $parent.focus = '#{@field}'"}
      phx-click="toggle"
      phx-value-checkbox={@field}
      phx-target={@target}
    >
      <div
        class="flex flex-row mb-3 gap-5 sm:gap-3 cursor-pointer items-center"
        x-data={"{ active: #{@check_value} }"}
        x-on:click="active = !active"
        phx-click="toggle"
        phx-value-checkbox={@field}
        phx-target={@target}
      >
        <div
          class="flex-shrink-0 w-6 h-6 rounded"
          x-bind:class={"{ '#{@active_bg_color}': active, '#{@inactive_bg_color} border-2 #{@border_color}': !active }"}
        >
          <img
            x-show="active"
            src={"/images/icons/#{@check_icon}.svg"}
            alt={"#{@field} is selected"}
          />
        </div>
        <div
          class="mt-0.5 text-title6 font-title6 leading-snug"
          x-bind:class={"{ '#{@label_color}': active || #{not @error?}, 'text-warning': !active && #{@error?} }"}
        >
          <%= @label_text %>
        </div>
      </div>
    </div>
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom)
  attr(:target, :any, default: "")
  slot(:inner_block, required: true)

  def inputs(assigns) do
    ~H"""
    <%= for subform <- Phoenix.HTML.Form.inputs_for(@form, @field, phx_target: @target) do %>
      <div>
        <%= render_slot(@inner_block, %{form: subform}) %>
      </div>
    <% end %>
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:active_field, :string, default: nil)
  attr(:options, :list, required: true)
  attr(:selected_option, :atom)
  attr(:target, :any, required: true)
  attr(:placeholder, :string, default: "")
  attr(:label_text, :string)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:disabled, :boolean, default: false)
  attr(:reserve_error_space, :boolean, default: true)
  attr(:debounce, :string, default: "1000")
  attr(:value, :any, default: nil)

  def dropdown(
        %{form: form, field: field, active_field: active_field, background: background} = assigns
      ) do
    errors = form[field].errors
    field_id = String.to_atom(input_id(form, field))
    active? = Atom.to_string(field_id) == active_field
    options_id = "#{field_id}-options"

    idle_border_color =
      if Enum.empty?(errors) do
        "border-grey3"
      else
        "border-warning"
      end

    active_border_color =
      if background == :light do
        "border-primary"
      else
        "border-tertiary"
      end

    current_border_color =
      if active? do
        active_border_color
      else
        idle_border_color
      end

    assigns =
      assign(assigns, %{
        field_id: field_id,
        field_name: input_name(form, field),
        field_value: value(form, assigns),
        current_border_color: current_border_color,
        idle_border_color: idle_border_color,
        active_border_color: active_border_color,
        options_id: options_id,
        active?: active?,
        errors: errors
      })

    ~H"""
    <.field
      field={@field_id}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      error_message={@error_message}
      reserve_error_space={@reserve_error_space}
      active?={@active?}
      errors={@errors}
    >
      <div class="relative">
        <input
          readonly
          type="text"
          id={@field_id}
          name={@field_name}
          value={@field_value}
          placeholder={@placeholder}
          class={"field-input text-grey1 text-bodymedium font-body pl-3 focus:outline-none whitespace-pre-wrap w-full border-2 border-solid rounded h-44px cursor-pointer #{@current_border_color}"}
          idle-class={@idle_border_color}
          active-class={@active_border_color}
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
        <div id={@options_id} class="absolute z-20 left-0 top-48px bg-black bg-opacity-20 w-full hidden">
          <div class="bg-white shadow-2xl rounded">
            <div class="max-h-dropdown overflow-y-scroll py-4">
              <div class="flex flex-col items-left">
                <%= for option <- @options do %>
                  <.dropdown_option option={option} {assigns} />
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </.field>
    """
  end

  attr(:option, :map, required: true)
  attr(:options_id, :string, required: true)
  attr(:text_color, :string, required: true)

  def dropdown_option(
        %{
          option: option,
          selected_option: selected_option,
          options_id: options_id,
          target: target
        } = assigns
      ) do
    text_color =
      if option == selected_option do
        "text-primary"
      else
        "text-grey1"
      end

    js_click =
      JS.hide(to: "##{options_id}")
      |> JS.push("select-option", value: option, target: target)

    assigns =
      assign(assigns, %{
        text_color: text_color,
        js_click: js_click
      })

    ~H"""
    <div class="flex-shrink-0">
      <div
        class="cursor-pointer hover:bg-grey5 px-8 h-10 flex flex-col justify-center"
        phx-click={@js_click}
      >
        <div class={"text-button font-button whitespace-nowrap #{@text_color}"}>
          <%= @option.label %>
        </div>
      </div>
    </div>
    """
  end
end
