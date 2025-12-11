defmodule Systems.Test.ModalToolbarTest do
  use CoreWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Frameworks.Pixel.ModalView

  describe "ModalView.update_modal_buttons/3" do
    defp test_socket do
      %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}}}
    end

    test "stores buttons and source for Toolbar LiveComponent" do
      socket = test_socket()
      source = {self(), "chapter_view"}

      buttons = [
        %{
          action: %{type: :send, event: "back"},
          face: %{type: :plain, label: "Back", icon: :back, icon_align: :left}
        },
        %{
          action: %{type: :send, event: "next_page"},
          face: %{type: :plain, label: "Next", icon: :forward, icon_align: :right}
        }
      ]

      updated_socket = ModalView.update_modal_buttons(socket, source, buttons)

      # Buttons are stored as-is for the Toolbar LiveComponent to process
      assert updated_socket.assigns.modal_toolbar_buttons == buttons

      # Source is stored for forwarding events
      assert updated_socket.assigns.modal_button_source == source
    end

    test "handles empty button list" do
      socket = test_socket()
      source = {self(), "chapter_view"}

      updated_socket = ModalView.update_modal_buttons(socket, source, [])

      assert updated_socket.assigns.modal_toolbar_buttons == []
      assert updated_socket.assigns.modal_button_source == source
    end
  end

  describe "ModalView.forward_toolbar_action/2" do
    test "sends toolbar_action to target process" do
      source = {self(), "chapter_view"}

      ModalView.forward_toolbar_action(source, :test_action)

      assert_receive {:toolbar_action, :test_action}
    end
  end

  describe "modal presentation" do
    test "routed view renders modal with toolbar", %{conn: conn} do
      {:ok, view, html} = live(conn, "/test/routed/with_modal")

      # Verify the page loaded
      assert view |> has_element?("[data-testid='routed-live-view']")

      # Modal should be visible with full style
      assert html =~ "modal-full"

      # Toolbar should have close button
      assert html =~ "phx-click=\"close_modal\""

      # Modal embedded view should be rendered
      assert view |> has_element?("[data-testid='modal-embedded-view']")
    end

    test "toolbar buttons update when update_modal_buttons event is sent", %{conn: conn} do
      {:ok, view, html} = live(conn, "/test/routed/with_modal")

      # Initially no custom buttons (just close button)
      refute html =~ "Custom Button"

      # Send update_modal_buttons event with new buttons (plain button maps)
      source = {self(), "test_source"}

      buttons = [
        %{
          action: %{type: :send, event: "custom_event"},
          face: %{type: :plain, label: "Custom Button", icon: :forward}
        }
      ]

      event = %LiveNest.Event{
        name: :update_modal_buttons,
        source: source,
        payload: %{buttons: buttons}
      }

      send(view.pid, {:live_nest_event, event})

      # Re-render to see the updated buttons
      html = render(view)

      # Custom button should now be visible
      assert html =~ "Custom Button"
    end
  end
end
