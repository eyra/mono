defmodule Systems.Assignment.Queries do
  require Ecto.Query
  require Frameworks.Utility.Query

  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Account
  alias Systems.Content
  alias Systems.Consent
  alias Systems.Project

  def assignment_query() do
    from(Assignment.Model, as: :assignment)
  end

  def assignment_query(special) when is_atom(special) do
    build(assignment_query(), :assignment, [
      special == ^special
    ])
  end

  def assignment_query(%Content.PageModel{id: page_id}) do
    build(assignment_query(), :assignment,
      page_refs: [
        page: [
          id == ^page_id
        ]
      ]
    )
  end

  def assignment_query(%Account.User{id: user_id}, :participant) do
    build(assignment_query(), :assignment,
      crew: [
        auth_node: [
          role_assignments: [
            role in [:participant, :tester],
            principal_id == ^user_id
          ]
        ]
      ]
    )
  end

  def assignment_query(%Project.NodeModel{id: project_node_id}, special) do
    build(assignment_query(special), :assignment,
      project_item: [
        node: [
          id == ^project_node_id
        ]
      ]
    )
  end

  def assignment_ids(selector, term) do
    assignment_query(selector, term)
    |> select([assignment: a], a.id)
    |> distinct(true)
  end

  def participant_query() do
    from(Crew.MemberModel, as: :member)
  end

  def participant_query(%Assignment.Model{crew: %{id: id, auth_node_id: auth_node_id}}) do
    build(participant_query(), :member, [crew_id == ^id, user: [id != nil]])
    |> join(:left, [user: u], e in ExternalSignIn.User, on: u.id == e.user_id, as: :external_user)
    |> join(:inner, [user: u], ra in Core.Authorization.RoleAssignment,
      on: ra.principal_id == u.id,
      as: :role_assignment
    )
    |> where([role_assignment: ra], ra.role == :participant)
    |> where([role_assignment: ra], ra.node_id == ^auth_node_id)
    |> select([member: m, user: u, external_user: e], %{
      user_id: u.id,
      member_id: m.id,
      public_id: m.public_id,
      external_id: e.external_id
    })
  end

  def signature_query() do
    from(Consent.SignatureModel, as: :signature)
  end

  def signature_query(%Assignment.Model{consent_agreement_id: consent_agreement_id})
      when not is_nil(consent_agreement_id) do
    build(signature_query(), :signature,
      revision: [
        agreement: [
          id == ^consent_agreement_id
        ]
      ]
    )
    |> select([signature: a], a.user_id)
  end
end
