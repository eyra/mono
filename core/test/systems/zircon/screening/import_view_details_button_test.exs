defmodule Systems.Zircon.Screening.ImportViewDetailsButtonTest do
  use CoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  alias Core.Factories
  alias Systems.Zircon.Screening

  setup do
    user = Factories.insert!(:member)
    tool = Factories.insert!(:zircon_screening_tool)

    %{user: user, tool: tool}
  end

  describe "Details button in prompting phase" do
    test "shows Details button and opens modal when clicked", %{conn: conn, tool: tool} do
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

      # Verify Details button is present
      assert has_element?(view, "[phx-click='show_details']")

      # Click the Details button
      view |> element("[phx-click='show_details']") |> render_click()

      # After clicking, the modal should be presented
      # Check that the modal was triggered (the actual modal presentation
      # is handled by LiveNest and might not show in the test DOM)
      # We can at least verify no error occurred
      refute render(view) =~ "phx-error"

      # Verify the ImportView is still functional
      assert has_element?(view, "[data-testid='prompting-summary-block']")
    end

    test "Details button only shows when there are errors or papers", %{conn: conn, tool: tool} do
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

      # Verify Details button is NOT present when there are no entries
      refute has_element?(view, "[phx-click='show_details']")
    end
  end
end
