defmodule CoreWeb.Survey.Complete do
  @moduledoc """
  The public study screen.
  """
  use CoreWeb, :live_view

  alias EyraUI.Hero.HeroSmall
  alias EyraUI.Container.ContentArea
  alias EyraUI.Text.{Title1, BodyLarge}
  alias EyraUI.Spacing

  alias Core.Studies
  alias Core.Studies.Study
  alias Core.Survey.Tools
  alias Core.Promotions

  data(study, :any)
  data(tool, :any)
  data(promotion, :any)

  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns[:current_user]
    study = Studies.get_study!(id)
    tool = load_tool(study)
    promotion = Promotions.get!(tool.promotion_id)

    tool
    |> Tools.get_or_create_task!(user)
    |> Tools.complete_task!()

    socket =
      socket
      |> assign(
        user: user,
        study: study,
        tool: tool,
        promotion: promotion
      )

    {:ok, socket}
  end

  def load_tool(%Study{} = study) do
    case Studies.list_survey_tools(study) do
      [] -> raise "Expected at least one survey tool for study #{study.title}"
      [survey_tool | _] -> survey_tool
    end
  end

  def render(assigns) do
    ~H"""
      <HeroSmall title={{ dgettext("eyra-survey", "conpleted.title") }} />
      <ContentArea>
        <Title1>{{ @promotion.title }}</Title1>
        <Spacing value="M" />
        <BodyLarge>{{dgettext("eyra-survey", "thank.you.message")}}</BodyLarge>
      </ContentArea>
    """
  end
end
