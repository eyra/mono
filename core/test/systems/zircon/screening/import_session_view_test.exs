defmodule Systems.Zircon.Screening.ImportSessionViewTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  import Frameworks.Signal.TestHelper

  alias Systems.Zircon.Screening

  setup do
    # Isolate signals to prevent workflow errors (includes nested LiveViews)
    # Keeps TestHelper, Zircon.Switch, and Observatory.Switch active
    isolate_signals(except: [Systems.Zircon.Switch, Systems.Observatory.Switch])

    member = Factories.insert!(:member)

    # Create required entities for import session
    zircon_tool = Factories.insert!(:zircon_screening_tool)
    paper_set = Systems.Paper.Public.obtain_paper_set!(:zircon_screening_tool, zircon_tool.id)

    reference_file =
      Systems.Zircon.Public.insert_reference_file!(
        zircon_tool,
        "test.ris",
        "http://example.com/test.ris"
      )

    # Create import session in prompting phase (for testing results blocks)
    import_session =
      Factories.insert!(:paper_ris_import_session, %{
        status: :activated,
        phase: :prompting,
        paper_set: paper_set,
        reference_file: reference_file,
        entries: [],
        errors: []
      })

    live_session = %{
      "user" => member,
      "session_id" => import_session.id
    }

    %{
      import_session: import_session,
      member: member,
      live_session: live_session,
      zircon_tool: zircon_tool,
      paper_set: paper_set,
      reference_file: reference_file
    }
  end

  describe "render import session view" do
    test "can render without errors", %{conn: conn, live_session: live_session} do
      conn = conn |> Map.put(:request_path, "/zircon/screening/import_session")
      {:ok, view, _html} = live_isolated(conn, Screening.ImportSessionView, session: live_session)

      # Check that main structure is rendered
      assert view |> has_element?("[data-testid='import-session-view']")
      # With empty entries and errors, should show empty block
      assert view |> has_element?("[data-testid='prompting-empty-block']")
    end

    test "displays empty state when no errors and no papers", %{
      conn: conn,
      member: member,
      reference_file: reference_file
    } do
      # Create session with empty data in processing phase
      empty_session =
        Factories.insert!(:paper_ris_import_session, %{
          status: :activated,
          phase: :prompting,
          reference_file: reference_file,
          entries: [],
          errors: []
        })

      live_session = %{
        "user" => member,
        "session_id" => empty_session.id
      }

      conn = conn |> Map.put(:request_path, "/zircon/screening/import_session")
      {:ok, view, _html} = live_isolated(conn, Screening.ImportSessionView, session: live_session)

      # Should show single empty state block
      assert view |> has_element?("[data-testid='prompting-empty-block']")

      # Should not show errors or papers blocks
      refute view |> has_element?("[data-testid='errors-block']")
      refute view |> has_element?("[data-testid='new-papers-block']")
    end

    test "displays errors when present", %{
      conn: conn,
      member: member,
      reference_file: reference_file
    } do
      # Create session with errors
      session_with_errors =
        Factories.insert!(:paper_ris_import_session, %{
          status: :activated,
          phase: :prompting,
          reference_file: reference_file,
          entries: [
            %{"status" => "error", "error" => %{"line" => 10, "error" => "Invalid DOI format"}},
            %{
              "status" => "error",
              "error" => %{"line" => 25, "error" => "Missing required field"}
            }
          ],
          errors: []
        })

      live_session = %{
        "user" => member,
        "session_id" => session_with_errors.id
      }

      conn = conn |> Map.put(:request_path, "/zircon/screening/import_session")
      {:ok, view, _html} = live_isolated(conn, Screening.ImportSessionView, session: live_session)

      # Should show errors block
      assert view |> has_element?("[data-testid='errors-block']")

      # No new papers block should be rendered when there are errors but no papers
      refute view |> has_element?("[data-testid='new-papers-block']")
    end

    test "displays new papers when present", %{
      conn: conn,
      member: member,
      reference_file: reference_file
    } do
      # Create session with new papers
      session_with_papers =
        Factories.insert!(:paper_ris_import_session, %{
          status: :activated,
          phase: :prompting,
          reference_file: reference_file,
          entries: [
            %{
              doi: "10.1234/test1",
              title: "Test Paper 1",
              authors: "Author One, Author Two",
              year: "2023",
              status: "new"
            },
            %{
              doi: "10.1234/test2",
              title: "Test Paper 2",
              authors: "Author Three",
              year: "2022",
              status: "new"
            }
          ],
          errors: []
        })

      live_session = %{
        "user" => member,
        "session_id" => session_with_papers.id
      }

      conn = conn |> Map.put(:request_path, "/zircon/screening/import_session")
      {:ok, view, _html} = live_isolated(conn, Screening.ImportSessionView, session: live_session)

      # Should show papers table instead of empty state
      assert view |> has_element?("[data-testid='new-papers-table']")
      refute view |> has_element?("[data-testid='new-papers-empty']")

      # No errors block should be rendered when there are papers but no errors
      refute view |> has_element?("[data-testid='errors-block']")
    end

    test "displays correct content based on new papers count", %{
      conn: conn,
      member: member,
      reference_file: reference_file
    } do
      # Test case 1: No new papers - should show empty state
      session_no_new_papers =
        Factories.insert!(:paper_ris_import_session, %{
          status: :activated,
          phase: :prompting,
          reference_file: reference_file,
          entries: [
            %{
              doi: "10.1234/duplicate",
              title: "Duplicate Paper",
              authors: "Some Author",
              year: "2020",
              status: "duplicate"
            }
          ],
          errors: []
        })

      live_session1 = %{
        "user" => member,
        "session_id" => session_no_new_papers.id
      }

      conn = conn |> Map.put(:request_path, "/zircon/screening/import_session")

      {:ok, view1, _html} =
        live_isolated(conn, Screening.ImportSessionView, session: live_session1)

      # Should show empty state (no new papers to display)
      assert view1 |> has_element?("[data-testid='prompting-empty-block']")
      refute view1 |> has_element?("[data-testid='new-papers-block']")

      # Test case 2: Has new papers - should show new papers block
      session_with_new_papers =
        Factories.insert!(:paper_ris_import_session, %{
          status: :activated,
          phase: :prompting,
          reference_file: reference_file,
          entries: [
            %{
              doi: "10.1234/new",
              title: "New Paper",
              authors: "New Author",
              year: "2024",
              status: "new"
            }
          ],
          errors: []
        })

      live_session2 = %{
        "user" => member,
        "session_id" => session_with_new_papers.id
      }

      {:ok, view2, _html} =
        live_isolated(conn, Screening.ImportSessionView, session: live_session2)

      # Should show new papers block
      assert view2 |> has_element?("[data-testid='prompting-new-papers-block']")
      refute view2 |> has_element?("[data-testid='prompting-empty-block']")
    end

    test "displays new papers correctly in prompting phase", %{conn: conn, member: member} do
      # Focus: Test display of new papers in ImportSessionView

      zircon_tool = Factories.insert!(:zircon_screening_tool)
      paper_set = Systems.Paper.Public.obtain_paper_set!(:zircon_screening_tool, zircon_tool.id)

      reference_file =
        Systems.Zircon.Public.insert_reference_file!(
          zircon_tool,
          "new_papers.ris",
          "http://example.com/new_papers.ris"
        )

      session_with_new_papers =
        Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: [
            %{
              "status" => "new",
              "title" => "New Paper 1",
              "subtitle" => nil,
              "authors" => ["Author 1"],
              "year" => "2024",
              "date" => nil,
              "doi" => "10.1234/new.1",
              "journal" => nil,
              "abbreviated_journal" => "Journal A",
              "volume" => nil,
              "pages" => nil,
              "abstract" => "Abstract for paper 1",
              "keywords" => ["keyword1", "keyword2"]
            },
            %{
              "status" => "new",
              "title" => "New Paper 2",
              "subtitle" => "Subtitle",
              "authors" => ["Author 2", "Co-Author"],
              "year" => "2024",
              "date" => nil,
              "doi" => "10.1234/new.2",
              "journal" => nil,
              "abbreviated_journal" => nil,
              "volume" => nil,
              "pages" => nil,
              "abstract" => nil,
              "keywords" => []
            }
          ],
          errors: [],
          summary: %{
            "total" => 2,
            "predicted_new" => 2,
            "predicted_existing" => 0,
            "imported" => 0,
            "skipped_duplicates" => 0
          }
        })

      live_session = %{
        "user" => member,
        "session_id" => session_with_new_papers.id
      }

      conn = conn |> Map.put(:request_path, "/zircon/screening/import_session")
      {:ok, view, html} = live_isolated(conn, Screening.ImportSessionView, session: live_session)

      # Verify new papers block is present
      assert view |> has_element?("[data-testid='prompting-new-papers-block']")
      assert view |> has_element?("[data-testid='new-papers-table']")

      # Verify paper content is displayed
      assert html =~ "New Paper 1"
      assert html =~ "New Paper 2"
      assert html =~ "10.1234/new.1"
      assert html =~ "10.1234/new.2"
      assert html =~ "Author 1"
      assert html =~ "Author 2"
    end

    test "displays mix of new and existing papers correctly", %{conn: conn, member: member} do
      # Focus: Test display of mixed paper statuses in ImportSessionView

      zircon_tool = Factories.insert!(:zircon_screening_tool)
      paper_set = Systems.Paper.Public.obtain_paper_set!(:zircon_screening_tool, zircon_tool.id)

      reference_file =
        Systems.Zircon.Public.insert_reference_file!(
          zircon_tool,
          "mixed_papers.ris",
          "http://example.com/mixed_papers.ris"
        )

      session_with_mixed_papers =
        Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: [
            # This should be displayed (new)
            %{
              "status" => "new",
              "title" => "Brand New Paper",
              "subtitle" => nil,
              "authors" => ["New Author"],
              "year" => "2024",
              "date" => nil,
              "doi" => "10.1234/brand.new",
              "journal" => nil,
              "abbreviated_journal" => nil,
              "volume" => nil,
              "pages" => nil,
              "abstract" => nil,
              "keywords" => []
            },
            # These should be filtered out (existing)
            %{
              "title" => "Different Title But Same DOI",
              "authors" => ["Different Author"],
              "year" => "2024",
              "doi" => "10.1234/existing.doi",
              "status" => "existing"
            },
            %{
              "title" => "Existing by Title",
              "authors" => ["Different Author"],
              "year" => "2024",
              "status" => "existing"
            }
          ],
          errors: [],
          summary: %{
            "total" => 3,
            "predicted_new" => 1,
            "predicted_existing" => 2,
            "imported" => 0,
            "skipped_duplicates" => 0
          }
        })

      live_session = %{
        "user" => member,
        "session_id" => session_with_mixed_papers.id
      }

      conn = conn |> Map.put(:request_path, "/zircon/screening/import_session")
      {:ok, view, html} = live_isolated(conn, Screening.ImportSessionView, session: live_session)

      # Should show new papers block (only new papers are displayed)
      assert view |> has_element?("[data-testid='prompting-new-papers-block']")

      # Should show only the new paper
      assert html =~ "Brand New Paper"
      assert html =~ "10.1234/brand.new"
      assert html =~ "New Author"

      # Should not show existing papers in the table
      refute html =~ "Different Title But Same DOI"
      refute html =~ "Existing by Title"
    end

    test "shows both papers initially marked as new", %{conn: conn, member: member} do
      # Focus: Test display of papers initially marked as new in ImportSessionView

      zircon_tool = Factories.insert!(:zircon_screening_tool)
      paper_set = Systems.Paper.Public.obtain_paper_set!(:zircon_screening_tool, zircon_tool.id)

      reference_file =
        Systems.Zircon.Public.insert_reference_file!(
          zircon_tool,
          "recheck.ris",
          "http://example.com/recheck.ris"
        )

      session_with_new_papers =
        Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: [
            # Marked as "new"
            %{
              "status" => "new",
              "title" => "Will Become Existing",
              "subtitle" => nil,
              "authors" => ["Author"],
              "year" => "2024",
              "date" => nil,
              "doi" => "10.1234/will.exist",
              "journal" => nil,
              "abbreviated_journal" => nil,
              "volume" => nil,
              "pages" => nil,
              "abstract" => nil,
              "keywords" => []
            },
            # This will remain new
            %{
              "status" => "new",
              "title" => "Truly New Paper",
              "subtitle" => nil,
              "authors" => ["New Author"],
              "year" => "2024",
              "date" => nil,
              "doi" => "10.1234/truly.new",
              "journal" => nil,
              "abbreviated_journal" => nil,
              "volume" => nil,
              "pages" => nil,
              "abstract" => nil,
              "keywords" => []
            }
          ],
          errors: [],
          summary: %{
            "total" => 2,
            "predicted_new" => 2,
            "predicted_existing" => 0,
            "imported" => 0,
            "skipped_duplicates" => 0
          }
        })

      live_session = %{
        "user" => member,
        "session_id" => session_with_new_papers.id
      }

      conn = conn |> Map.put(:request_path, "/zircon/screening/import_session")
      {:ok, view, html} = live_isolated(conn, Screening.ImportSessionView, session: live_session)

      # Should show new papers block with both papers
      assert view |> has_element?("[data-testid='prompting-new-papers-block']")

      # Both papers should be displayed as they are marked as "new"
      assert html =~ "Will Become Existing"
      assert html =~ "Truly New Paper"
      assert html =~ "10.1234/will.exist"
      assert html =~ "10.1234/truly.new"
      assert html =~ "Author"
      assert html =~ "New Author"
    end

    test "displays new paper content ready for import", %{conn: conn, member: member} do
      # Create a complete setup with Zircon tool and reference file
      zircon_tool = Factories.insert!(:zircon_screening_tool)
      paper_set = Systems.Paper.Public.obtain_paper_set!(:zircon_screening_tool, zircon_tool.id)

      reference_file =
        Systems.Zircon.Public.insert_reference_file!(
          zircon_tool,
          "test.ris",
          "http://example.com/test.ris"
        )

      # Create a session with new paper ready for import
      session_with_new_paper =
        Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: [
            %{
              "status" => "new",
              "title" => "Paper Ready For Import",
              "subtitle" => nil,
              "authors" => ["Author One"],
              "year" => "2024",
              "date" => nil,
              "doi" => "10.1234/ready.import",
              "journal" => nil,
              "abbreviated_journal" => nil,
              "volume" => nil,
              "pages" => nil,
              "abstract" => nil,
              "keywords" => []
            }
          ],
          errors: [],
          summary: %{
            "total" => 1,
            "predicted_new" => 1,
            "predicted_existing" => 0,
            "imported" => 0,
            "skipped_duplicates" => 0
          }
        })

      live_session = %{
        "user" => member,
        "session_id" => session_with_new_paper.id
      }

      conn = conn |> Map.put(:request_path, "/zircon/screening/import_session")
      {:ok, view, html} = live_isolated(conn, Screening.ImportSessionView, session: live_session)

      # Verify new papers block is displayed
      assert view |> has_element?("[data-testid='prompting-new-papers-block']")

      # Verify paper content is shown
      assert html =~ "Paper Ready For Import"
      assert html =~ "10.1234/ready.import"
      assert html =~ "Author One"
      assert html =~ "2024"

      # Should show new papers table
      assert view |> has_element?("[data-testid='new-papers-table']")
    end

    test "displays processing status block for parsing and importing phases", %{
      conn: conn,
      member: member
    } do
      # Test parsing phase
      parsing_session =
        Factories.insert!(:paper_ris_import_session, %{
          status: :activated,
          phase: :parsing
        })

      parsing_live_session = %{
        "user" => member,
        "session_id" => parsing_session.id
      }

      conn = conn |> Map.put(:request_path, "/zircon/screening/import_session")

      {:ok, parsing_view, _parsing_html} =
        live_isolated(conn, Screening.ImportSessionView, session: parsing_live_session)

      # Should show processing status block
      assert parsing_view |> has_element?("[data-testid='processing-status-block']")

      # Test importing phase
      importing_session =
        Factories.insert!(:paper_ris_import_session, %{
          status: :activated,
          phase: :importing
        })

      importing_live_session = %{
        "user" => member,
        "session_id" => importing_session.id
      }

      {:ok, importing_view, _importing_html} =
        live_isolated(conn, Screening.ImportSessionView, session: importing_live_session)

      # Should show processing status block
      assert importing_view |> has_element?("[data-testid='processing-status-block']")
    end
  end
end
