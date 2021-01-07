defmodule Link.Authorization do
  @moduledoc """
  The authorization system for Link.

  It makes use of the GreenLight framework to manage permissions and
  authorization.
  """
  use GreenLight,
    repo: Link.Repo,
    roles: [:visitor, :member, :researcher, :owner, :participant],
    role_assignment_schema: Link.Users.RoleAssignment

  alias GreenLight.Principal
  alias Link.Users

  grant_access(Link.Studies.Study, [:visitor, :member])
  grant_access(Link.SurveyTools.SurveyTool, [:owner])

  grant_actions(LinkWeb.DashboardController, %{
    index: [:member]
  })

  grant_actions(LinkWeb.FakeSurveyController, %{
    index: [:visitor, :member]
  })

  grant_actions(LinkWeb.SessionController, %{
    new: [:visitor]
  })

  grant_actions(LinkWeb.RegistrationController, %{
    new: [:visitor]
  })

  grant_actions(LinkWeb.LanguageSwitchController, %{
    index: [:visitor, :member]
  })

  grant_actions(LinkWeb.UserProfileController, %{
    edit: [:member],
    update: [:member]
  })

  grant_actions(LinkWeb.StudyController, %{
    index: [:visitor, :member],
    show: [:visitor, :member],
    new: [:researcher],
    create: [:researcher],
    edit: [:owner],
    update: [:owner],
    delete: [:owner]
  })

  grant_actions(LinkWeb.Studies.PermissionsController, %{
    show: [:owner],
    change: [:owner],
    create: [:owner]
  })

  grant_actions(LinkWeb.ParticipantController, %{
    index: [:owner],
    show: [:owner, :participant],
    new: [:member],
    create: [:member],
    edit: [:owner],
    update: [:owner],
    delete: [:owner]
  })

  grant_actions(LinkWeb.SurveyToolController, %{
    index: [:owner],
    show: [:owner, :participant],
    new: [:owner],
    create: [:owner],
    edit: [:owner],
    update: [:owner],
    delete: [:owner]
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
    roles =
      [:member | if(Users.get_profile(user).researcher, do: [:researcher], else: [])]
      |> MapSet.new()

    %Principal{id: user.id, roles: roles}
  end

  def assign_role!(%Link.Users.User{} = user, entity, role) do
    user |> principal() |> assign_role!(entity, role)
  end

  def can?(%Plug.Conn{} = conn, entity, module, action) do
    conn |> principal() |> can?(entity, module, action)
  end
end
