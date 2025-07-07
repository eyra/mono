defmodule Frameworks.Pixel.Form do
  @moduledoc false
  use CoreWeb, :pixel

  import Frameworks.Pixel.ImagePreview

  import Phoenix.HTML
  # , only: [input_id: 2, input_name: 2, input_value: 2]
  import Phoenix.HTML.Form

  import Frameworks.Pixel.FormHelpers
  import Frameworks.Pixel.ErrorHelpers, only: [translate_error: 1]

  alias Phoenix.LiveView.JS
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text

  @label "label"
  @input "input"
  @error "error"
  @error_space "error_space"
  @error_message "error_message"

  defp active_input_color(%{background: :light}), do: "border-primary"
  defp active_input_color(_), do: "border-tertiary"

  defp active_label_color(%{background: :light}), do: "text-primary"
  defp active_label_color(_), do: "text-tertiary"

  defp field_tag(name), do: "field-#{name}"
  defp field_item_id(field, item), do: "#{field}_#{item}"

  attr(:field, :atom, required: true)
  attr(:label_text, :string)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, required: true)
  attr(:read_only, :boolean, default: false)
  attr(:errors, :list, default: [])
  attr(:error_message, :string, default: nil)
  attr(:reserve_error_space, :boolean, default: true)
  attr(:extra_space, :boolean, default: true)

  slot(:inner_block, required: true)

  def field(%{field: field, errors: errors} = assigns) do
    has_errors = Enum.count(errors) > 0

    error_space_id = field_item_id(field, @error_space)
    error_message_id = field_item_id(field, @error_message)
    error_static_class = "#{field_tag(@error)} text-caption font-caption text-warning"

    label_id = field_item_id(field, @label)
    label_static_class = "#{field_tag(@label)} mt-0.5 text-title6 font-title6 leading-snug"
    label_dynamic_class = "text-grey1"

    active_color = active_label_color(assigns)

    assigns =
      assign(assigns, %{
        label_id: label_id,
        error_space_id: error_space_id,
        error_message_id: error_message_id,
        error_static_class: error_static_class,
        label_static_class: label_static_class,
        label_dynamic_class: label_dynamic_class,
        active_color: active_color,
        has_errors: has_errors
      })

    ~H"""
    <div id={"#{field_tag(@field)}"} data-field-id={@field} phx-hook="LiveField">
      <div>
        <%= if @label_text do %>
          <div>
            <div
              id={@label_id}
              class={"#{@label_static_class} #{@label_dynamic_class}"}
              __eyra_field_id={@field}
              __eyra_field_has_errors={@has_errors}
              __eyra_field_static_class={@label_static_class}
              __eyra_field_active_color={@active_color}
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
        <%= if Enum.count(@errors) > 0 do %>
          <div
            id={@error_message_id}
            class={@error_static_class}
            __eyra_field_id={@field}
          >
            <%= for error <- @errors do %>
              <div>
                <%= translate_error(error) %>
              </div>
            <% end %>
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

  def input(%{form: form, field: field} = assigns) do
    errors = guarded_errors(form, field)
    field_id = String.to_atom(input_id(form, field))
    input_id = field_item_id(field_id, @input)

    input_static_class =
      "#{field_tag(@input)} text-grey1 text-bodymedium font-body pl-3 w-full border-2 border-solid focus:outline-none rounded h-44px"

    input_dynamic_class = "border-grey3"
    active_color = active_input_color(assigns)
    has_errors = Enum.count(errors) > 0

    assigns =
      assign(assigns, %{
        field_id: field_id,
        field_name: input_name(form, field),
        field_value: value(form, assigns),
        target: target(form),
        input_id: input_id,
        input_static_class: input_static_class,
        input_dynamic_class: input_dynamic_class,
        active_color: active_color,
        errors: errors,
        has_errors: has_errors
      })

    ~H"""
    <.field
      field={@field_id}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      reserve_error_space={@reserve_error_space}
      errors={@errors}
    >
      <%= if @disabled do %>
        <input
          type={@type}
          id={@input_id}
          name={@field_name}
          value={@field_value}
          placeholder={@placeholder}
          class={"#{@input_static_class} text-grey3"}
          disabled
        />
      <% else %>
        <input
          type={@type}
          id={@input_id}
          name={@field_name}
          value={@field_value}
          min="0"
          placeholder={@placeholder}
          maxlength={@maxlength}
          phx-target={@target}
          phx-debounce={@debounce}
          class={[@input_static_class, @input_dynamic_class]}
          __eyra_field_id={@field_id}
          __eyra_field_has_errors={@has_errors}
          __eyra_field_static_class={@input_static_class}
          __eyra_field_active_color={@active_color}
        />
      <% end %>
    </.field>
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
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
  attr(:label_text, :string, default: nil)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:placeholder, :string, default: "")
  attr(:reserve_error_space, :boolean, default: true)
  attr(:debounce, :string, default: "1000")
  attr(:maxlength, :string, default: "1000")
  attr(:disabled, :boolean, default: false)

  def text_input(assigns) do
    ~H"""
    <.input
      form={@form}
      field={@field}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      placeholder={@placeholder}
      reserve_error_space={@reserve_error_space}
      debounce={@debounce}
      maxlength={@maxlength}
      type="text"
      disabled={@disabled}
    />
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:label_text, :string, default: nil)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:placeholder, :string, default: "")
  attr(:reserve_error_space, :boolean, default: true)
  attr(:debounce, :string, default: "1000")
  attr(:maxlength, :string, default: "1000")
  attr(:value, :string, default: "")

  # FIXME: discuss how to make this neater. Now I just force the display of the
  # provided value
  # Used for working with providing a list of values in one text field in a form.
  def list_input(assigns) do
    ~H"""
    <.input
      form={@form}
      field={@field}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      placeholder={@placeholder}
      reserve_error_space={@reserve_error_space}
      debounce={@debounce}
      maxlength={@maxlength}
      type="text"
      value={@value}
    />
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:placeholder, :string, default: "")
  attr(:label_text, :string, default: nil)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:reserve_error_space, :boolean, default: true)
  attr(:debounce, :string, default: "1000")

  def url_input(assigns) do
    ~H"""
    <.input
      form={@form}
      field={@field}
      placeholder={@placeholder}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      reserve_error_space={@reserve_error_space}
      debounce={@debounce}
      type="url"
    />
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:label_text, :string)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:reserve_error_space, :boolean, default: true)
  attr(:debounce, :string, default: "1000")

  def password_input(assigns) do
    ~H"""
    <.input
      form={@form}
      field={@field}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      reserve_error_space={@reserve_error_space}
      debounce={@debounce}
      type="password"
    />
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:label_text, :string)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:disabled, :boolean, default: false)
  attr(:reserve_error_space, :boolean, default: true)

  def date_input(assigns) do
    ~H"""
    <.input
      form={@form}
      field={@field}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      reserve_error_space={@reserve_error_space}
      type="date"
      disabled={@disabled}
      debounce={""}
    />
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:label_text, :string)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:disabled, :boolean, default: false)
  attr(:reserve_error_space, :boolean, default: true)

  def datetime_input(assigns) do
    ~H"""
    <.input
      form={@form}
      field={@field}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      reserve_error_space={@reserve_error_space}
      type="datetime-local"
      disabled={@disabled}
      debounce={""}
    />
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:label_text, :string)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:reserve_error_space, :boolean, default: true)

  def email_input(assigns) do
    ~H"""
    <.input
      form={@form}
      field={@field}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      reserve_error_space={@reserve_error_space}
      type="email"
    />
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:placeholder, :string, default: "")
  attr(:label_text, :string, default: nil)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:debounce, :string, default: "1000")
  attr(:height, :string, default: "h-64")
  attr(:reserve_error_space, :boolean, default: true)

  def text_area(%{form: form, field: field, height: height} = assigns) do
    errors = guarded_errors(form, field)
    has_errors = Enum.count(errors) > 0
    field_id = String.to_atom(input_id(form, field))

    input_static_class =
      "#{field_tag(@input)} field-input text-grey1 text-bodymedium font-body pl-3 pt-2 w-full #{height} border-2 focus:outline-none rounded"

    input_dynamic_class = "border-grey3"
    active_color = active_input_color(assigns)

    assigns =
      assign(assigns, %{
        field_id: field_id,
        field_name: input_name(form, field),
        field_value: html_escape(input_value(form, field) || ""),
        target: target(form),
        input_static_class: input_static_class,
        input_dynamic_class: input_dynamic_class,
        active_color: active_color,
        errors: errors,
        has_errors: has_errors
      })

    ~H"""
    <.field
      field={@field_id}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      errors={@errors}
      reserve_error_space={@reserve_error_space}
      extra_space={false}
    >
      <textarea
        id={@field_id}
        name={@field_name}
        placeholder={@placeholder}
        class={[@input_static_class, @input_dynamic_class]}
        __eyra_field_id={@field_id}
        __eyra_field_has_errors={@has_errors}
        __eyra_field_static_class={@input_static_class}
        __eyra_field_active_color={@active_color}
        phx-target={@target}
        phx-debounce={@debounce}
      ><%= @field_value %></textarea>
    </.field>
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:label_text, :string, default: nil)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:debounce, :string, default: "1000")
  attr(:min_height, :string, default: "min-h-wysiwyg-editor")
  attr(:max_height, :string, default: "max-h-wysiwyg-editor")
  attr(:visible, :boolean, default: true)
  attr(:reserve_error_space, :boolean, default: true)

  def wysiwyg_area(%{form: form, field: field} = assigns) do
    errors = guarded_errors(form, field)
    has_errors = Enum.count(errors) > 0
    field_id = String.to_atom(input_id(form, field))

    input_static_class =
      "#{field_tag(@input)} field-input text-grey1 text-bodymedium font-body p-4 w-full border-2 focus:outline-none rounded"

    input_dynamic_class = "border-grey3"
    active_color = active_input_color(assigns)

    assigns =
      assign(assigns, %{
        field_id: field_id,
        field_name: input_name(form, field),
        field_value: html_escape(input_value(form, field) || ""),
        target: target(form),
        input_static_class: input_static_class,
        input_dynamic_class: input_dynamic_class,
        active_color: active_color,
        errors: errors,
        has_errors: has_errors
      })

    ~H"""
    <div class={if @visible do "visible" else "hidden" end}>
    <.field
      field={@field_id}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      errors={@errors}
      reserve_error_space={@reserve_error_space}
      extra_space={false}
    >
      <div
        id={@field_id}
        name={@field_name}
        class={[@input_static_class, @input_dynamic_class]}
        __eyra_field_id={@field_id}
        __eyra_field_has_errors={@has_errors}
        __eyra_field_static_class={@input_static_class}
        __eyra_field_active_color={@active_color}
      >
        <div id={"#{@field_id}_wysiwyg"}
          phx-update="ignore"
          phx-hook="Wysiwyg"
          data-id={"#{@field_id}_input"}
          data-name={"#{@field_name}_input"}
          data-html={@field_value}
          data-visible={true}
          data-locked={false}
          data-target={@target}
          data-min-height={@min_height}
          data-max-height={@max_height}
        />
      </div>
    </.field>
    </div>
    """
  end

  attr(:static_path, :any, required: true)
  attr(:label_text, :string, default: nil)
  attr(:label_color, :string, default: "text-grey1")
  attr(:photo_url, :string, required: true)
  attr(:uploads, :any, required: true)
  attr(:primary_button_text, :string, required: true)
  attr(:secondary_button_text, :string, required: true)
  attr(:placeholder, :string, default: "profile_photo_default")

  def photo_input(assigns) do
    ~H"""
    <%= if @label_text do %>
      <Text.title6><%= @label_text %></Text.title6>
    <% end %>
    <div class="flex flex-row items-center">
      <.image_preview
        image_url={@photo_url}
        placeholder={"/images/#{@placeholder}.svg"}
        shape="w-image-preview-circle sm:w-image-preview-circle-sm h-image-preview-circle sm:h-image-preview-circle-sm rounded-full"
      />
      <.spacing value="S" direction="l" />
      <div class="flex-wrap">
        <%= if @photo_url do %>
          <Button.dynamic
            action={%{type: :label, field: @uploads.photo.ref}}
            face={%{type: :secondary, label: @secondary_button_text}}
          />
        <% else %>
        <Button.dynamic
            action={%{type: :label, field: @uploads.photo.ref}}
            face={%{type: :primary, label: @primary_button_text}}
          />
        <% end %>
        <div class="hidden">
          <.live_file_input upload={@uploads.photo} />
        </div>
      </div>
    </div>
    """
  end

  attr(:static_path, :any, required: true)
  attr(:label_text, :string, default: nil)
  attr(:label_color, :string, default: "text-grey1")
  attr(:image_url, :string, required: true)
  attr(:uploads, :any, required: true)
  attr(:primary_button_text, :string, required: true)
  attr(:secondary_button_text, :string, required: true)
  attr(:loading, :boolean, default: false)

  def image_input(assigns) do
    ~H"""
    <%= if @label_text do %>
      <Text.title6><%= @label_text %></Text.title6>
    <% end %>
    <div class="flex flex-row items-top">
      <.image_preview
        image_url={@image_url}
        placeholder={"/images/image_placeholder.svg"}
        shape="w-image-preview sm:w-image-preview-sm h-image-preview sm:h-image-preview-sm"
      />
      <.spacing value="S" direction="l" />
      <div class="flex-wrap">
        <%= if @image_url do %>
          <Button.dynamic
            action={%{type: :label, field: @uploads.image.ref}}
            face={%{type: :secondary, label: @secondary_button_text, loading: @loading}}
          />
        <% else %>
          <Button.dynamic
            action={%{type: :label, field: @uploads.image.ref}}
            face={%{type: :primary, label: @primary_button_text, loading: @loading}}
          />
        <% end %>
        <div class="hidden">
          <.live_file_input upload={@uploads.image} />
        </div>
      </div>
    </div>
    """
  end

  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)
  attr(:label_text, :string, default: nil)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:items, :list, required: true)

  def radio_group(%{form: form, field: field} = assigns) do
    field_id = String.to_atom(input_id(form, field))
    field_name = input_name(form, field)

    assigns = assign(assigns, %{field_id: field_id, field_name: field_name})

    ~H"""
    <.field
      field={@field_id}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      extra_space={false}
    >
      <div class="flex flex-row gap-8 ml-[6px] mt-3">
        <%= for item <- @items do %>
          <label class="cursor-pointer flex flex-row gap-[18px] items-center">
            <input
              id={"#{@field_id}_#{item.id}"}
              value={item.id}
              type="radio"
              name={@field_name}
              checked={item.active}
              class="cursor-pointer appearance-none w-3 h-3 rounded-full outline outline-2 outline-offset-4 outline-grey3 checked:bg-primary checked:outline-primary"
            />
            <div class="text-label font-label text-grey1 select-none mt-1"><%= item.value %></div>
          </label>
        <% end %>
      </div>
    </.field>
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
        check_icon: "check_#{background}.svg",
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
            src={~p"/images/icons/#{@check_icon}"}
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
  attr(:field, :atom, required: true)
  attr(:options, :list, required: true)
  attr(:target, :any, required: true)
  attr(:placeholder, :string, default: "")
  attr(:label_text, :string)
  attr(:label_color, :string, default: "text-grey1")
  attr(:background, :atom, default: :light)
  attr(:disabled, :boolean, default: false)
  attr(:reserve_error_space, :boolean, default: true)
  attr(:debounce, :string, default: "1000")
  attr(:value, :any, default: nil)

  def dropdown(%{form: form, field: field, options: options} = assigns) do
    errors = guarded_errors(form, field)
    field_id = String.to_atom(input_id(form, field))
    options_id = "#{field_id}-options"

    field_value =
      if raw_value = value(form, assigns) do
        case Enum.find(options, "", &(Atom.to_string(&1.id) == raw_value)) do
          %{value: value} -> value
          _ -> raw_value
        end
      else
        ""
      end

    input_static_class =
      "#{field_tag(@input)} text-grey1 text-bodymedium font-body pl-3 focus:outline-none whitespace-pre-wrap w-full border-2 border-solid rounded h-44px cursor-pointer"

    input_dynamic_class = "border-grey3"
    active_color = active_input_color(assigns)
    has_errors = Enum.count(errors) > 0

    js_click =
      JS.focus(to: "##{field_id}")
      |> JS.toggle(to: "##{options_id}")
      |> JS.toggle(to: "##{options_id}-dropdown-img")
      |> JS.toggle(to: "##{options_id}-dropup-img")

    assigns =
      assign(assigns, %{
        field_id: field_id,
        field_name: input_name(form, field),
        field_value: field_value,
        options_id: options_id,
        input_static_class: input_static_class,
        input_dynamic_class: input_dynamic_class,
        active_color: active_color,
        errors: errors,
        has_errors: has_errors,
        js_click: js_click
      })

    ~H"""
    <.field
      field={@field_id}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      reserve_error_space={@reserve_error_space}
      errors={@errors}
    >
      <div class="relative" >
        <input
          type="text"
          id={@field_id}
          name={@field_name}
          value={@field_value}
          placeholder={@placeholder}
          class={"#{@input_static_class} #{@input_dynamic_class}"}
          __eyra_field_id={@field_id}
          __eyra_field_has_error={@has_errors}
          __eyra_field_static_class={@input_static_class}
          __eyra_field_active_color={@active_color}
          phx-target={@target}
        />
        <div class="absolute z-20 right-0 top-0 h-44px flex flex-col justify-center">
          <div id={"#{@options_id}-dropdown-img"}>
            <img class="mr-3" src={~p"/images/icons/dropdown.svg"} alt="Dropdown" phx-click={@js_click}>
          </div>
          <div id={"#{@options_id}-dropup-img"} class="hidden">
            <img class="mr-3" src={~p"/images/icons/dropup.svg"} alt="Dropup" phx-click={@js_click}>
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
  attr(:field_value, :string, required: true)
  attr(:options_id, :string, required: true)
  attr(:target, :any, required: true)

  def dropdown_option(
        %{
          option: option,
          field_value: field_value,
          options_id: options_id,
          target: target
        } = assigns
      ) do
    text_color =
      if option.value == field_value do
        "text-primary"
      else
        "text-grey1"
      end

    js_click =
      JS.hide(to: "##{options_id}")
      |> JS.toggle(to: "##{options_id}-dropdown-img")
      |> JS.toggle(to: "##{options_id}-dropup-img")
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
          <%= @option.value %>
        </div>
      </div>
    </div>
    """
  end
end
