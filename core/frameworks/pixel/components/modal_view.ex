defmodule Frameworks.Pixel.ModalView do
  use CoreWeb, :pixel
  use Gettext, backend: CoreWeb.Gettext

  require Logger

  import LiveNest.HTML

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Toolbar

  defmacro __using__(_) do
    quote do
      alias Frameworks.Pixel.ModalView

      import ModalView, only: [update_modal_buttons: 3]

      # Handle toolbar action events from the Toolbar LiveComponent
      def consume_event(
            %{name: :toolbar_action, payload: %{action: action}},
            socket
          ) do
        # Forward to the source that published the buttons
        source = Map.get(socket.assigns, :modal_button_source)

        if source do
          Frameworks.Pixel.ModalView.forward_toolbar_action(source, action)
        end

        {:stop, socket}
      end

      def consume_event(
            %{name: :update_modal_buttons, source: source, payload: %{buttons: buttons}},
            socket
          ) do
        {:stop, Frameworks.Pixel.ModalView.update_modal_buttons(socket, source, buttons)}
      end
    end
  end

  def modal_id(%{live_component: live_component}), do: modal_id(live_component)
  def modal_id(%{ref: %{id: id}}), do: id

  attr(:socket, :map, required: true)
  attr(:modal, :map, default: nil)
  attr(:toolbar_buttons, :list, default: [])

  def dynamic(%{modal: nil} = assigns) do
    ~H""
  end

  def dynamic(assigns) do
    ~H"""
      <.background visible={@modal.visible} >
        <.content modal={@modal} socket={@socket} toolbar_buttons={@toolbar_buttons} />
      </.background>
    """
  end

  attr(:visible, :boolean, default: false)
  slot(:inner_block, required: true)

  def background(assigns) do
    ~H"""
    <div class={"modal-view fixed z-50 left-0 top-0 w-full h-full backdrop-blur-md bg-black/30 #{if @visible do "block" else "hidden" end}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  # Legacy style names (deprecated, use aspects instead)
  @allowed_styles [:max, :full, :page, :compact]

  # Modal presets - common aspect combinations
  # Note: :max and :full both use full width but different padding/controls
  # :max = minimal padding (p-4 lg:p-8), close button only
  # :full = large padding (p-4 xl:p-20), toolbar
  @presets %{
    max: [controls: :close, width: :max, height: :full],
    full: [controls: :tools, width: :full, height: :full],
    page: [controls: :tools, width: :wide, height: :full],
    sheet: [controls: :close, width: :wide, height: :tall, scrollable: true, context: true],
    compact: [controls: :close, width: :narrow]
  }

  # Default aspect values
  @defaults [
    controls: :none,
    width: :medium,
    height: :auto,
    scrollable: false,
    context: false
  ]

  @doc """
  Resolves modal aspects from style (legacy), preset, or explicit options.
  Returns a keyword list of resolved aspects.
  """
  def resolve_aspects(style_or_preset, overrides \\ [])

  def resolve_aspects(style, overrides) when is_atom(style) do
    base =
      if Map.has_key?(@presets, style) do
        @presets[style]
      else
        # Legacy style - map to aspects
        legacy_to_aspects(style)
      end

    @defaults
    |> Keyword.merge(base)
    |> Keyword.merge(overrides)
  end

  def resolve_aspects(opts, _overrides) when is_list(opts) do
    @defaults
    |> Keyword.merge(opts)
  end

  # Legacy style to aspects mapping
  @legacy_aspects %{
    max: [controls: :close, width: :max, height: :full],
    full: [controls: :tools, width: :full, height: :full],
    page: [controls: :tools, width: :wide, height: :full],
    sheet: [controls: :close, width: :medium, scrollable: true],
    compact: [controls: :close, width: :narrow]
  }

  # Width classes
  # :max = truly full width with minimal padding (p-4 lg:p-8)
  # :full = full width with larger padding (p-4 xl:p-20)
  # others = max-width with full width fallback for small screens
  @width_classes %{
    narrow: "w-full max-w-[500px]",
    medium: "w-full max-w-[700px]",
    wide: "w-full max-w-[960px]",
    full: "w-full",
    max: "w-full"
  }

  # Height classes for outer wrapper
  @height_classes %{
    auto: "",
    tall: "",
    full: "h-full"
  }

  # Height classes for inner modal box
  @inner_height_classes %{
    auto: "",
    tall: "max-h-[80vh]",
    full: "h-full"
  }

  # Padding classes per width type
  # :max = minimal padding for maximum content area
  # :full = larger padding for comfortable viewing
  # others = standard padding
  @padding_classes %{
    max: "p-4 lg:p-8",
    full: "p-4 xl:p-20",
    wide: "p-4 sm:px-10 sm:py-20",
    medium: "p-4 sm:px-10 sm:py-20",
    narrow: "px-4 sm:px-10"
  }

  defp legacy_to_aspects(style), do: Map.get(@legacy_aspects, style, [])
  defp width_class(width), do: Map.get(@width_classes, width, "")
  defp height_class(height), do: Map.get(@height_classes, height, "")
  defp inner_height_class(height), do: Map.get(@inner_height_classes, height, "")
  defp padding_class(width), do: Map.get(@padding_classes, width, "p-4 sm:px-10 sm:py-20")

  attr(:socket, :map, required: true)
  attr(:modal, :map, required: true)
  attr(:toolbar_buttons, :list, default: [])

  def content(assigns) do
    ~H"""
      <div class={"w-full h-full #{if @modal.visible do "block" else "hidden" end}"} >
        <div class="flex flex-row items-center justify-center w-full h-full">
          <.frame modal={@modal} socket={@socket} toolbar_buttons={@toolbar_buttons} />
        </div>
      </div>
    """
  end

  attr(:socket, :map, required: true)
  attr(:modal, :map, required: true)
  attr(:toolbar_buttons, :list, default: [])

  def frame(%{modal: %{style: style}} = assigns) when is_atom(style) do
    if style in @allowed_styles do
      render_legacy_frame(assigns)
    else
      assigns
      |> assign(:frame, build_frame(resolve_aspects(style), assigns.modal))
      |> render_frame()
    end
  end

  def frame(%{modal: %{style: opts}} = assigns) when is_list(opts) do
    assigns
    |> assign(:frame, build_frame(resolve_aspects(opts), assigns.modal))
    |> render_frame()
  end

  defp build_frame(aspects, modal) do
    width_key = aspects[:width]
    height_key = aspects[:height]

    %{
      width_class: width_class(width_key),
      height_class: height_class(height_key),
      inner_height_class: inner_height_class(height_key),
      padding_class: padding_class(width_key),
      controls: aspects[:controls],
      scrollable: aspects[:scrollable],
      header: build_header(aspects, modal)
    }
  end

  defp render_legacy_frame(assigns) do
    ~H"""
      <%= case @modal.style do %>
        <% :max -> %>
          <.max modal={@modal} socket={@socket} />
        <% :full -> %>
          <.full modal={@modal} socket={@socket} toolbar_buttons={@toolbar_buttons} />
        <% :page -> %>
          <.page modal={@modal} socket={@socket} toolbar_buttons={@toolbar_buttons} />
        <% :sheet -> %>
          <.sheet modal={@modal} socket={@socket} />
        <% :compact -> %>
          <.compact modal={@modal} socket={@socket} />
      <% end %>
    """
  end

  defp render_frame(assigns) do
    ~H"""
    <div class={"modal-dynamic #{@frame.width_class} #{@frame.height_class} #{@frame.padding_class}"}>
      <div class={"relative flex flex-col w-full bg-white rounded shadow-floating #{@frame.inner_height_class} pt-8 pb-8"}>
        <.header {@frame.header} modal={@modal} />

        <div class={"flex-1 px-8 #{if @frame.scrollable do "overflow-y-scroll" else "" end}"}>
          <.element {Map.from_struct(@modal.element)} socket={@socket} />
        </div>

        <div :if={@frame.controls == :tools} class="flex-shrink-0">
          <.live_component
            module={Toolbar}
            id="modal_toolbar"
            close_button={close_icon_label_button(@modal)}
            mobile_close_button={close_icon_button(@modal)}
            buttons={@toolbar_buttons}
          />
        </div>

        <div :if={@frame.controls == :actions} class="flex-shrink-0 px-8 pt-6">
          <div class="flex flex-row justify-center gap-4">
            <Button.dynamic_bar buttons={@toolbar_buttons} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp build_header(aspects, modal) do
    show_context = aspects[:context]
    show_close = aspects[:controls] == :close

    # Check both modal.options (LiveNest) and modal.element.options (Fabric)
    context =
      Keyword.get(modal.options, :context) ||
        Keyword.get(modal.element.options, :context)

    %{
      visible: show_context || show_close,
      context: if(show_context, do: context),
      show_close: show_close
    }
  end

  attr(:visible, :boolean, required: true)
  attr(:context, :string, default: nil)
  attr(:show_close, :boolean, required: true)
  attr(:modal, :map, required: true)

  defp header(%{visible: false} = assigns), do: ~H""

  defp header(assigns) do
    ~H"""
    <div class="flex-shrink-0 px-8 pb-4">
      <div class="flex flex-row items-start">
        <div class="flex-grow">
          <Text.title6 :if={@context} color="text-grey2"><%= @context %></Text.title6>
        </div>
        <Button.dynamic :if={@show_close} {close_icon_button(@modal)} />
      </div>
    </div>
    """
  end

  attr(:socket, :map, required: true)
  attr(:modal, :map, required: true)

  def max(assigns) do
    ~H"""
    <div class="flex flex-row items-center justify-center w-full h-full">
      <div class={"modal-max p-4 lg:p-8 w-full h-full"}>
        <div class={"relative flex flex-col w-full bg-white rounded shadow-floating h-full pt-8 sm:pb-8"}>
          <%!-- HEADER --%>
          <div class="shrink-0 px-8">
            <div class="flex flex-row">
              <div class="flex-grow">
                <.title3 modal={@modal} />
              </div>
              <Button.dynamic {close_icon_button(@modal)} />
            </div>
          </div>
          <%!-- BODY --%>
          <div class="h-ftesull overflow-y-scroll scrollbar-hidden px-8">
            <.element {Map.from_struct(@modal.element)} socket={@socket} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:socket, :map, required: true)
  attr(:modal, :map, required: true)
  attr(:toolbar_buttons, :list, default: [])

  def full(assigns) do
    ~H"""
    <div class="flex flex-row items-center justify-center w-full h-full">
    <div class={"modal-full p-4 xl:p-20 w-full h-full"}>
      <div class={"relative flex flex-col w-full bg-white rounded shadow-floating h-full pt-4 sm:pt-8 overflow-hidden"}>
          <%!-- HEADER --%>
          <%!-- OPTIONAL LIGHT GREY TITLE THAT DESCRIBES THE CONTEXT OF THE MODAL --%>
          <div :if={Keyword.get(@modal.element.options, :header)} class="px-4 sm:px-8">
            <Text.title6 color="text-grey2">
              <%= Keyword.get(@modal.element.options, :header) %>
            </Text.title6>
            <.spacing value="XS" />
          </div>
          <%!-- BODY --%>
          <div class="relative flex-1 overflow-y-scroll px-4 sm:px-8 overscroll-contain overflow-visible">
            <.element {Map.from_struct(@modal.element)} socket={@socket} />
          </div>
          <%!-- TOOLBAR --%>
          <div class="flex-shrink-0">
            <.live_component
              module={Toolbar}
              id="modal_toolbar"
              close_button={close_icon_label_button(@modal)}
              mobile_close_button={close_icon_button(@modal)}
              buttons={@toolbar_buttons}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:socket, :map, required: true)
  attr(:modal, :map, required: true)
  attr(:toolbar_buttons, :list, default: [])

  def page(assigns) do
    ~H"""
      <div class={"modal-page w-[960px] p-4 sm:px-10 sm:py-20 h-full"}>
        <div class={"flex flex-col w-full bg-white rounded shadow-floating h-full pt-4 sm:pt-8"}>
          <%!-- BODY --%>
          <div class="h-full overflow-y-scroll px-8">
            <.element {Map.from_struct(@modal.element)} socket={@socket} />
          </div>
           <%!-- TOOLBAR --%>
           <div class="flex-shrink-0">
            <.live_component
              module={Toolbar}
              id="modal_toolbar"
              close_button={close_icon_label_button(@modal)}
              mobile_close_button={close_icon_button(@modal)}
              buttons={@toolbar_buttons}
            />
          </div>
        </div>
      </div>
    """
  end

  attr(:socket, :map, required: true)
  attr(:modal, :map, required: true)

  def sheet(assigns) do
    context = Keyword.get(assigns.modal.element.options, :context)
    assigns = assign(assigns, :context, context)

    ~H"""
      <div class={"modal-sheet w-[960px] p-4 sm:px-10 sm:py-20"}>
        <div class={"relative flex flex-col w-full bg-white rounded shadow-floating pt-8 pb-8"}>
          <%!-- Header with optional context --%>
          <div :if={@context} class="px-8 pb-4">
            <Text.title6 color="text-grey2"><%= @context %></Text.title6>
          </div>
          <%!-- Close button --%>
          <div class="absolute z-30 top-8 right-8">
            <Button.dynamic {close_icon_button(@modal)} />
          </div>
          <%!-- BODY --%>
          <div class="h-full overflow-y-scroll px-8">
            <.element {Map.from_struct(@modal.element)} socket={@socket} />
          </div>
        </div>
      </div>
    """
  end

  attr(:socket, :map, required: true)
  attr(:modal, :map, required: true)

  def compact(assigns) do
    ~H"""
      <div class="modal-dialog w-[700px] px-4 sm:px-10">
        <div class="relative h-full w-full bg-white pt-6 pb-9 px-9 rounded shadow-floating">
          <%!-- Floating close button --%>
          <div class="absolute z-30 top-6 right-9">
            <Button.dynamic {close_icon_button(@modal)} />
          </div>
          <%!-- BODY --%>
          <div class="h-full w-full overflow-y-scroll">
            <.element {Map.from_struct(@modal.element)} socket={@socket} />
          </div>
        </div>
      </div>
    """
  end

  attr(:modal, :map, required: true)
  attr(:centered?, :boolean, default: false)

  def title2(assigns) do
    ~H"""
      <Text.title2 align={"#{if @centered? do "text-center" else "text-left" end}"}>
        <%= Keyword.get(@modal.element.options, :title) %>
      </Text.title2>
    """
  end

  attr(:modal, :map, required: true)

  def title3(assigns) do
    ~H"""
      <Text.title3>
        <%= Keyword.get(@modal.element.options, :title) %>
      </Text.title3>
    """
  end

  defp close_icon_label_button(%LiveNest.Modal{element: %{id: element_id}}) do
    %{
      action: %{type: :send, event: "close_modal", item: element_id, target: nil},
      face: %{
        type: :plain,
        icon: :close,
        label: dgettext("eyra-pixel", "modal.back.button"),
        icon_align: :left
      }
    }
  end

  defp close_icon_button(%LiveNest.Modal{element: %{id: element_id}}) do
    %{
      action: %{type: :send, event: "close_modal", item: element_id, target: nil},
      face: %{type: :icon, icon: :close}
    }
  end

  @doc """
  Updates modal toolbar buttons in socket assigns.
  Called when embedded view publishes :update_modal_buttons event.
  Stores source for event forwarding and buttons for the Toolbar LiveComponent.
  """
  def update_modal_buttons(socket, source, buttons) when is_list(buttons) do
    socket
    |> Phoenix.Component.assign(:modal_toolbar_buttons, buttons)
    |> Phoenix.Component.assign(:modal_button_source, source)
  end

  @doc """
  Forwards a toolbar action to the target LiveView process.
  Source is a tuple {pid, element_id} from LiveNest.Event.
  """
  def forward_toolbar_action({pid, _element_id}, action) when is_pid(pid) and is_atom(action) do
    send(pid, {:toolbar_action, action})
  end
end
