defmodule Systems.Zircon.Screening.PaperSetDeleteTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Core.Repo
  alias Systems.Paper
  alias Systems.Zircon.Screening

  setup do
    # Isolate signals to prevent unwanted side effects
    isolate_signals(except: [Systems.Zircon.Switch])

    # Create required entities
    auth_node = Factories.insert!(:auth_node)
    tool = Factories.insert!(:zircon_screening_tool, %{auth_node: auth_node})

    # Create paper set
    paper_set = Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool.id)

    # Create some test papers
    paper1 =
      Factories.insert!(:paper, %{
        title: "Test Paper 1",
        doi: "10.1234/test1",
        year: "2024"
      })

    paper2 =
      Factories.insert!(:paper, %{
        title: "Test Paper 2",
        doi: "10.1234/test2",
        year: "2024"
      })

    paper3 =
      Factories.insert!(:paper, %{
        title: "Test Paper 3",
        doi: "10.1234/test3",
        year: "2024"
      })

    # Associate papers with the set
    Repo.insert!(%Paper.SetAssoc{paper_id: paper1.id, set_id: paper_set.id})
    Repo.insert!(%Paper.SetAssoc{paper_id: paper2.id, set_id: paper_set.id})
    Repo.insert!(%Paper.SetAssoc{paper_id: paper3.id, set_id: paper_set.id})

    %{paper_set: paper_set, papers: [paper1, paper2, paper3]}
  end

  describe "delete paper from set" do
    test "removes paper when delete button is clicked", %{
      conn: conn,
      paper_set: paper_set,
      papers: [paper1, paper2, paper3]
    } do
      # Set request path
      conn = conn |> Map.put(:request_path, "/paper_set/#{paper_set.id}")

      # Mount the paper set view
      {:ok, view, html} =
        live_isolated(conn, Screening.PaperSetView, session: %{"paper_set_id" => paper_set.id})

      # Verify all three papers are shown initially
      assert html =~ paper1.title
      assert html =~ paper2.title
      assert html =~ paper3.title

      # Count papers in the set
      initial_count =
        Paper.SetAssoc
        |> Repo.all()
        |> Enum.filter(&(&1.set_id == paper_set.id))
        |> length()

      assert initial_count == 3

      # Click the delete button for paper2
      render_click(view, :delete, %{"item" => "#{paper2.id}"})

      # Check the updated HTML
      updated_html = render(view)

      # Paper2 should be gone, others should remain
      assert updated_html =~ paper1.title
      refute updated_html =~ paper2.title
      assert updated_html =~ paper3.title

      # Verify paper was removed from database
      remaining_count =
        Paper.SetAssoc
        |> Repo.all()
        |> Enum.filter(&(&1.set_id == paper_set.id))
        |> length()

      assert remaining_count == 2

      # Verify paper2 still exists but is no longer in the set
      assert Repo.get(Paper.Model, paper2.id) != nil

      assoc_exists =
        Paper.SetAssoc
        |> Repo.all()
        |> Enum.any?(&(&1.set_id == paper_set.id && &1.paper_id == paper2.id))

      refute assoc_exists
    end

    test "can delete multiple papers", %{conn: conn, paper_set: paper_set, papers: papers} do
      # Set request path
      conn = conn |> Map.put(:request_path, "/paper_set/#{paper_set.id}")

      {:ok, view, _html} =
        live_isolated(conn, Screening.PaperSetView, session: %{"paper_set_id" => paper_set.id})

      # Delete all papers one by one
      Enum.each(papers, fn paper ->
        render_click(view, :delete, %{"item" => "#{paper.id}"})
      end)

      # Verify all papers are removed from the set
      remaining_count =
        Paper.SetAssoc
        |> Repo.all()
        |> Enum.filter(&(&1.set_id == paper_set.id))
        |> length()

      assert remaining_count == 0

      # Check the view shows no papers
      final_html = render(view)

      Enum.each(papers, fn paper ->
        refute final_html =~ paper.title
      end)
    end
  end
end
