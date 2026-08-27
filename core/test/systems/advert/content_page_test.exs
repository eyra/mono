defmodule Systems.Advert.ContentPageTest do
  use CoreWeb.ConnCase, async: false

  import ExUnit.Assertions
  import Mock
  import Phoenix.Component, only: [assign: 2]
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Systems.Advert

  describe "show content page for advert with monitor tab" do
    setup [:login_as_creator]

    test "Default", %{conn: %{assigns: %{current_user: researcher}} = conn} do
      branch =
        Promox.stub(Promox.new(), Frameworks.Concept.Branch, :hierarchy, fn _ -> [] end)

      with_mock Systems.Project.LiveHook,
        on_mount: fn _live_view_module, _params, _session, socket ->
          {:cont, assign(socket, branch: branch)}
        end do
        %{id: id} = Advert.Factories.create_advert(researcher, :accepted, 1)

        {:ok, _view, html} = live(conn, ~p"/advert/#{id}/content")

        assert html =~
                 ~s(tab_panel_settings" data-tab-id="settings" class="tab-panel hidden)

        assert html =~ "Settings"

        assert html =~
                 ~s(tab_panel_pool" data-tab-id="pool" class="tab-panel hidden">)

        assert html =~ "Criteria"

        assert html =~
                 ~s(tab_panel_monitor" data-tab-id="monitor" class="tab-panel hidden">)

        assert html =~ "Monitor"
      end
    end
  end
end
