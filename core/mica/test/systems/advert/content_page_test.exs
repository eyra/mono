defmodule Systems.Advert.ContentPageTest do
  use MicaWeb.ConnCase, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Phoenix.Component, only: [assign: 2]

  import ExUnit.Assertions
  import Mock

  alias Systems.Advert

  describe "show content page for advert with monitor tab" do
    setup [:login_as_creator]

    test "Default", %{conn: %{assigns: %{current_user: researcher}} = conn} do
      branch =
        Promox.new()
        |> Promox.stub(Frameworks.Concept.Branch, :hierarchy, fn _ -> [] end)

      with_mock Systems.Project.LiveHook,
        on_mount: fn _live_view_module, _params, _session, socket ->
          {:cont, socket |> assign(branch: branch)}
        end do
        %{id: id} = Advert.Factories.create_advert(researcher, :accepted, 1)

        {:ok, _view, html} = live(conn, ~p"/advert/#{id}/content")

        assert html =~
                 "tab_panel_settings\" data-tab-id=\"settings\" class=\"tab-panel hidden"

        assert html =~ "Settings"

        assert html =~
                 "tab_panel_pool\" data-tab-id=\"pool\" class=\"tab-panel hidden\">"

        assert html =~ "Criteria"

        assert html =~
                 "tab_panel_monitor\" data-tab-id=\"monitor\" class=\"tab-panel hidden\">"

        assert html =~ "Monitor"
      end
    end
  end

  describe "pool visibility banner on the settings tab" do
    setup [:login_as_creator]

    setup do
      branch =
        Promox.new()
        |> Promox.stub(Frameworks.Concept.Branch, :hierarchy, fn _ -> [] end)

      {:ok, branch: branch}
    end

    defp online_advert(researcher, assignment_status) do
      currency = Systems.Fund.Factories.create_currency("banner_currency", :legal, "ƒ", 2)
      fund = Systems.Fund.Factories.create_fund("banner_fund", currency)
      advert = Advert.Factories.create_advert(researcher, :accepted, 1, fund)
      advert.assignment |> Ecto.Changeset.change(status: assignment_status) |> Mica.Repo.update!()
      advert |> Ecto.Changeset.change(status: :online) |> Mica.Repo.update!()
    end

    defp render_content_page(conn, branch, advert) do
      with_mock Systems.Project.LiveHook,
        on_mount: fn _live_view_module, _params, _session, socket ->
          {:cont, socket |> assign(branch: branch)}
        end do
        {:ok, _view, html} = live(conn, ~p"/advert/#{advert.id}/content")
        html
      end
    end

    test "shows the publish-your-study banner when the assignment is not published", %{
      conn: %{assigns: %{current_user: researcher}} = conn,
      branch: branch
    } do
      advert = online_advert(researcher, :concept)
      html = render_content_page(conn, branch, advert)

      assert html =~ "data-testid=\"advert-assignment-unpublished-banner\""
      assert html =~ "data-testid=\"advert-publish-assignment-button\""
      assert html =~ "/assignment/#{advert.assignment_id}/content\""
      refute html =~ "This advert is visible in the pool."
    end

    test "shows the visible banner once the assignment is published", %{
      conn: %{assigns: %{current_user: researcher}} = conn,
      branch: branch
    } do
      html = render_content_page(conn, branch, online_advert(researcher, :online))

      assert html =~ "This advert is visible in the pool."
      refute html =~ "advert-assignment-unpublished-banner"
      refute html =~ "advert-publish-assignment-button"
    end

    test "keeps the visible banner when the assignment is idle", %{
      conn: %{assigns: %{current_user: researcher}} = conn,
      branch: branch
    } do
      html = render_content_page(conn, branch, online_advert(researcher, :idle))

      assert html =~ "This advert is visible in the pool."
      refute html =~ "advert-assignment-unpublished-banner"
      refute html =~ "advert-publish-assignment-button"
    end
  end
end
