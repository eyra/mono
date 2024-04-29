defmodule Systems.Campaign.Assembly do
  import Core.ImageCatalog, only: [image_catalog: 0]

  alias Core.Accounts
  alias Core.Authorization
  alias Core.Repo
  alias Ecto.Multi

  alias Systems.{
    Campaign,
    Assignment,
    Promotion,
    Pool
  }

  def delete(%Campaign.Model{} = campaign) do
    Multi.new()
    |> delete(campaign)
    |> Repo.transaction()
  end

  def delete(
        multi,
        %Campaign.Model{
          auth_node: auth_node,
          promotion: promotion
        } = campaign
      ) do
    multi
    |> Multi.delete(:campaign, campaign)
    |> Multi.delete(:campaign_auth_node, auth_node)
    |> delete(promotion)
  end

  def delete(multi, %Promotion.Model{auth_node: auth_node} = promotion) do
    multi
    |> Multi.delete(:promotion, promotion)
    |> Multi.delete(:promotion_auth_node, auth_node)
  end

  def create(template, user, title, pool, budget) do
    profile = user |> Accounts.get_profile()

    promotion_attrs = create_promotion_attrs(title, user, profile)

    campaign_auth_node = Authorization.create_node!()
    promotion_auth_node = Authorization.create_node!(campaign_auth_node)

    {:ok, promotion} = Promotion.Public.create(promotion_attrs, promotion_auth_node)
    {:ok, submission} = Pool.Public.create_submission(submission_attrs(), pool)

    {:ok, assignment} = Assignment.Assembly.create(template, :campaign, budget)

    {:ok, campaign} =
      Campaign.Public.create(promotion, assignment, [submission], user, campaign_auth_node)

    {:ok, _author} = Campaign.Public.add_author(campaign, user)

    campaign
  end

  defp submission_attrs(), do: %{director: :campaign, status: :idle}

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
              info: info,
              workflow: workflow
            } = assignment
        } = campaign
      ) do
    campaign_auth_node = Authorization.copy(campaign_auth_node)
    promotion_auth_node = Authorization.copy(promotion_auth_node, campaign_auth_node)
    assignment_auth_node = Authorization.copy(assignment_auth_node, campaign_auth_node)

    promotion = Promotion.Public.copy(promotion, promotion_auth_node)
    submissions = Pool.Public.copy(submissions)
    info = Assignment.Public.copy_info(info)
    workflow = Assignment.Public.copy_workflow(workflow)
    assignment = Assignment.Public.copy(assignment, info, workflow, budget, assignment_auth_node)

    campaign =
      Campaign.Public.copy(campaign, promotion, assignment, submissions, campaign_auth_node)

    authors = Campaign.Public.copy(authors, campaign)

    {
      :ok,
      %{
        campaign: campaign,
        promotion: promotion,
        submissions: submissions,
        info: info,
        workflow: workflow,
        assignment: assignment,
        authors: authors
      }
    }
  end
end
