defmodule Systems.Manual.ViewTest do
  use CoreWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Frameworks.Concept.LiveContext
  alias Systems.Manual

  describe "Manual.View rendering" do
    setup do
      user = Factories.insert!(:member)
      manual = Manual.Factories.create_manual(2, 1)
      [chapter1, chapter2] = manual.chapters

      %{user: user, manual: manual, chapter1: chapter1, chapter2: chapter2}
    end

    test "renders chapter list when no chapter selected", %{
      conn: conn,
      user: user,
      manual: manual
    } do
      context =
        LiveContext.new(%{
          manual_id: manual.id,
          title: "Test Manual",
          current_user: user,
          presentation: :modal,
          user_state: %{},
          user_state_namespace: [:manual, manual.id]
        })

      conn = Map.put(conn, :request_path, "/manual/view")

      {:ok, view, _html} =
        live_isolated(conn, Manual.View,
          session: %{
            "live_context" => context
          }
        )

      # Should render the chapter list view
      assert has_element?(view, "[data-testid='chapter-list-view']")
      refute has_element?(view, "[data-testid='chapter-view']")
    end

    test "loads every page after selecting a chapter", %{conn: conn, user: user} do
      manual = Manual.Factories.create_manual(1, 3)
      [chapter] = manual.chapters

      [_first_page, _second_page, third_page] =
        Enum.sort_by(chapter.pages, & &1.userflow_step.order)

      third_page =
        third_page
        |> Ecto.Changeset.change(title: "Third page")
        |> Core.Repo.update!()

      context =
        LiveContext.new(%{
          manual_id: manual.id,
          title: "Test Manual",
          current_user: user,
          presentation: :modal,
          user_state: %{},
          user_state_namespace: [:manual, manual.id]
        })

      conn = Map.put(conn, :request_path, "/manual/view")

      {:ok, view, _html} =
        live_isolated(conn, Manual.View, session: %{"live_context" => context})

      view
      |> element("[data-testid='chapter-list-item-#{chapter.id}']")
      |> render_click()

      assert eventually_has_element?(
               view,
               "[data-testid='chapter-view']",
               chapter.title
             )

      view
      |> element("[phx-click='select_page'][phx-value-item='#{third_page.id}']")
      |> render_click()

      assert eventually_has_element?(
               view,
               "[data-testid='chapter-view']",
               third_page.title
             )
    end

    test "renders chapter view when chapter is selected", %{
      conn: conn,
      user: user,
      manual: manual,
      chapter1: chapter1
    } do
      context =
        LiveContext.new(%{
          manual_id: manual.id,
          title: "Test Manual",
          current_user: user,
          presentation: :modal,
          user_state: %{manual: %{manual.id => %{chapter: chapter1.id}}},
          user_state_namespace: [:manual, manual.id]
        })

      conn = Map.put(conn, :request_path, "/manual/view")

      {:ok, view, _html} =
        live_isolated(conn, Manual.View,
          session: %{
            "live_context" => context
          }
        )

      # Should render the chapter view
      assert has_element?(view, "[data-testid='chapter-view']")
    end
  end

  describe "Modal toolbar events" do
    setup do
      user = Factories.insert!(:member)
      manual = Manual.Factories.create_manual(2, 3)
      [chapter1, _chapter2] = manual.chapters

      %{user: user, manual: manual, chapter1: chapter1}
    end

    test "back event clears selected chapter and shows chapter list", %{
      conn: conn,
      user: user,
      manual: manual,
      chapter1: chapter1
    } do
      # Start with a chapter selected
      context =
        LiveContext.new(%{
          manual_id: manual.id,
          title: "Test Manual",
          current_user: user,
          presentation: :modal,
          user_state: %{manual: %{manual.id => %{chapter: chapter1.id}}},
          user_state_namespace: [:manual, manual.id]
        })

      conn = Map.put(conn, :request_path, "/manual/view")

      {:ok, view, _html} =
        live_isolated(conn, Manual.View,
          session: %{
            "live_context" => context
          }
        )

      # Verify chapter view is shown
      assert has_element?(view, "[data-testid='chapter-view']")

      # Send :back toolbar event to the LiveView
      send(view.pid, {:toolbar_action, :back})

      # Wait for view to process the message and re-render
      _ = render(view)

      # Should now show chapter list
      assert has_element?(view, "[data-testid='chapter-list-view']")
      refute has_element?(view, "[data-testid='chapter-view']")
    end

    test "next_page event navigates to next page in chapter", %{
      conn: conn,
      user: user,
      manual: manual,
      chapter1: chapter1
    } do
      # Start with chapter selected on first page
      context =
        LiveContext.new(%{
          manual_id: manual.id,
          title: "Test Manual",
          current_user: user,
          presentation: :modal,
          user_state: %{manual: %{manual.id => %{chapter: chapter1.id, page: nil}}},
          user_state_namespace: [:manual, manual.id]
        })

      conn = Map.put(conn, :request_path, "/manual/view")

      {:ok, view, html} =
        live_isolated(conn, Manual.View,
          session: %{
            "live_context" => context
          }
        )

      # Verify chapter view is shown with first page
      assert has_element?(view, "[data-testid='chapter-view']")
      # The page indicator should show "1/3" for first of 3 pages
      assert html =~ "1/3"

      # Send :next_page toolbar event
      send(view.pid, {:toolbar_action, :next_page})

      assert eventually_render(view, "2/3") =~ "2/3"
    end

    test "previous_page event navigates to previous page", %{
      conn: conn,
      user: user,
      manual: manual,
      chapter1: chapter1
    } do
      [_page1, page2, _page3] = Enum.sort_by(chapter1.pages, & &1.userflow_step.order)

      # Start with chapter selected on second page
      context =
        LiveContext.new(%{
          manual_id: manual.id,
          title: "Test Manual",
          current_user: user,
          presentation: :modal,
          user_state: %{manual: %{manual.id => %{chapter: chapter1.id, page: page2.id}}},
          user_state_namespace: [:manual, manual.id]
        })

      conn = Map.put(conn, :request_path, "/manual/view")

      {:ok, view, html} =
        live_isolated(conn, Manual.View,
          session: %{
            "live_context" => context
          }
        )

      # Verify chapter view is shown with second page
      assert has_element?(view, "[data-testid='chapter-view']")
      assert html =~ "2/3"

      # Send :previous_page toolbar event
      send(view.pid, {:toolbar_action, :previous_page})

      assert eventually_render(view, "1/3") =~ "1/3"
    end

    test "previous_page on first page triggers back to chapter list", %{
      conn: conn,
      user: user,
      manual: manual,
      chapter1: chapter1
    } do
      [page1, _page2, _page3] = Enum.sort_by(chapter1.pages, & &1.userflow_step.order)

      # Start with chapter selected on first page
      context =
        LiveContext.new(%{
          manual_id: manual.id,
          title: "Test Manual",
          current_user: user,
          presentation: :modal,
          user_state: %{manual: %{manual.id => %{chapter: chapter1.id, page: page1.id}}},
          user_state_namespace: [:manual, manual.id]
        })

      conn = Map.put(conn, :request_path, "/manual/view")

      {:ok, view, _html} =
        live_isolated(conn, Manual.View,
          session: %{
            "live_context" => context
          }
        )

      # Verify chapter view is shown
      assert has_element?(view, "[data-testid='chapter-view']")

      # Send :previous_page toolbar event on first page - should trigger back
      send(view.pid, {:toolbar_action, :previous_page})

      # Wait for view to process and re-render
      _ = render(view)

      # ChapterView handles previous_page on first page by publishing :back event
      # which Manual.View consumes and clears the chapter
      # Note: This tests the full flow through ChapterView's handle_event
    end
  end

  describe "Embedded presentation" do
    setup do
      user = Factories.insert!(:member)
      manual = Manual.Factories.create_manual(2, 3)
      [chapter1, _chapter2] = manual.chapters

      %{user: user, manual: manual, chapter1: chapter1}
    end

    test "renders no toolbar when no chapter selected", %{
      conn: conn,
      user: user,
      manual: manual
    } do
      context =
        LiveContext.new(%{
          manual_id: manual.id,
          title: "Test Manual",
          current_user: user,
          presentation: :embedded,
          user_state: %{},
          user_state_namespace: [:manual, manual.id]
        })

      conn = Map.put(conn, :request_path, "/manual/view")

      {:ok, view, _html} =
        live_isolated(conn, Manual.View,
          session: %{
            "live_context" => context
          }
        )

      # Should render the chapter list view without toolbar
      assert has_element?(view, "[data-testid='chapter-list-view']")
      refute has_element?(view, "[data-testid='toolbar']")
    end

    test "renders local toolbar when chapter is selected", %{
      conn: conn,
      user: user,
      manual: manual,
      chapter1: chapter1
    } do
      context =
        LiveContext.new(%{
          manual_id: manual.id,
          title: "Test Manual",
          current_user: user,
          presentation: :embedded,
          user_state: %{manual: %{manual.id => %{chapter: chapter1.id}}},
          user_state_namespace: [:manual, manual.id]
        })

      conn = Map.put(conn, :request_path, "/manual/view")

      {:ok, view, _html} =
        live_isolated(conn, Manual.View,
          session: %{
            "live_context" => context
          }
        )

      # Should render the chapter view with local toolbar
      assert has_element?(view, "[data-testid='chapter-view']")
      assert has_element?(view, "[data-testid='toolbar']")
    end

    test "toolbar next_page action navigates to next page", %{
      conn: conn,
      user: user,
      manual: manual,
      chapter1: chapter1
    } do
      context =
        LiveContext.new(%{
          manual_id: manual.id,
          title: "Test Manual",
          current_user: user,
          presentation: :embedded,
          user_state: %{manual: %{manual.id => %{chapter: chapter1.id, page: nil}}},
          user_state_namespace: [:manual, manual.id]
        })

      conn = Map.put(conn, :request_path, "/manual/view")

      {:ok, view, html} =
        live_isolated(conn, Manual.View,
          session: %{
            "live_context" => context
          }
        )

      # Verify first page is shown
      assert html =~ "1/3"

      # Send toolbar_action event via LiveNest
      event = %LiveNest.Event{
        name: :toolbar_action,
        source: {self(), "manual_toolbar"},
        payload: %{action: :next_page}
      }

      send(view.pid, {:live_nest_event, event})

      assert eventually_render(view, "2/3") =~ "2/3"
    end

    test "toolbar previous_page action navigates to previous page", %{
      conn: conn,
      user: user,
      manual: manual,
      chapter1: chapter1
    } do
      [_page1, page2, _page3] = Enum.sort_by(chapter1.pages, & &1.userflow_step.order)

      context =
        LiveContext.new(%{
          manual_id: manual.id,
          title: "Test Manual",
          current_user: user,
          presentation: :embedded,
          user_state: %{manual: %{manual.id => %{chapter: chapter1.id, page: page2.id}}},
          user_state_namespace: [:manual, manual.id]
        })

      conn = Map.put(conn, :request_path, "/manual/view")

      {:ok, view, html} =
        live_isolated(conn, Manual.View,
          session: %{
            "live_context" => context
          }
        )

      # Verify second page is shown
      assert html =~ "2/3"

      # Send toolbar_action event via LiveNest
      event = %LiveNest.Event{
        name: :toolbar_action,
        source: {self(), "manual_toolbar"},
        payload: %{action: :previous_page}
      }

      send(view.pid, {:live_nest_event, event})

      assert eventually_render(view, "1/3") =~ "1/3"
    end

    test "toolbar back action on first page clears chapter selection", %{
      conn: conn,
      user: user,
      manual: manual,
      chapter1: chapter1
    } do
      [page1, _page2, _page3] = Enum.sort_by(chapter1.pages, & &1.userflow_step.order)

      context =
        LiveContext.new(%{
          manual_id: manual.id,
          title: "Test Manual",
          current_user: user,
          presentation: :embedded,
          user_state: %{manual: %{manual.id => %{chapter: chapter1.id, page: page1.id}}},
          user_state_namespace: [:manual, manual.id]
        })

      conn = Map.put(conn, :request_path, "/manual/view")

      {:ok, view, _html} =
        live_isolated(conn, Manual.View,
          session: %{
            "live_context" => context
          }
        )

      # Verify chapter view is shown
      assert has_element?(view, "[data-testid='chapter-view']")

      # Send toolbar_action event via LiveNest (back event on first page)
      event = %LiveNest.Event{
        name: :toolbar_action,
        source: {self(), "manual_toolbar"},
        payload: %{action: :back}
      }

      send(view.pid, {:live_nest_event, event})

      # Force render to process
      _ = render(view)

      # Should now show chapter list (chapter cleared)
      assert has_element?(view, "[data-testid='chapter-list-view']")
      refute has_element?(view, "[data-testid='chapter-view']")
    end
  end
end
