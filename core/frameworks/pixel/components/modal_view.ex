defmodule Frameworks.Pixel.ModalView do
  use CoreWeb, :pixel
  use Gettext, backend: CoreWeb.Gettext

  require Logger

  import LiveNest.HTML
  import Frameworks.Pixel.Toolbar

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text

  defmacro __using__(_) do
    quote do
      alias Frameworks.Pixel.ModalView

      import Frameworks.Pixel.ModalView, only: [modal_id: 1]

      @impl true
      def handle_event("prepare_modal", modal, socket) do
        Map.get(socket.assigns, :modals)

        {
          :noreply,
          socket |> upsert_modal(modal |> Map.put(:prepared, true))
        }
      end

      @impl true
      def handle_event("show_modal", modal, socket) do
        modals = Map.get(socket.assigns, :modals)

        {
          :noreply,
          socket |> upsert_modal(modal |> Map.put(:prepared, false))
        }
      end

      @impl true
      def handle_event("hide_modal", modal, socket) do
        {:noreply, socket |> delete_modal(modal)}
      end

      @impl true
      def handle_event("hide_modals", _, socket) do
        {
          :noreply,
          socket |> assign(modals: [])
        }
      end

      @impl true
      def handle_event("close_modal", %{"item" => modal_id}, socket) do
        modal =
          socket
          |> modals()
          |> Enum.find(&(modal_id(&1) == modal_id))
          |> tap(
            &if &1 == nil do
              Logger.warning("Modal not found with ref: #{modal_id}")
            end
          )

        {
          :noreply,
          socket |> close_modal(modal)
        }
      end

      def close_modal(socket, %{live_component: %{ref: ref}} = modal) do
        socket
        |> delete_modal(modal)
        |> Fabric.handle_modal_closed(ref)
      end

      def upsert_modal(socket, modal) do
        if modal_exists?(socket, modal) do
          update_modal(socket, modal)
        else
          insert_modal(socket, modal)
        end
      end

      def show_modal(socket, modal) do
        if modal_exists?(socket, modal) do
          update_modal(socket, modal)
        else
          insert_modal(socket, modal)
        end
      end

      def update_modal(socket, modal) do
        socket
        |> delete_modal(modal)
        |> insert_modal(modal)
      end

      def insert_modal(%{assigns: %{modals: modals}} = socket, modal) do
        socket |> assign(modals: modals ++ [modal])
      end

      def delete_modal(%{assigns: %{modals: modals}} = socket, modal) do
        assign(socket, modals: Enum.reject(modals, &(modal_id(&1) == modal_id(modal))))
      end

      def modal_exists?(socket, modal) do
        socket
        |> modals()
        |> Enum.find(&(modal_id(&1) == modal_id(modal))) != nil
      end

      def modals(%{assigns: %{modals: modals}} = socket), do: modals
      def modals(_socket), do: []
    end
  end

  def modal_id(%{live_component: live_component}), do: modal_id(live_component)
  def modal_id(%{ref: %{id: id}}), do: id

  attr(:modal, :map, default: nil)

  def dynamic(assigns) do
    ~H"""
      <.background visible={@modal.visible} >
        <.content modal={@modal} />
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

  @allowed_styles [:max, :full, :page, :sheet, :compact]

  attr(:modal, :map, required: true)

  def content(assigns) do
    ~H"""
      <div class={"w-full h-full #{if @modal.visible do "block" else "hidden" end}"} >
        <div class="flex flex-row items-center justify-center w-full h-full">
          <.frame modal={@modal} />
        </div>
      </div>
    """
  end

  attr(:modal, :map, required: true)

  def frame(%{modal: %{style: style}} = assigns) do
    unless style in @allowed_styles do
      raise ArgumentError,
            "Invalid style: #{style}. Allowed styles are: #{Enum.join(@allowed_styles, ", ")}"
    end

    ~H"""
      <%= if @modal.style == :max do %>
        <.max modal={@modal} />
      <% end %>
      <%= if @modal.style == :full do %>
        <.full modal={@modal} />
      <% end %>
      <%= if @modal.style == :page do %>
        <.page modal={@modal} />
      <% end %>
      <%= if @modal.style == :sheet do %>
        <.sheet modal={@modal} />
      <% end %>
      <%= if @modal.style == :compact do %>
        <.compact modal={@modal} />
      <% end %>
    """
  end

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
          <div class="h-full overflow-y-scroll scrollbar-hidden px-8">
            <.element {Map.from_struct(@modal.element)} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:modal, :map, required: true)

  def full(assigns) do
    ~H"""
    <div class="flex flex-row items-center justify-center w-full h-full">
    <div class={"modal-full p-4 xl:p-20 w-full h-full"}>
      <div class={"relative flex flex-col w-full bg-white rounded shadow-floating h-full pt-4 sm:pt-8 overflow-hidden"}>
          <%!-- BODY --%>
          <div class="h-full overflow-y-scroll px-4 sm:px-8 overscroll-contain overflow-visible">
            <.element {Map.from_struct(@modal.element)} />
          </div>
          <%!-- TOOLBAR --%>
          <div class="flex-shrink-0">
            <.toolbar close_button={close_icon_label_button(@modal)} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:modal, :map, required: true)

  def page(assigns) do
    ~H"""
      <div class={"modal-page w-[960px] p-4 sm:px-10 sm:py-20 h-full"}>
        <div class={"flex flex-col w-full bg-white rounded shadow-floating h-full pt-4 sm:pt-8"}>
          <%!-- BODY --%>
          <div class="h-full overflow-y-scroll px-8">
            <.element {Map.from_struct(@modal.element)} />
          </div>
           <%!-- TOOLBAR --%>
           <div class="flex-shrink-0">
            <.toolbar close_button={close_icon_label_button(@modal)} />
          </div>
        </div>
      </div>
    """
  end

  attr(:modal, :map, required: true)

  def sheet(assigns) do
    ~H"""
      <div class={"modal-sheet w-[960px] p-4 sm:px-10 sm:py-20"}>
        <div class={"flex flex-col w-full bg-white rounded shadow-floating pt-8 pb-8"}>
          <%!-- HEADER --%>
          <div class="shrink-0 px-8">
            <div class="flex flex-row">
              <div class="flex-grow">
                <.title2 modal={@modal} centered?={true}/>
              </div>
              <Button.dynamic {close_icon_button(@modal)} />
            </div>
          </div>
          <%!-- BODY --%>
          <div class="h-full overflow-y-scroll px-8">
            <.element {Map.from_struct(@modal.element)} />
          </div>
        </div>
      </div>
    """
  end

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
            <.element {Map.from_struct(@modal.element)} />
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
        <%= Map.get(@modal.element.options, :title) %>
      </Text.title2>
    """
  end

  attr(:modal, :map, required: true)

  def title3(assigns) do
    ~H"""
      <Text.title3>
        <%= Map.get(@modal.element.options, :title) %>
      </Text.title3>
    """
  end

  defp close_icon_label_button(%LiveNest.Modal{element: %{id: element_id}}) do
    %{
      action: %{type: :send, event: "close_modal", item: element_id},
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
      action: %{type: :send, event: "close_modal", item: element_id},
      face: %{type: :icon, icon: :close}
    }
  end
end
