defmodule Systems.Zircon.Screening.ImportViewSummaryButtonsTest do
  use CoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  alias Core.Factories
  alias Systems.Zircon.Screening

  setup do
    user = Factories.insert!(:member)
    tool = Factories.insert!(:zircon_screening_tool)

    %{user: user, tool: tool}
  end

  describe "Summary buttons in prompting phase" do
    test "shows warning, new papers, and existing papers buttons", %{conn: conn, tool: tool} do
      # Create the necessary setup
      paper_set = Systems.Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool.id)

      reference_file =
        Systems.Zircon.Public.insert_reference_file!(
          tool,
          "test.ris",
          "http://example.com/test.ris"
        )

      # Create an import session in prompting phase with both errors and new papers
      _import_session =
        Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: [
            %{
              "title" => "New Paper 1",
              "authors" => ["Author A"],
              "year" => "2024",
              "doi" => "10.1234/test1",
              "status" => "new"
            },
            %{
              "title" => "Error Paper",
              "status" => "error",
              "error" => %{
                "line" => 15,
                "error" => "Invalid field format"
              }
            },
            %{
              "title" => "Existing Paper",
              "authors" => ["Author B"],
              "year" => "2023",
              "doi" => "10.1234/existing",
              "status" => "duplicate"
            }
          ],
          errors: []
        })

      conn = conn |> Map.put(:request_path, "/zircon/screening/import")

      session_data = %{
        "title" => "Test Import",
        "tool" => tool
      }

      {:ok, view, html} = live_isolated(conn, Screening.ImportView, session: session_data)

      # Verify the prompting summary is shown
      assert html =~ "data-testid=\"prompting-summary-block\""

      # Verify the "Found in this file:" text is present
      assert html =~ "Found in this file:"

      # Verify all three buttons are present
      assert has_element?(view, "[phx-click='show_warnings']")
      assert has_element?(view, "[phx-click='show_new_papers']")
      assert has_element?(view, "[phx-click='show_duplicates']")

      # Verify button labels with counts
      assert html =~ "1 warning"
      assert html =~ "1 new paper"
      assert html =~ "1 duplicate"

      # Test clicking each button
      view |> render_click(:show_warnings)
      refute render(view) =~ "phx-error"
      view |> render_click(:show_new_papers)
      refute render(view) =~ "phx-error"
      view |> render_click(:show_duplicates)
      refute render(view) =~ "phx-error"
    end

    test "buttons only show when there are items to display", %{conn: conn, tool: tool} do
      # Create the necessary setup
      paper_set = Systems.Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool.id)

      reference_file =
        Systems.Zircon.Public.insert_reference_file!(
          tool,
          "empty.ris",
          "http://example.com/empty.ris"
        )

      # Create an import session with no entries
      _import_session =
        Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: [],
          errors: []
        })

      conn = conn |> Map.put(:request_path, "/zircon/screening/import")

      session_data = %{
        "title" => "Test Import",
        "tool" => tool
      }

      {:ok, view, html} = live_isolated(conn, Screening.ImportView, session: session_data)

      # Verify the prompting summary is shown
      assert html =~ "data-testid=\"prompting-summary-block\""

      # Verify no buttons are present when there are no entries
      refute has_element?(view, "[phx-click='show_warnings']")
      refute has_element?(view, "[phx-click='show_new_papers']")
      refute has_element?(view, "[phx-click='show_duplicates']")
    end
  end
end
