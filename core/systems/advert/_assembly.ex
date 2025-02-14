defmodule Systems.Advert.Assembly do
  use Gettext, backend: CoreWeb.Gettext

  use Core, :auth
  alias Core.Repo
  alias Ecto.Multi
  alias Ecto.Changeset

  alias Frameworks.Signal
  alias Systems.Advert
  alias Systems.Assignment
  alias Systems.Promotion
  alias Systems.Pool
  alias Systems.Project
  alias Systems.Account

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

  def create(
        %Assignment.Model{info: %{image_id: image_id, title: title}} = assignment,
        user,
        pool
      ) do
    project_node =
      %{auth_node: project_auth_node} =
      assignment
      |> Project.Public.get_item_by()
      |> Project.Public.get_node_by_item!([:auth_node])

    profile = user |> Account.Public.get_profile()

    promotion_attrs = create_promotion_attrs(image_id, title, user, profile)

    advert_auth_node = auth_module().create_node!(project_auth_node)
    promotion_auth_node = auth_module().create_node!(advert_auth_node)

    promotion = Promotion.Public.prepare(promotion_attrs, promotion_auth_node)
    submission = Pool.Public.prepare_submission(%{director: :advert, status: :idle}, pool)

    advert_name = get_advert_name(title, project_node)

    project_item =
      prepare_advert_project_item(
        project_node,
        assignment,
        submission,
        promotion,
        advert_name,
        advert_auth_node
      )

    Multi.new()
    |> Multi.insert(:project_item, project_item)
    |> Signal.Public.multi_dispatch({:project_item, :inserted})
    |> Repo.transaction()
  end

  def get_advert_name(nil, project_node) do
    Project.Public.new_item_name(
      project_node,
      dgettext("eyra-advert", "advert.default.name")
    )
  end

  def get_advert_name(name, project_node) when is_binary(name) do
    case name do
      "" -> get_advert_name(nil, project_node)
      name -> name
    end
  end

  defp prepare_advert_project_item(
         %{id: project_node_id, project_path: project_path} = project_node,
         assignment,
         submission,
         promotion,
         name,
         auth_node
       ) do
    advert =
      %Advert.Model{}
      |> Advert.Model.changeset(%{status: :concept})
      |> Changeset.put_assoc(:auth_node, auth_node)
      |> Changeset.put_assoc(:assignment, assignment)
      |> Changeset.put_assoc(:submission, submission)
      |> Changeset.put_assoc(:promotion, promotion)

    Project.Public.prepare_item(
      %{name: name, project_path: project_path ++ [project_node_id]},
      advert
    )
    |> Changeset.put_assoc(:node, project_node)
  end

  defp create_promotion_attrs(image_id, title, user, profile) do
    %{
      director: :advert,
      title: title,
      marks: ["panl"],
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
    advert_auth_node = auth_module().copy(advert_auth_node)
    promotion_auth_node = auth_module().copy(promotion_auth_node, advert_auth_node)
    assignment_auth_node = auth_module().copy(assignment_auth_node, advert_auth_node)

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
