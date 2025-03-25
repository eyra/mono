defmodule CoreWeb.UI.Popup do
  use CoreWeb, :ui

  slot(:inner_block)

  def popup(assigns) do
    ~H"""
    <div class={"fixed z-20 left-0 top-0 w-full h-full backdrop-blur-md bg-black/30 #{if @inner_block == [] do "hidden" else "block" end}"}>
      <div class="flex flex-row items-center justify-center w-full h-full">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr(:popup, :map, required: true)

  def popup_block(assigns) do
    ~H"""
      <%= if @popup do %>
        <.popup>
          <div class="mx-6 sm:mx-10 w-full max-w-popup sm:max-w-popup-sm md:max-w-popup-md lg:max-w-popup-lg p-8 bg-white shadow-floating rounded">
            <.live_component module={@popup.module} {@popup.props} />
          </div>
        </.popup>
      <% end %>
    """
  end

  defmacro __using__(_) do
    quote do
      @impl true
      def handle_event("show_popup", %{ref: %{id: id, module: module}, params: params}, socket) do
        popup = %{module: module, props: Map.put(params, :id, id)}
        handle_event("show_popup", popup, socket)
      end

      @impl true
      def handle_event("show_popup", %{module: _, props: _} = popup, socket) do
        {:noreply, socket |> assign(popup: popup)}
      end

      @impl true
      def handle_event("hide_popup", _, socket) do
        {:noreply, socket |> assign(popup: nil)}
      end

      @impl true
      def handle_info({:show_popup, popup}, socket) do
        {:noreply, socket |> assign(popup: popup)}
      end

      @impl true
      def handle_info({:hide_popup}, socket) do
        {:noreply, socket |> assign(popup: nil)}
      end
    end
  end
end
