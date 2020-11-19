defmodule Link.Authorization do
  @moduledoc """
  The authorization system for Link.

  It makes use of the GreenLight framework to manage permissions and
  authorization.
  """
  use GreenLight,
    repo: Link.Repo,
    roles: [:visitor, :member, :researcher],
    role_assignment_schema: Link.Users.RoleAssignment

  alias GreenLight.Principal

  grant_access(Link.Studies.Study, [:visitor, :member])
  grant_access(Link.SurveyTools.SurveyTool, [:researcher])

  grant_actions(LinkWeb.StudyController, %{
    index: [:visitor, :member],
    show: [:visitor, :member],
    new: [:member],
    create: [:member],
    edit: [:researcher],
    update: [:researcher],
    delete: [:researcher]
  })

  grant_actions(LinkWeb.SurveyToolController, %{
    index: [:researcher],
    show: [:researcher, :participant],
    new: [:researcher],
    create: [:researcher],
    edit: [:researcher],
    update: [:researcher],
    delete: [:researcher]
  })

  grant_actions(LinkWeb.PageController, %{
    index: [:visitor, :member]
  })

  def principal(%Plug.Conn{} = conn) do
    Pow.Plug.current_user(conn)
    |> principal()
  end

  def principal(user) when is_nil(user) do
    %Principal{id: nil, roles: MapSet.new([:visitor])}
  end

  def principal(%Link.Users.User{} = user) do
    %Principal{id: user.id, roles: MapSet.new([:member])}
  end

  def assign_role!(%Link.Users.User{} = user, entity, role) do
    user |> principal() |> assign_role!(entity, role)
  end

  def can?(%Plug.Conn{} = conn, entity, module, action) do
    conn |> principal() |> can?(entity, module, action)
  end

  # entity_loader(
  #   &Loaders.survey_tool!/3,
  #   parents: [
  #     &Loaders.study!/3
  #   ]
  # )
end
