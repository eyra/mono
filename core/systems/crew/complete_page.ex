defmodule Systems.Task.CompletePage do
  @moduledoc """
  The redirect page to complete a task
  """
  use CoreWeb, :live_view

  alias EyraUI.Hero.HeroSmall
  alias EyraUI.Text.{Title1, BodyLarge}

  alias Systems.Campaign
  alias Core.Survey.Tools
  alias Core.Promotions

  data(campaign, :any)
  data(tool, :any)
  data(promotion, :any)

  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns[:current_user]
    campaign = Campaign.Context.get!(id)
    tool = load_tool(campaign)
    promotion = Promotions.get!(tool.promotion_id)

    tool
    |> Tools.get_or_create_task!(user)
    |> Tools.complete_task!()

    socket =
      socket
      |> assign(
        user: user,
        campaign: campaign,
        tool: tool,
        promotion: promotion
      )

    {:ok, socket}
  end

  @impl true
  def handle_uri(socket), do: socket

  def load_tool(%Campaign.Model{} = campaign) do
    case Campaign.Context.list_survey_tools(campaign) do
      [] -> raise "Expected at least one survey tool for campaign #{campaign.title}"
      [survey_tool | _] -> survey_tool
    end
  end

  def render(assigns) do
    ~H"""
      <HeroSmall title={{ dgettext("link-survey", "conpleted.title") }} />
      <ContentArea>
        <MarginY id={{:page_top}} />
        <Title1>{{ @promotion.title }}</Title1>
        <Spacing value="M" />
        <BodyLarge>{{dgettext("link-survey", "thank.you.message")}}</BodyLarge>
      </ContentArea>
    """
  end
end
