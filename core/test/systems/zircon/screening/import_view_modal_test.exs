defmodule Systems.Zircon.Screening.ImportViewModalTest do
  use CoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  alias Core.Factories
  alias Systems.Zircon.Screening

  setup do
    user = Factories.insert!(:member)
    tool = Factories.insert!(:zircon_screening_tool)

    %{user: user, tool: tool}
  end

  describe "Modal functionality for warnings, new papers, and existing papers" do
    test "clicking warning button opens modal with warnings view", %{conn: conn, tool: tool} do
      # Create the necessary setup
      paper_set = Systems.Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool.id)

      reference_file =
        Systems.Zircon.Public.insert_reference_file!(
          tool,
          "test.ris",
          "http://example.com/test.ris"
        )

      # Create an import session with warnings
      _import_session =
        Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: [
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

      {:ok, view, _html} = live_isolated(conn, Screening.ImportView, session: session_data)

      # Click the warnings button
      view |> element("[phx-click='show_warnings']") |> render_click()

      # Modal should be triggered without errors
      refute render(view) =~ "phx-error"
    end

    test "clicking new papers button opens modal with new papers view", %{conn: conn, tool: tool} do
      # Create the necessary setup
      paper_set = Systems.Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool.id)

      reference_file =
        Systems.Zircon.Public.insert_reference_file!(
          tool,
          "test.ris",
          "http://example.com/test.ris"
        )

      # Create an import session with new papers
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
            }
          ],
          errors: []
        })

      conn = conn |> Map.put(:request_path, "/zircon/screening/import")

      session_data = %{
        "title" => "Test Import",
        "tool" => tool
      }

      {:ok, view, _html} = live_isolated(conn, Screening.ImportView, session: session_data)

      # Click the new papers button
      view |> element("[phx-click='show_new_papers']") |> render_click()

      # Modal should be triggered without errors
      refute render(view) =~ "phx-error"
    end

    test "clicking duplicates button opens modal with duplicates view", %{
      conn: conn,
      tool: tool
    } do
      # Create the necessary setup
      paper_set = Systems.Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool.id)

      reference_file =
        Systems.Zircon.Public.insert_reference_file!(
          tool,
          "test.ris",
          "http://example.com/test.ris"
        )

      # Create an import session with existing papers
      _import_session =
        Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: [
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

      {:ok, view, _html} = live_isolated(conn, Screening.ImportView, session: session_data)

      # Click the duplicates button
      view |> element("[phx-click='show_duplicates']") |> render_click()

      # Modal should be triggered without errors
      refute render(view) =~ "phx-error"
    end

    test "all three modals (warnings, new papers, duplicates) can be triggered from the same view",
         %{conn: conn, tool: tool} do
      # Create the necessary setup
      paper_set = Systems.Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool.id)

      reference_file =
        Systems.Zircon.Public.insert_reference_file!(
          tool,
          "test.ris",
          "http://example.com/test.ris"
        )

      # Create an import session with all types of entries
      _import_session =
        Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: [
            %{
              "title" => "Error Paper",
              "status" => "error",
              "error" => %{
                "line" => 15,
                "error" => "Invalid field format"
              }
            },
            %{
              "title" => "New Paper",
              "status" => "new"
            },
            %{
              "title" => "Duplicate Paper",
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

      # Verify all three buttons are present
      assert has_element?(view, "[phx-click='show_warnings']")
      assert has_element?(view, "[phx-click='show_new_papers']")
      assert has_element?(view, "[phx-click='show_duplicates']")

      # Verify button labels show counts
      assert html =~ "1 warning"
      assert html =~ "1 new paper"
      assert html =~ "1 duplicate"

      # Test that each button can be clicked without errors
      view |> element("[phx-click='show_warnings']") |> render_click()
      refute render(view) =~ "phx-error"

      view |> element("[phx-click='show_new_papers']") |> render_click()
      refute render(view) =~ "phx-error"

      view |> element("[phx-click='show_duplicates']") |> render_click()
      refute render(view) =~ "phx-error"
    end
  end
end
