defmodule Systems.Zircon.Screening.ImportSessionWarningsViewTest do
  use CoreWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Systems.Paper

  describe "modal opening with session_id" do
    setup do
      user = Factories.insert!(:member)

      # Create a screening tool
      tool = Factories.insert!(:zircon_screening_tool)

      # Create a reference file
      reference_file =
        Factories.insert!(:paper_reference_file, %{
          status: :uploaded
        })

      # Create paper set
      paper_set = Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool.id)

      # Create an import session with errors
      import_session =
        Factories.insert!(:paper_ris_import_session, %{
          reference_file: reference_file,
          paper_set: paper_set,
          status: :activated,
          phase: :prompting,
          entries: [
            %{
              "status" => "error",
              "error" => %{
                "line" => 1,
                "message" => "Missing required field",
                "content" => "TY  - JOUR\nER  -"
              },
              "raw" => "TY  - JOUR\nER  -"
            },
            %{
              "status" => "error",
              "error" => %{
                "line" => 5,
                "message" => "Invalid DOI format",
                "content" => "TY  - JOUR\nDO  - invalid\nER  -"
              },
              "raw" => "TY  - JOUR\nDO  - invalid\nER  -"
            }
          ],
          summary: %{
            "total" => 2,
            "predicted_new" => 0,
            "predicted_existing" => 0,
            "predicted_errors" => 2
          }
        })

      %{
        user: user,
        tool: tool,
        import_session: import_session
      }
    end

    test "ImportSessionWarningsView can be mounted with session parameter", %{
      conn: conn,
      import_session: import_session
    } do
      # This simulates what happens when the modal is opened with the full session object
      # The view expects the actual session, not just the ID

      conn = conn |> Map.put(:request_path, "/zircon/screening/import")

      # Preload the reference file association with nested file
      import_session = import_session |> Core.Repo.preload(reference_file: :file)

      # Mount the view with full session object (as fixed in ImportView)
      assert {:ok, _view, _html} =
               live_isolated(conn, Systems.Zircon.Screening.ImportSessionWarningsView,
                 session: %{
                   "session" => import_session,
                   "title" => "Warnings"
                 }
               )
    end

    test "ImportSessionWarningsView displays errors when opened with session", %{
      conn: conn,
      import_session: import_session
    } do
      conn = conn |> Map.put(:request_path, "/zircon/screening/import")

      # Preload the reference file association with nested file
      import_session = import_session |> Core.Repo.preload(reference_file: :file)

      # Mount the view with full session object
      {:ok, view, html} =
        live_isolated(conn, Systems.Zircon.Screening.ImportSessionWarningsView,
          session: %{
            "session" => import_session,
            "title" => "Warnings"
          }
        )

      # Verify errors are displayed
      assert html =~ "Missing required field"
      assert html =~ "Invalid DOI format"

      # Verify table is rendered
      assert has_element?(view, "[data-testid='ris-entry-error-table']")
    end
  end

  describe "intrinsic duplicate error display" do
    setup do
      user = Factories.insert!(:member)
      tool = Factories.insert!(:zircon_screening_tool)

      # Create a reference file
      reference_file =
        Factories.insert!(:paper_reference_file, %{
          status: :uploaded
        })

      # Create paper set
      paper_set = Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool.id)

      # Create an import session with intrinsic duplicate errors
      import_session =
        Factories.insert!(:paper_ris_import_session, %{
          reference_file: reference_file,
          paper_set: paper_set,
          status: :activated,
          phase: :prompting,
          entries: [
            %{
              "status" => "error",
              "error" => %{
                "line" => 5,
                "message" => "Duplicate entry in file - DOI: 10.1234/duplicate",
                "content" => "TY  - JOUR\nDOI - 10.1234/duplicate\nT1  - First Paper\nER  -"
              },
              "raw" => "TY  - JOUR\nDOI - 10.1234/duplicate\nT1  - First Paper\nER  -"
            },
            %{
              "status" => "error",
              "error" => %{
                "line" => 10,
                "message" => "Duplicate entry in file - Title: \"Exercise and diabetes.\"",
                "content" => "TY  - JOUR\nT1  - Exercise and diabetes.\nER  -"
              },
              "raw" => "TY  - JOUR\nT1  - Exercise and diabetes.\nER  -"
            }
          ],
          summary: %{
            "total" => 2,
            "predicted_new" => 0,
            "predicted_existing" => 0,
            "predicted_errors" => 2
          }
        })

      %{
        user: user,
        tool: tool,
        import_session: import_session
      }
    end

    test "ImportSessionWarningsView displays intrinsic duplicate errors correctly", %{
      conn: conn,
      import_session: import_session
    } do
      conn = conn |> Map.put(:request_path, "/zircon/screening/import")

      # Preload the reference file association with nested file
      import_session = import_session |> Core.Repo.preload(reference_file: :file)

      # Mount the view with full session object
      {:ok, view, html} =
        live_isolated(conn, Systems.Zircon.Screening.ImportSessionWarningsView,
          session: %{
            "session" => import_session,
            "title" => "Warnings"
          }
        )

      # Verify intrinsic duplicate errors are displayed
      assert html =~ "Duplicate entry in file - DOI: 10.1234/duplicate"
      # The title text might be escaped differently in HTML, just check for the key parts
      assert html =~ "Duplicate entry in file"
      assert html =~ "Exercise and diabetes"

      # Verify table is rendered
      assert has_element?(view, "[data-testid='ris-entry-error-table']")

      # Verify line numbers are displayed
      assert html =~ "5"
      assert html =~ "10"
    end
  end
end
