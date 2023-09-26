defmodule Systems.Campaign.Assembly do
  import Core.ImageCatalog, only: [image_catalog: 0]

  alias Core.Accounts
  alias Core.Authorization
  alias Core.Repo
  alias Ecto.Multi

  alias Frameworks.Utility.EctoHelper

  alias Systems.{
    Campaign,
    Assignment,
    Questionnaire,
    Lab,
    Crew,
    Pool,
    Promotion
  }

  def delete(%Campaign.Model{
        auth_node: auth_node,
        submissions: _submissions,
        promotion: promotion,
        promotable_assignment: %{
          crew: crew,
          assignable_experiment: experiment
        }
      }) do
    Multi.new()
    |> EctoHelper.delete(:promotion, promotion)
    |> Assignment.Public.delete_tool(experiment)
    |> EctoHelper.delete(:crew, crew)
    |> Multi.delete(:auth_node, auth_node)
    |> Repo.transaction()
  end

  def create(user, title, tool_type, pool, budget) do
    profile = user |> Accounts.get_profile()

    promotion_attrs = create_promotion_attrs(title, user, profile)

    campaign_auth_node = Authorization.create_node!()
    promotion_auth_node = Authorization.create_node!(campaign_auth_node)
    assignment_auth_node = Authorization.create_node!(campaign_auth_node)
    crew_auth_node = Authorization.create_node!(assignment_auth_node)
    experiment_auth_node = Authorization.create_node!(assignment_auth_node)
    tool_auth_node = Authorization.create_node!(experiment_auth_node)

    {:ok, tool} = create_tool(tool_type, tool_auth_node)
    {:ok, crew} = Crew.Public.create(crew_auth_node)

    {:ok, experiment} =
      Assignment.Public.create_experiment(
        experiment_attrs(tool_type),
        tool,
        experiment_auth_node
      )

    {:ok, assignment} =
      Assignment.Public.create(
        assignment_attrs(),
        crew,
        experiment,
        budget,
        assignment_auth_node
      )

    {:ok, promotion} = Promotion.Public.create(promotion_attrs, promotion_auth_node)
    {:ok, submission} = Pool.Public.create_submission(submission_attrs(), pool)

    {:ok, campaign} =
      Campaign.Public.create(promotion, assignment, [submission], user, campaign_auth_node)

    {:ok, _author} = Campaign.Public.add_author(campaign, user)

    campaign
  end

  defp create_tool(tool_type, tool_auth_node) do
    tool_attrs = create_tool_attrs()
    context(tool_type).create_tool(tool_attrs, tool_auth_node)
  end

  defp context(:online), do: Questionnaire.Public
  defp context(:lab), do: Lab.Public

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
          submissions: submissions,
          promotion:
            %{
              auth_node: promotion_auth_node
            } = promotion,
          promotable_assignment:
            %{
              budget: budget,
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

    promotion = Promotion.Public.copy(promotion, promotion_auth_node)
    submissions = Pool.Public.copy(submissions)
    tool = Assignment.Public.copy_tool(experiment, experiment_auth_node)
    experiment = Assignment.Public.copy_experiment(experiment, tool, experiment_auth_node)
    assignment = Assignment.Public.copy(assignment, budget, experiment, assignment_auth_node)

    campaign =
      Campaign.Public.copy(campaign, promotion, assignment, submissions, campaign_auth_node)

    authors = Campaign.Public.copy(authors, campaign)

    {
      :ok,
      %{
        campaign: campaign,
        promotion: promotion,
        submissions: submissions,
        tool: tool,
        experiment: experiment,
        assignment: assignment,
        authors: authors
      }
    }
  end
end
