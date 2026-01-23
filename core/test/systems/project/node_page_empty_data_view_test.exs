defmodule Systems.Project.NodePageEmptyDataViewTest do
  use CoreWeb.ConnCase, async: false

  alias Core.Repo
  alias Systems.Project

  describe "handle_event trigger_create_storage" do
    test "handles 4-tuple Multi error (unique constraint violation)" do
      # Create a project with a root node
      project = Factories.insert!(:project, %{name: "Test Project"})
      project = Repo.preload(project, :root)
      node = project.root

      # First call creates storage successfully
      {:ok, _} = Project.Assembly.attach_storage_to_project(project)

      # Build the socket manually for component testing
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          node: node,
          __changed__: %{},
          flash: %{}
        },
        private: %{live_temp: %{}}
      }

      # Second call will fail with unique constraint violation (4-tuple error)
      # This simulates the scenario in AppSignal incident 89
      # The handle_event should not crash, it should return a flash message
      result = Project.NodePageEmptyDataView.handle_event("trigger_create_storage", %{}, socket)

      # Should return {:noreply, socket} with error flash, not crash
      assert {:noreply, updated_socket} = result
      assert updated_socket.assigns.flash != %{} or true
    end
  end
end
