defmodule Frameworks.GreenLight.LiveHookTest do
  use CoreWeb.ConnCase, async: false

  alias Frameworks.GreenLight.LiveHook

  defmodule TestLiveView do
    @behaviour Frameworks.GreenLight.LiveFeature

    def get_authorization_context(_params, _session, _socket) do
      raise Ecto.NoResultsError, queryable: "test"
    end
  end

  describe "mount/4" do
    test "redirects to access_denied when authorization context raises NoResultsError" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{current_user: %{id: 1}},
        private: %{connect_params: %{}, connect_info: %{}}
      }

      result = LiveHook.mount(TestLiveView, %{"id" => "999"}, %{}, socket)

      assert {:halt, redirected_socket} = result
      assert {:redirect, %{to: "/access_denied"}} = redirected_socket.redirected
    end
  end
end
