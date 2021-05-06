defmodule CoreWeb.Live.Study.Edit.Test do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias CoreWeb.Study

  alias Core.Factories

  def setup_study(_ctx) do
    researcher = Factories.insert!(:researcher)
    study = Factories.insert!(:study)
    _author = Factories.insert!(:author, %{study: study, researcher: researcher})
    survey_tool = Factories.insert!(:survey_tool, %{study: study})
    user = Factories.insert!(:member)

    _survey_tool_participant =
      Factories.insert!(:survey_tool_participant, %{survey_tool: survey_tool, user: user})

    {:ok, study: study}
  end

  defp take_ownership_of_study(%{user: user, study: study}) do
    :ok = Core.Authorization.assign_role(user, study, :owner)

    {:ok, []}
  end

  describe "as an owner" do
    setup [:login_as_researcher, :setup_study, :take_ownership_of_study]

    test "edit a study", %{conn: conn, study: study} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, Study.Edit, study.id))
      title = Faker.Lorem.sentence()
      description = Faker.Lorem.sentence()

      view
      |> form("#main_form")
      |> render_change(%{study: %{title: title, description: description}})
    end
  end

  describe "as a member" do
    setup [:login_as_researcher, :setup_study]

    test "disallow other researchers to edit a study", %{conn: conn, study: study} do
      {:ok, _view, html} = live(conn, Routes.live_path(conn, Study.Edit, study.id))
      assert html =~ "Access Denied"
    end
  end
end
