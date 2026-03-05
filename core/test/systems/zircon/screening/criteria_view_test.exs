defmodule Systems.Zircon.Screening.CriteriaViewTest do
  use CoreWeb.ConnCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Systems.Zircon
  alias Systems.Zircon.Screening
  alias Systems.Zircon.Screening.ToolAnnotationAssoc
  alias Systems.Zircon.Screening.ToolModel

  setup do
    ontology = Zircon.Factories.setup_ontology()
    member = Factories.insert!(:member)
    dimension1_ontology_ref = Factories.build(:ontology_ref, %{concept: ontology.dimension1})

    dimension1_annotation_ref =
      Factories.build(:annotation_ref, %{ontology_ref: dimension1_ontology_ref})

    dimension1_criterion =
      Factories.build(:annotation, %{
        type: ontology.context.parameter,
        statement: "Dimension 1 specification",
        references: [
          dimension1_annotation_ref
        ]
      })

    tool = Factories.insert!(:zircon_screening_tool, %{annotations: [dimension1_criterion]})

    session = %{
      "user" => member,
      "tool" => tool,
      "title" => "Test Criteria View"
    }

    %{ontology: ontology, tool: tool, member: member, session: session}
  end

  describe "show criteria view" do
    test "Default", %{conn: conn, session: session} do
      # add bogus request path to prevent error:  * 1st argument: not an iodata term
      conn = Map.put(conn, :request_path, "/zircon/screening/criteria")
      {:ok, _view, html} = live_isolated(conn, Screening.CriteriaView, session: session)

      assert html =~ "Test Criteria View"
      assert html =~ "Dimension 1"
      assert html =~ "Dimension 2"
      assert html =~ "Dimension 3"
      assert html =~ "Dimension 4"

      assert html =~ "Dimension 1 specification"
      refute html =~ "Dimension 2 specification"
      refute html =~ "Dimension 3 specification"
      refute html =~ "Dimension 4 specification"

      assert html =~ "Framework 1"
      assert html =~ "Framework 2"
      assert html =~ "Framework 3"

      refute html =~ "Dimension 5"
      refute html =~ "Framework 4"
    end

    test "Clicking on add criterion shows criterion form", %{
      conn: conn,
      session: session,
      tool: tool
    } do
      # add bogus request path to prevent error:  * 1st argument: not an iodata term
      conn = Map.put(conn, :request_path, "/zircon/screening/criteria")

      {:ok, view, _html} = live_isolated(conn, Screening.CriteriaView, session: session)

      html = render_click(view, :add, %{"item" => "Dimension 1"})

      assert html =~ "<div><textarea id=\"annotation_form_criterion_form_0_statement\""

      assert [%{}] =
               Core.Repo.all(
                 from(taa in ToolAnnotationAssoc,
                   where: taa.tool_id == ^tool.id
                 )
               )

      assert [%{annotations: [%{}]}] =
               from(t in ToolModel, where: t.id == ^tool.id)
               |> Core.Repo.all()
               |> Core.Repo.preload(:annotations)
    end

    test "Clicking on add criterion twice on same dimension fails", %{
      conn: conn,
      session: session,
      tool: tool
    } do
      # add bogus request path to prevent error:  * 1st argument: not an iodata term
      conn = Map.put(conn, :request_path, "/zircon/screening/criteria")

      {:ok, view, _html} = live_isolated(conn, Screening.CriteriaView, session: session)

      render_click(view, :add, %{"item" => "Dimension 1"})
      html = render_click(view, :add, %{"item" => "Dimension 1"})

      assert html =~ "<div><textarea id=\"annotation_form_criterion_form_0_statement\""
      refute html =~ "<div><textarea id=\"annotation_form_criterion_form_1_statement\""

      assert [%{}] =
               Core.Repo.all(
                 from(taa in ToolAnnotationAssoc,
                   where: taa.tool_id == ^tool.id
                 )
               )

      assert [%{annotations: [%{}]}] =
               from(t in ToolModel, where: t.id == ^tool.id)
               |> Core.Repo.all()
               |> Core.Repo.preload(:annotations)
    end

    test "Clicking on add criterion twice on different dimension succeeds", %{
      conn: conn,
      session: session,
      tool: tool
    } do
      # add bogus request path to prevent error:  * 1st argument: not an iodata term
      conn = Map.put(conn, :request_path, "/zircon/screening/criteria")

      {:ok, view, _html} = live_isolated(conn, Screening.CriteriaView, session: session)

      render_click(view, :add, %{"item" => "Dimension 1"})
      render_click(view, :add, %{"item" => "Dimension 2"})
      html = render(view)
      assert html =~ "<div><textarea id=\"annotation_form_criterion_form_0_statement\""
      assert html =~ "<div><textarea id=\"annotation_form_criterion_form_1_statement\""

      assert [%{}, %{}] =
               Core.Repo.all(
                 from(taa in ToolAnnotationAssoc,
                   where: taa.tool_id == ^tool.id
                 )
               )

      assert [%{annotations: [%{}, %{}]}] =
               from(t in ToolModel, where: t.id == ^tool.id)
               |> Core.Repo.all()
               |> Core.Repo.preload(:annotations)
    end

    test "Clicking on delete criterion removes criterion", %{
      conn: conn,
      session: session,
      tool: tool
    } do
      # add bogus request path to prevent error:  * 1st argument: not an iodata term
      conn = Map.put(conn, :request_path, "/zircon/screening/criteria")

      {:ok, view, html} = live_isolated(conn, Screening.CriteriaView, session: session)

      assert html =~ "<div><textarea id=\"annotation_form_criterion_form_0_statement\""

      render_click(view, :delete, %{"item" => "criterion_form_0"})
      html = render(view)
      refute html =~ "<div><textarea id=\"annotation_form_criterion_form_0_statement\""

      assert [] =
               Core.Repo.all(
                 from(taa in ToolAnnotationAssoc,
                   where: taa.tool_id == ^tool.id
                 )
               )

      assert [%{annotations: []}] =
               from(t in ToolModel, where: t.id == ^tool.id)
               |> Core.Repo.all()
               |> Core.Repo.preload(:annotations)
    end
  end
end
