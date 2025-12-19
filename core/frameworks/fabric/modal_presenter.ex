defmodule Fabric.ModalPresenter do
  defmacro __using__(_opts) do
    quote do
      import Fabric.ModalPresenter

      require Logger

      def handle_event("prepare_modal", %{live_component: %{ref: %{id: id}}} = modal, socket) do
        if fabric_modal = Map.get(socket.assigns, :fabric_modal) do
          if fabric_modal.live_component.ref.id != id do
            Logger.debug(
              "[Warning] Preparing modal #{id} that is not the same as current modal #{fabric_modal.ref.id}"
            )
          end
        end

        # Set visible to false to preload the modal in the background
        live_nest_modal = map_live_nest_modal(modal, false)

        {
          :noreply,
          socket
          |> handle_present_modal(live_nest_modal)
          |> assign(fabric_modal: modal)
        }
      end

      def handle_event("show_modal", %{live_component: %{ref: %{id: id}}} = modal, socket) do
        if fabric_modal = Map.get(socket.assigns, :fabric_modal) do
          if fabric_modal.live_component.ref.id != id do
            Logger.debug(
              "[Warning] Showing modal #{id} that is not the same as current modal #{fabric_modal.ref.id}"
            )
          end
        end

        live_nest_modal = map_live_nest_modal(modal, true)

        {
          :noreply,
          socket
          |> handle_present_modal(live_nest_modal)
          |> assign(fabric_modal: modal)
        }
      end

      def handle_event("hide_modal", %{live_component: %{ref: %{id: id}}} = modal, socket) do
        if fabric_modal = Map.get(socket.assigns, :fabric_modal) do
          if fabric_modal.live_component.ref.id != id do
            Logger.debug(
              "[Warning] Hiding modal #{id} that is not the same as current modal #{fabric_modal.ref.id}"
            )
          end
        end

        live_nest_modal = map_live_nest_modal(fabric_modal, true)

        {
          :noreply,
          socket
          |> handle_hide_modal(live_nest_modal)
          |> assign(fabric_modal: nil)
        }
      end

      def handle_event("close_modal", %{"item" => modal_id}, socket) do
        {
          :noreply,
          socket
          |> handle_close_modal(modal_id)
          |> notify_modal_controller(modal_id)
          |> assign(fabric_modal: nil)
        }
      end

      def notify_modal_controller(
            %{assigns: %{fabric_modal: %{live_component: %{ref: ref}}}} = socket,
            modal_id
          ) do
        Fabric.send_event(ref, %{
          name: :handle_modal_closed,
          payload: %{source: %{name: :modal_presenter}}
        })

        socket
      end

      def map_live_nest_modal(
            %{live_component: %{ref: %{id: id, module: module}, params: params}, style: style} =
              _modal,
            visible
          ) do
        %LiveNest.Modal{
          style: style,
          visible: visible,
          # Set controller_pid to self() so LiveNest can send :modal_closed event
          controller_pid: self(),
          options: [],
          element: %LiveNest.Element{
            id: id,
            type: :live_component,
            implementation: module,
            options: to_keyword_list(params)
          }
        }
      end

      defp to_keyword_list(%{} = params) do
        Enum.into(params, [], fn {k, v} -> {k, v} end)
      end
    end
  end
end
