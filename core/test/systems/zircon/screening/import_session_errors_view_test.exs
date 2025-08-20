defmodule Systems.Zircon.Screening.ImportSessionErrorsViewTest do
  use CoreWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Core.Factories
  alias Core.Repo
  alias Systems.Paper
  alias Systems.Zircon.Screening.ImportSessionErrorsView

  describe "search interaction" do
    test "searching filters the errors in real-time", %{conn: conn} do
      conn = conn |> Map.put(:request_path, "/test")

      # Create actual database records
      tool = Factories.insert!(:zircon_screening_tool)
      paper_set = Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool.id)

      reference_file =
        Systems.Zircon.Public.insert_reference_file!(
          tool,
          "test.ris",
          "http://example.com/test.ris"
        )

      # Create import session with error entries (need > 10 for search bar to show)
      entries = [
        %{
          "status" => "error",
          "error" => %{
            "line" => 1,
            "error" => "Missing required field: TY",
            "content" => "AB  - Abstract text"
          }
        },
        %{
          "status" => "error",
          "error" => %{
            "line" => 5,
            "error" => "Invalid date format",
            "content" => "DA  - 2024-13-45"
          }
        },
        %{
          "status" => "error",
          "error" => %{
            "line" => 10,
            "error" => "Missing required field: AU",
            "content" => "TI  - Title text"
          }
        },
        %{
          "status" => "error",
          "error" => %{
            "line" => 15,
            "error" => "Duplicate reference",
            "content" => "ID  - REF001"
          }
        },
        %{
          "status" => "error",
          "error" => %{"line" => 20, "error" => "Error 5", "content" => "Content 5"}
        },
        %{
          "status" => "error",
          "error" => %{"line" => 25, "error" => "Error 6", "content" => "Content 6"}
        },
        %{
          "status" => "error",
          "error" => %{"line" => 30, "error" => "Error 7", "content" => "Content 7"}
        },
        %{
          "status" => "error",
          "error" => %{"line" => 35, "error" => "Error 8", "content" => "Content 8"}
        },
        %{
          "status" => "error",
          "error" => %{"line" => 40, "error" => "Error 9", "content" => "Content 9"}
        },
        %{
          "status" => "error",
          "error" => %{"line" => 45, "error" => "Error 10", "content" => "Content 10"}
        },
        %{
          "status" => "error",
          "error" => %{"line" => 50, "error" => "Error 11", "content" => "Content 11"}
        }
      ]

      import_session =
        Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: entries
        })

      # Preload associations
      import_session = import_session |> Repo.preload(reference_file: :file)

      {:ok, view, html} =
        live_isolated(conn, ImportSessionErrorsView,
          session: %{
            "session" => import_session
          }
        )

      # Initially first 10 errors should be visible
      assert html =~ "data-testid=\"ris-entry-error-table-row-0\""
      assert html =~ "data-testid=\"ris-entry-error-table-row-1\""
      assert html =~ "data-testid=\"ris-entry-error-table-row-9\""
      refute html =~ "data-testid=\"ris-entry-error-table-row-10\""

      # Type "missing" in the search box
      view |> form("#search_bar_form", query: "missing") |> render_change()
      html = render(view)

      # Should only show the two "Missing" errors (they get new row indices 0 and 1)
      assert html =~ "data-testid=\"ris-entry-error-table-row-0\""
      assert html =~ "data-testid=\"ris-entry-error-table-row-1\""
      # No third row
      refute html =~ "data-testid=\"ris-entry-error-table-row-2\""
      # No fourth row
      refute html =~ "data-testid=\"ris-entry-error-table-row-3\""

      # Clear the search
      view |> form("#search_bar_form", query: "") |> render_change()
      html = render(view)

      # Should show first 10 errors again
      assert html =~ "data-testid=\"ris-entry-error-table-row-0\""
      assert html =~ "data-testid=\"ris-entry-error-table-row-1\""
      assert html =~ "data-testid=\"ris-entry-error-table-row-9\""
      refute html =~ "data-testid=\"ris-entry-error-table-row-10\""

      # Test searching in content field
      view |> form("#search_bar_form", query: "abstract") |> render_change()
      html = render(view)

      # Should only show the error with "Abstract" in content
      # Has "AB  - Abstract text"
      assert html =~ "data-testid=\"ris-entry-error-table-row-0\""
      refute html =~ "data-testid=\"ris-entry-error-table-row-1\""
      refute html =~ "data-testid=\"ris-entry-error-table-row-2\""
      refute html =~ "data-testid=\"ris-entry-error-table-row-3\""
    end
  end

  describe "rendering" do
    test "renders initial errors with search bar when > 10 errors", %{conn: conn} do
      # Set request_path to avoid iodata error
      conn = conn |> Map.put(:request_path, "/test")

      # Create actual database records
      tool = Factories.insert!(:zircon_screening_tool)
      paper_set = Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool.id)

      reference_file =
        Systems.Zircon.Public.insert_reference_file!(
          tool,
          "test.ris",
          "http://example.com/test.ris"
        )

      # Create more than 10 errors to ensure search bar shows
      entries =
        for i <- 1..12 do
          %{
            "status" => "error",
            "error" => %{"line" => i, "error" => "Error #{i}", "content" => "Content #{i}"}
          }
        end

      import_session =
        Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: entries
        })

      # Preload associations
      import_session = import_session |> Repo.preload(reference_file: :file)

      {:ok, _view, html} =
        live_isolated(conn, ImportSessionErrorsView,
          session: %{
            "session" => import_session
          }
        )

      # Verify structure and data-testid attributes
      assert html =~ "data-testid=\"errors-block\""
      assert html =~ "data-testid=\"errors-list\""
      assert html =~ "data-testid=\"ris-entry-error-table\""

      # Verify we have 10 error rows displayed (pagination)
      assert html =~ "data-testid=\"ris-entry-error-table-row-0\""
      assert html =~ "data-testid=\"ris-entry-error-table-row-9\""
      refute html =~ "data-testid=\"ris-entry-error-table-row-10\""

      # Verify search bar is present (search form is rendered)
      assert html =~ "search_bar_form"
      assert html =~ "phx-change=\"change\""
    end

    test "renders without search bar when show_action_bar? is false", %{conn: conn} do
      conn = conn |> Map.put(:request_path, "/test")

      # Create actual database records with only 1 error (so action bar won't show)
      tool = Factories.insert!(:zircon_screening_tool)
      paper_set = Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool.id)

      reference_file =
        Systems.Zircon.Public.insert_reference_file!(
          tool,
          "test.ris",
          "http://example.com/test.ris"
        )

      import_session =
        Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: [
            %{
              "status" => "error",
              "error" => %{"line" => 1, "error" => "Test error", "content" => "Test content"}
            }
          ]
        })

      # Preload associations
      import_session = import_session |> Repo.preload(reference_file: :file)

      {:ok, _view, html} =
        live_isolated(conn, ImportSessionErrorsView,
          session: %{
            "session" => import_session
          }
        )

      # Verify structure
      assert html =~ "data-testid=\"errors-block\""
      assert html =~ "data-testid=\"errors-list\""
      assert html =~ "data-testid=\"ris-entry-error-table\""

      # Verify we have 1 error row
      assert html =~ "data-testid=\"ris-entry-error-table-row-0\""

      # Search bar should not be present
      refute html =~ "search_bar_form"
    end
  end

  describe "pagination with search" do
    test "search resets pagination to first page", %{conn: conn} do
      conn = conn |> Map.put(:request_path, "/test")

      # Create actual database records
      tool = Factories.insert!(:zircon_screening_tool)
      paper_set = Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool.id)

      reference_file =
        Systems.Zircon.Public.insert_reference_file!(
          tool,
          "test.ris",
          "http://example.com/test.ris"
        )

      # Create enough errors to have multiple pages (page size is 10)
      entries =
        for i <- 1..25 do
          %{
            "status" => "error",
            "error" => %{
              "line" => i,
              "error" => "Error #{i}",
              "content" => "Content #{i}"
            }
          }
        end

      import_session =
        Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: entries
        })

      # Preload associations
      import_session = import_session |> Repo.preload(reference_file: :file)

      {:ok, view, html} =
        live_isolated(conn, ImportSessionErrorsView,
          session: %{
            "session" => import_session
          }
        )

      # Should show first 10 errors - verify table is rendered
      assert html =~ "data-testid=\"ris-entry-error-table\""
      # Count table rows to verify pagination (header + 10 data rows)
      assert length(Regex.scan(~r/<tr/, html)) == 11

      # Click to go to page 2 (use a more specific selector for the page button)
      view |> element("[phx-click='select_page'][phx-value-item='1']", "2") |> render_click()
      html = render(view)

      # Should now show errors 11-20 - still 10 rows
      # header + 10 data rows
      assert length(Regex.scan(~r/<tr/, html)) == 11

      # Test search interaction
      # The search bar is component 2, we can trigger its change event
      view |> form("#search_bar_form", query: "Error 1") |> render_change()
      html = render(view)

      # After searching for "Error 1", should show matching results (1, 10-19)
      # Error 1
      assert html =~ "data-testid=\"ris-entry-error-table-row-0\""
      # Error 10 (matches "Error 1")
      assert html =~ "data-testid=\"ris-entry-error-table-row-9\""
    end
  end
end
