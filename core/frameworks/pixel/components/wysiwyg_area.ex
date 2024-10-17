defmodule Frameworks.Pixel.Components.WysiwygArea do
  use Phoenix.LiveComponent

  import Frameworks.Pixel.FormHelpers
  import Phoenix.HTML
  import Phoenix.HTML.Form

  import Frameworks.Pixel.Form
  import Frameworks.Pixel.FormHelpers
  import Frameworks.Pixel.ErrorHelpers, only: [translate_error: 1]

  alias Frameworks.Pixel.TrixPostProcessor

  defmacro __using__(_opts) do
    quote do
      @impl true
      def handle_event(
            "save",
            %{"body_input" => body},
            socket
          ) do
        dbg("hitting save")

        {
          :noreply,
          socket
          |> assign(body: body)
          |> handle_body_update()
        }
      end
    end
  end

  defp active_input_color(%{background: :light}), do: "border-primary"
  defp active_input_color(_), do: "border-tertiary"
  defp active_label_color(%{background: :light}), do: "text-primary"
  defp active_label_color(_), do: "text-tertiary"
  defp field_tag(name), do: "field-#{name}"

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{form: form, field: field} = params, socket) do
    errors =
      if form do
        guarded_errors(form, field)
      else
        []
      end

    has_errors = Enum.count(errors) > 0
    field_id = String.to_atom(input_id(form, field))

    input_static_class =
      "#{field_tag(@input)} field-input text-grey1 text-bodymedium font-body p-4 w-full border-2 focus:outline-none rounded"

    input_dynamic_class = "border-grey3"
    active_color = active_input_color(params)

    {:ok,
     socket
     |> assign(
       field_id: field_id,
       field_name: input_name(form, field),
       field_value:
         html_escape((input_value(form, field) || "") |> TrixPostProcessor.add_target_blank()),
       target: target(form),
       input_static_class: input_static_class,
       input_dynamic_class: input_dynamic_class,
       active_color: active_color,
       errors: errors,
       has_errors: has_errors,
       label_text: nil,
       label_color: "text-grey1",
       background: :light,
       debounce: "1000",
       max_height: "max-h-wysiwyg-editor",
       min_height: "min-h-wysiwyg-editor"
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.field
        field={@field_id}
        label_text={@label_text}
        label_color={@label_color}
        background={@background}
        errors={@errors}
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
            phx-update="stream"
            phx-hook="Wysiwyg"
            data-id={"#{@field_id}_input"}
            data-name={"#{@field_name}_input"}
            data-html={@field_value}
            data-visible={true}
            data-locked={false}
            data-target={@target}
          />
        </div>
      </.field>
    </div>
    """
  end
end
