defmodule Systems.Campaign.Assembly do
  alias Systems.{
    Campaign,
    Assignment,
    Survey,
    Lab,
    Crew
  }

  alias Frameworks.Utility.EctoHelper
  alias Systems.Promotion
  alias Core.Submissions
  alias Core.Pools
  alias Core.Pools.Submissions
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
          assignable_experiment: experiment
        }
      }) do
    Multi.new()
    |> EctoHelper.delete(:promotion, promotion)
    |> Assignment.Context.delete_tool(experiment)
    |> EctoHelper.delete(:crew, crew)
    |> Multi.delete(:auth_node, auth_node)
    |> Repo.transaction()
  end

  def create(user, title, tool_type) do
    profile = user |> Accounts.get_profile()

    promotion_attrs = create_promotion_attrs(title, user, profile)

    pool = Pools.get_by_name(:sbe_2021)

    campaign_auth_node = Authorization.create_node!()
    promotion_auth_node = Authorization.create_node!(campaign_auth_node)
    assignment_auth_node = Authorization.create_node!(campaign_auth_node)
    crew_auth_node = Authorization.create_node!(assignment_auth_node)
    experiment_auth_node = Authorization.create_node!(assignment_auth_node)
    tool_auth_node = Authorization.create_node!(experiment_auth_node)

    with {:ok, tool} <- create_tool(tool_type, tool_auth_node),
         {:ok, crew} <- Crew.Context.create(crew_auth_node),
         {:ok, experiment} <-
           Assignment.Context.create_experiment(
             experiment_attrs(tool_type),
             tool,
             experiment_auth_node
           ),
         {:ok, assignment} <-
           Assignment.Context.create(assignment_attrs(), crew, experiment, assignment_auth_node),
         {:ok, promotion} <- Promotion.Context.create(promotion_attrs, promotion_auth_node),
         {:ok, _submission} <- Submissions.create(submission_attrs(), promotion, pool),
         {:ok, campaign} <-
           Campaign.Context.create(promotion, assignment, user, campaign_auth_node),
         {:ok, _author} <- Campaign.Context.add_author(campaign, user) do
      campaign
    end
  end

  defp create_tool(tool_type, tool_auth_node) do
    tool_attrs = create_tool_attrs()
    context(tool_type).create_tool(tool_attrs, tool_auth_node)
  end

  defp context(:online), do: Survey.Context
  defp context(:lab), do: Lab.Context

  defp assignment_attrs(), do: %{director: :campaign}
  defp submission_attrs(), do: %{director: :campaign, status: :idle}

  defp experiment_attrs(:online) do
    %{
      director: :campaign,
      devices: [:phone, :tablet, :desktop]
    }
  end

  defp experiment_attrs(:lab) do
    %{
      director: :campaign,
      devices: []
    }
  end

  defp create_tool_attrs() do
    %{
      director: :campaign
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

  def copy(
        %Campaign.Model{
          auth_node: campaign_auth_node,
          authors: authors,
          promotion:
            %{
              auth_node: promotion_auth_node,
              submission:
                %{
                  pool: pool,
                  criteria: criteria
                } = submission
            } = promotion,
          promotable_assignment:
            %{
              auth_node: assignment_auth_node,
              assignable_experiment:
                %{
                  auth_node: experiment_auth_node
                } = experiment
            } = assignment
        } = campaign
      ) do
    campaign_auth_node = Authorization.copy(campaign_auth_node)
    promotion_auth_node = Authorization.copy(promotion_auth_node, campaign_auth_node)
    assignment_auth_node = Authorization.copy(assignment_auth_node, campaign_auth_node)
    experiment_auth_node = Authorization.copy(experiment_auth_node, assignment_auth_node)

    promotion = Promotion.Context.copy(promotion, promotion_auth_node)
    submission = Submissions.copy(submission, promotion, pool)
    criteria = Submissions.copy(criteria, submission)
    tool = Assignment.Context.copy_tool(experiment, experiment_auth_node)
    experiment = Assignment.Context.copy_experiment(experiment, tool, experiment_auth_node)
    assignment = Assignment.Context.copy(assignment, experiment, assignment_auth_node)
    campaign = Campaign.Context.copy(campaign, promotion, assignment, campaign_auth_node)
    authors = Campaign.Context.copy(authors, campaign)

    {
      :ok,
      %{
        campaign: campaign,
        promotion: promotion,
        submission: submission,
        criteria: criteria,
        tool: tool,
        experiment: experiment,
        assignment: assignment,
        authors: authors
      }
    }
  end
end
