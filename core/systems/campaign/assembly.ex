defmodule Systems.Campaign.Assembly do

  alias Systems.{
    Campaign,
    Assignment,
    Crew
  }
  alias Frameworks.Utility.EctoHelper
  alias Core.Content
  alias Systems.Promotion
  alias Core.Submissions
  alias Core.Pools
  alias Core.Pools.Submissions
  alias Core.Survey.Tools
  alias Core.Accounts
  alias Core.Authorization
  alias Core.Repo
  alias Ecto.Multi

  import Core.ImageCatalog, only: [image_catalog: 0]


  def delete(%Campaign.Model{
    auth_node: auth_node,
    promotion: promotion,
    promotable_assignment: %{
      crew: crew,
      assignable_survey_tool: %{
        content_node_id: content_node_id
      } = survey_tool
    }
  }) do

    content_node = Core.Content.Nodes.get!(content_node_id)

    Multi.new()
    |> EctoHelper.delete(:promotion, promotion)
    |> EctoHelper.delete(:survey_tool, survey_tool)
    |> EctoHelper.delete(:crew, crew)
    |> Multi.delete(:auth_node, auth_node)
    |> Multi.delete(:content_node, content_node)
    |> Repo.transaction()
  end

  def create(user, title) do
    profile = user |> Accounts.get_profile()

    tool_attrs = create_tool_attrs()
    promotion_attrs = create_promotion_attrs(title, user, profile)

    pool = Pools.get_by_name(:vu_students)

    campaign_auth_node = Authorization.create_node!()
    promotion_auth_node = Authorization.create_node!(campaign_auth_node)
    assignment_auth_node = Authorization.create_node!(campaign_auth_node)
    tool_auth_node = Authorization.create_node!(assignment_auth_node)
    crew_auth_node = Authorization.create_node!(assignment_auth_node)

    tool_content_node = Content.Nodes.create!(%{ready: false})
    promotion_content_node = Content.Nodes.create!(%{ready: false}, tool_content_node)
    submission_content_node = Content.Nodes.create!(%{ready: true}, promotion_content_node)

    with {:ok, tool} <- Tools.create_survey_tool(tool_attrs, tool_auth_node, tool_content_node),
         {:ok, crew} <- Crew.Context.create(crew_auth_node),
         {:ok, assignment} <- Assignment.Context.create(assignment_attrs(), crew, tool, assignment_auth_node),
         {:ok, promotion} <- Promotion.Context.create(promotion_attrs, promotion_auth_node, promotion_content_node),
         {:ok, _submission} <- Submissions.create(submission_attrs(), promotion, pool, submission_content_node),
         {:ok, campaign} <- Campaign.Context.create(promotion, assignment, user, campaign_auth_node),
         {:ok, _author} <- Campaign.Context.add_author(campaign, user)
    do
      campaign
    end
  end

  defp assignment_attrs(), do: %{director: :campaign}
  defp submission_attrs(), do: %{director: :campaign, status: :idle}

  defp create_tool_attrs() do
    %{
      director: :campaign,
      reward_currency: :eur,
      devices: [:phone, :tablet, :desktop]
    }
  end

  defp create_promotion_attrs(title, user, profile) do
    image_id = image_catalog().random(:abstract)

    %{
      director: :campaign,
      title: title,
      marks: ["vu"],
      banner_photo_url: profile.photo_url,
      banner_title: user.displayname,
      banner_subtitle: profile.title,
      banner_url: nil,
      image_id: image_id
    }
  end

  # Copy

  def copy(%Campaign.Model{
    auth_node: campaign_auth_node,
    authors: authors,
    promotion: %{
      auth_node: promotion_auth_node,
      content_node: promotion_content_node,
      submission: %{
        pool: pool,
        criteria: criteria,
        content_node: submission_content_node,
      } = submission
    } = promotion,
    promotable_assignment: %{
      auth_node: assignment_auth_node,
      assignable_survey_tool: %{
        auth_node: tool_auth_node,
        content_node: tool_content_node
      } = tool
    } = assignment
  } = campaign) do

    campaign_auth_node = Authorization.copy(campaign_auth_node)
    promotion_auth_node = Authorization.copy(promotion_auth_node, campaign_auth_node)
    assignment_auth_node = Authorization.copy(assignment_auth_node, campaign_auth_node)
    tool_auth_node = Authorization.copy(tool_auth_node, assignment_auth_node)

    tool_content_node = Content.Nodes.copy(tool_content_node)
    promotion_content_node = Content.Nodes.copy(promotion_content_node, tool_content_node)
    submission_content_node = Content.Nodes.copy(submission_content_node, promotion_content_node)

    promotion = Promotion.Context.copy(promotion, promotion_auth_node, promotion_content_node)
    submission = Submissions.copy(submission, promotion, pool, submission_content_node)
    _criteria = Submissions.copy(criteria, submission)
    tool = Tools.copy(tool, tool_auth_node, tool_content_node)
    assignment = Assignment.Context.copy(assignment, tool, assignment_auth_node)
    campaign = Campaign.Context.copy(campaign, promotion, assignment, campaign_auth_node)
    _authors = Campaign.Context.copy(authors, campaign)

    campaign
  end

end
