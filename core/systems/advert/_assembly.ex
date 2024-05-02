defmodule Systems.Advert.Assembly do
  import Core.ImageCatalog, only: [image_catalog: 0]

  alias Core.Accounts
  alias Core.Authorization
  alias Core.Repo
  alias Ecto.Multi

  alias Systems.{
    Advert,
    Assignment,
    Promotion,
    Pool
  }

  def delete(%Advert.Model{} = advert) do
    Multi.new()
    |> delete(advert)
    |> Repo.transaction()
  end

  def delete(
        multi,
        %Advert.Model{
          auth_node: auth_node,
          promotion: promotion
        } = advert
      ) do
    multi
    |> Multi.delete(:advert, advert)
    |> Multi.delete(:advert_auth_node, auth_node)
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

    advert_auth_node = Authorization.create_node!()
    promotion_auth_node = Authorization.create_node!(advert_auth_node)

    {:ok, promotion} = Promotion.Public.create(promotion_attrs, promotion_auth_node)
    {:ok, submission} = Pool.Public.create_submission(submission_attrs(), pool)
    {:ok, assignment} = Assignment.Assembly.create(template, :advert, budget)

    {:ok, advert} =
      Advert.Public.create(promotion, assignment, submission, user, advert_auth_node)

    advert
  end

  defp submission_attrs(), do: %{director: :advert, status: :idle}

  defp create_promotion_attrs(title, user, profile) do
    image_id = image_catalog().random(:abstract)

    %{
      director: :advert,
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
        %Advert.Model{
          auth_node: advert_auth_node,
          submission: submission,
          promotion:
            %{
              auth_node: promotion_auth_node
            } = promotion,
          assignment:
            %{
              budget: budget,
              auth_node: assignment_auth_node,
              info: info,
              workflow: workflow
            } = assignment
        } = advert
      ) do
    advert_auth_node = Authorization.copy(advert_auth_node)
    promotion_auth_node = Authorization.copy(promotion_auth_node, advert_auth_node)
    assignment_auth_node = Authorization.copy(assignment_auth_node, advert_auth_node)

    promotion = Promotion.Public.copy(promotion, promotion_auth_node)
    submission = Pool.Public.copy(submission)
    info = Assignment.Public.copy_info(info)
    workflow = Assignment.Public.copy_workflow(workflow)
    assignment = Assignment.Public.copy(assignment, info, workflow, budget, assignment_auth_node)

    advert = Advert.Public.copy(advert, promotion, assignment, submission, advert_auth_node)

    {
      :ok,
      %{
        advert: advert,
        promotion: promotion,
        submission: submission,
        info: info,
        workflow: workflow,
        assignment: assignment
      }
    }
  end
end
