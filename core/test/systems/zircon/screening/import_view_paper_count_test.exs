defmodule Systems.Zircon.Screening.ImportViewPaperCountTest do
  use CoreWeb.ConnCase, async: false
  use Oban.Testing, repo: Core.Repo
  import Phoenix.LiveViewTest

  alias Core.Repo
  alias Systems.Paper
  alias Systems.Zircon
  alias Systems.Zircon.Screening

  setup do
    # Don't isolate signals - we need them for Observatory updates
    # The ImportView and PaperSetView need to receive signals

    # Create required entities
    auth_node = Factories.insert!(:auth_node)
    tool = Factories.insert!(:zircon_screening_tool, %{auth_node: auth_node})

    # Create paper set
    paper_set = Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool.id)

    # Create some test papers
    paper1 =
      Factories.insert!(:paper, %{
        title: "Paper Count Test 1",
        doi: "10.1234/count1",
        year: "2024"
      })

    paper2 =
      Factories.insert!(:paper, %{
        title: "Paper Count Test 2",
        doi: "10.1234/count2",
        year: "2024"
      })

    paper3 =
      Factories.insert!(:paper, %{
        title: "Paper Count Test 3",
        doi: "10.1234/count3",
        year: "2024"
      })

    # Associate papers with the set
    Repo.insert!(%Paper.SetAssoc{paper_id: paper1.id, set_id: paper_set.id})
    Repo.insert!(%Paper.SetAssoc{paper_id: paper2.id, set_id: paper_set.id})
    Repo.insert!(%Paper.SetAssoc{paper_id: paper3.id, set_id: paper_set.id})

    %{tool: tool, paper_set: paper_set, papers: [paper1, paper2, paper3]}
  end

  describe "paper count updates in ImportView" do
    test "paper count decreases when paper is deleted from set", %{
      conn: conn,
      tool: tool,
      paper_set: paper_set,
      papers: [_paper1, paper2, _paper3]
    } do
      # Mount the ImportView
      conn = conn |> Map.put(:request_path, "/zircon/screening/import")

      {:ok, import_view, import_html} =
        live_isolated(conn, Screening.ImportView,
          session: %{"title" => "Import Papers", "tool" => tool}
        )

      # Verify initial paper count is 3
      assert import_html =~ "Import Papers"
      # The paper count in the title
      assert import_html =~ ">3</span>"

      # Mount the PaperSetView in a separate process
      conn2 = conn |> Map.put(:request_path, "/paper_set/#{paper_set.id}")

      {:ok, paper_set_view, _} =
        live_isolated(conn2, Screening.PaperSetView, session: %{"paper_set_id" => paper_set.id})

      # Delete paper2 from the paper set view
      paper_set_view
      |> element("[phx-click='delete'][phx-value-item='#{paper2.id}']")
      |> render_click()

      # Give time for signal propagation and Observatory update
      Process.sleep(100)

      # Check that ImportView has updated paper count to 2
      updated_import_html = render(import_view)
      # The paper count should now be 2
      assert updated_import_html =~ ">2</span>"
      # Should no longer show 3
      refute updated_import_html =~ ">3</span>"
    end

    test "paper count increases when papers are imported", %{
      conn: conn,
      tool: tool,
      paper_set: paper_set
    } do
      # Start with 3 papers
      initial_paper_count =
        Paper.SetAssoc
        |> Repo.all()
        |> Enum.filter(&(&1.set_id == paper_set.id))
        |> length()

      assert initial_paper_count == 3

      # Mount the ImportView
      conn = conn |> Map.put(:request_path, "/zircon/screening/import")

      {:ok, import_view, import_html} =
        live_isolated(conn, Screening.ImportView,
          session: %{"title" => "Import Papers", "tool" => tool}
        )

      # Verify initial paper count
      assert import_html =~ ">3</span>"

      # Create a reference file for import
      reference_file =
        Zircon.Public.insert_reference_file!(tool, "test.ris", "http://example.com/test.ris")

      # Create an import session in prompting phase with new papers to import
      import_session =
        Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: [
            %{
              "title" => "New Imported Paper 1",
              "doi" => "10.1234/new1",
              "year" => "2024",
              "status" => "new",
              "processed_attrs" => %{
                "title" => "New Imported Paper 1",
                "doi" => "10.1234/new1",
                "year" => "2024"
              }
            },
            %{
              "title" => "New Imported Paper 2",
              "doi" => "10.1234/new2",
              "year" => "2024",
              "status" => "new",
              "processed_attrs" => %{
                "title" => "New Imported Paper 2",
                "doi" => "10.1234/new2",
                "year" => "2024"
              }
            }
          ]
        })

      # Process the import (simulating commit_import)
      # First transition to importing phase
      {:ok, %{paper_ris_import_session: updated_session}} =
        import_session
        |> Paper.RISImportSessionModel.advance_phase_with_signal(:importing)

      # Manually run the commit job since Oban is disabled in tests
      assert :ok =
               Paper.RISImportCommitJob.perform(%Oban.Job{
                 args: %{"session_id" => updated_session.id}
               })

      # Give time for signal propagation
      Process.sleep(100)

      # Check that ImportView has updated paper count to 5 (3 original + 2 imported)
      updated_import_html = render(import_view)
      # The paper count should now be 5
      assert updated_import_html =~ ">5</span>"
      # Should no longer show 3
      refute updated_import_html =~ ">3</span>"

      # Verify papers were actually added to the database
      final_paper_count =
        Paper.SetAssoc
        |> Repo.all()
        |> Enum.filter(&(&1.set_id == paper_set.id))
        |> length()

      assert final_paper_count == 5
    end

    test "paper count updates correctly with multiple operations", %{
      conn: conn,
      tool: tool,
      paper_set: paper_set,
      papers: [paper1, paper2, paper3]
    } do
      # Mount the ImportView
      conn = conn |> Map.put(:request_path, "/zircon/screening/import")

      {:ok, import_view, import_html} =
        live_isolated(conn, Screening.ImportView,
          session: %{"title" => "Import Papers", "tool" => tool}
        )

      # Initial count should be 3
      assert import_html =~ ">3</span>"

      # Mount PaperSetView for deletions
      conn2 = conn |> Map.put(:request_path, "/paper_set/#{paper_set.id}")

      {:ok, paper_set_view, _} =
        live_isolated(conn2, Screening.PaperSetView, session: %{"paper_set_id" => paper_set.id})

      # Delete paper1
      paper_set_view
      |> element("[phx-click='delete'][phx-value-item='#{paper1.id}']")
      |> render_click()

      Process.sleep(50)

      # Should be 2 now
      html_after_first_delete = render(import_view)
      assert html_after_first_delete =~ ">2</span>"

      # Delete paper2
      paper_set_view
      |> element("[phx-click='delete'][phx-value-item='#{paper2.id}']")
      |> render_click()

      Process.sleep(50)

      # Should be 1 now
      html_after_second_delete = render(import_view)
      assert html_after_second_delete =~ ">1</span>"

      # Delete paper3 (last one)
      paper_set_view
      |> element("[phx-click='delete'][phx-value-item='#{paper3.id}']")
      |> render_click()

      Process.sleep(50)

      # Should be 0 now
      html_after_all_deleted = render(import_view)
      assert html_after_all_deleted =~ ">0</span>"
    end
  end
end
