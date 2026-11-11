defmodule Systems.Assignment.Factories do
  import Ecto.Query, only: [from: 2]

  alias Mica.Factories

  alias Systems.Alliance
  alias Systems.Fund

  def create_info(duration, subject_count) do
    Factories.insert!(
      :assignment_info,
      %{
        subject_count: subject_count,
        duration: duration,
        language: :en,
        devices: [:desktop]
      }
    )
  end

  def create_tool(auth_node) do
    Factories.insert!(:alliance_tool, %{
      url: "https://eyra.co/alliance/123",
      auth_node: auth_node,
      director: :assignment
    })
  end

  def create_tool_ref(%Alliance.ToolModel{} = tool) do
    Factories.insert!(:tool_ref, %{
      alliance_tool: tool
    })
  end

  def create_workflow() do
    Factories.insert!(:workflow, %{})
  end

  def create_workflow_item(workflow, tool_ref, title \\ "Test Task", position \\ 0) do
    Factories.insert!(:workflow_item, %{
      workflow: workflow,
      tool_ref: tool_ref,
      title: title,
      position: position
    })
  end

  def add_task(%{workflow: %{items: items} = workflow} = assignment) do
    tool = create_tool(Factories.insert!(:auth_node))

    create_workflow_item(
      workflow,
      create_tool_ref(tool),
      "Task #{length(items) + 1}",
      length(items)
    )

    assignment
    |> Mica.Repo.preload([workflow: Systems.Workflow.Model.preload_graph(:down)], force: true)
  end

  def create_assignment(info, consent_agreement, workflow, auth_node, %Fund.Model{} = fund) do
    crew = Factories.insert!(:crew)

    Factories.insert!(:assignment, %{
      info: info,
      consent_agreement: consent_agreement,
      workflow: workflow,
      crew: crew,
      auth_node: auth_node,
      fund: fund
    })
  end

  def create_assignment(info, consent_agreement, workflow, auth_node, status)
      when is_atom(status) do
    crew = Factories.insert!(:crew)

    Factories.insert!(:assignment, %{
      info: info,
      consent_agreement: consent_agreement,
      workflow: workflow,
      crew: crew,
      auth_node: auth_node,
      special: :data_donation,
      status: status
    })
  end

  def create_assignment(duration, subject_count, status \\ :online) when is_integer(duration) do
    assignment_auth_node = Factories.build(:auth_node)
    tool_auth_node = Factories.build(:auth_node, %{parent: assignment_auth_node})

    info = create_info(Integer.to_string(duration), subject_count)
    tool = create_tool(tool_auth_node)
    tool_ref = create_tool_ref(tool)
    workflow = create_workflow()
    _workflow_item = create_workflow_item(workflow, tool_ref)
    consent_agreement = Factories.insert!(:consent_agreement)

    create_assignment(info, consent_agreement, workflow, assignment_auth_node, status)
  end

  def build_assignment() do
    Factories.insert!(:assignment, %{})
  end

  def create_base_assignment do
    create_full_assignment(nil)
  end

  def create_assignment_with_consent do
    consent_agreement = Factories.insert!(:consent_agreement)
    _revision = Factories.insert!(:consent_revision, %{agreement: consent_agreement})
    create_full_assignment(consent_agreement)
  end

  defp create_full_assignment(consent_agreement) do
    auth_node = Factories.insert!(:auth_node)
    tool_auth_node = Factories.insert!(:auth_node, %{parent: auth_node})

    tool = create_tool(tool_auth_node)
    tool_ref = create_tool_ref(tool)
    workflow = create_workflow()
    _workflow_item = create_workflow_item(workflow, tool_ref)
    info = create_info("10", 100)

    assignment =
      create_assignment(
        info,
        consent_agreement,
        workflow,
        auth_node,
        :online
      )

    assignment |> Mica.Repo.preload(Systems.Assignment.Model.preload_graph(:down))
  end

  @doc """
  Switches consent as the researcher does in the settings: `:on`, or `:off`
  through the confirmation modal. Returns the reloaded assignment.
  """
  def switch_consent(%Systems.Assignment.Model{} = assignment, status) do
    {:noreply, _} = handle_gdpr_switch(assignment, status)

    Systems.Assignment.Public.get!(
      assignment.id,
      Systems.Assignment.Model.preload_graph(:down)
    )
  end

  defp handle_gdpr_switch(assignment, :on) do
    Systems.Assignment.GdprForm.handle_event("update", %{status: :on}, gdpr_socket(assignment))
  end

  defp handle_gdpr_switch(assignment, :off) do
    Systems.Assignment.GdprForm.handle_event(
      "confirmed",
      %{source: %{name: :confirmation_modal}},
      gdpr_socket(assignment)
    )
  end

  @doc """
  Moves the creation of the assignment's agreement `seconds` into the past, so
  consent has been on since then. Returns the reloaded assignment.
  """
  def consent_since(%{consent_agreement_id: agreement_id} = assignment, seconds) do
    from(a in Systems.Consent.AgreementModel, where: a.id == ^agreement_id)
    |> Mica.Repo.update_all(set: [inserted_at: seconds_ago(seconds)])

    reload(assignment)
  end

  @doc """
  Moves the participant's join `seconds` into the past.
  """
  def joined_since(%{crew_id: crew_id}, %{id: user_id}, seconds) do
    from(m in Systems.Crew.MemberModel, where: m.crew_id == ^crew_id and m.user_id == ^user_id)
    |> Mica.Repo.update_all(set: [inserted_at: seconds_ago(seconds)])
  end

  @doc """
  Switches consent on as older code does: it only links a new agreement, created
  `seconds` ago. Returns the reloaded assignment.
  """
  def switch_consent_on_as_old_code(%{id: id} = assignment, seconds) do
    agreement = Factories.insert!(:consent_agreement, %{inserted_at: seconds_ago(seconds)})
    _revision = Factories.insert!(:consent_revision, %{agreement: agreement})

    from(a in "assignments", where: a.id == ^id)
    |> Mica.Repo.update_all(set: [consent_agreement_id: agreement.id])

    reload(assignment)
  end

  defp reload(%{id: id}) do
    Systems.Assignment.Public.get!(id, Systems.Assignment.Model.preload_graph(:down))
  end

  defp seconds_ago(seconds) do
    NaiveDateTime.utc_now() |> NaiveDateTime.add(-seconds) |> NaiveDateTime.truncate(:second)
  end

  def gdpr_socket(assignment) do
    %Phoenix.LiveView.Socket{
      assigns: %{__changed__: %{}, entity: assignment, fabric: Fabric.Factories.create_fabric()}
    }
  end

  def add_participant(%{} = assignment, user) do
    Systems.Assignment.Public.add_participant!(assignment, user)
    assignment |> Mica.Repo.preload([:crew], force: true)
  end

  def create_assignment_with_affiliate(redirect_url \\ nil, platform_name \\ nil, attrs \\ %{}) do
    affiliate =
      Factories.insert!(:affiliate, %{redirect_url: redirect_url, platform_name: platform_name})

    auth_node = Factories.insert!(:auth_node)
    tool_auth_node = Factories.insert!(:auth_node, %{parent: auth_node})

    tool = create_tool(tool_auth_node)
    tool_ref = create_tool_ref(tool)
    workflow = create_workflow()
    _workflow_item = create_workflow_item(workflow, tool_ref)
    info = create_info("10", 100)
    crew = Factories.insert!(:crew)

    assignment =
      Factories.insert!(
        :assignment,
        Map.merge(
          %{
            info: info,
            consent_agreement: nil,
            workflow: workflow,
            crew: crew,
            auth_node: auth_node,
            affiliate: affiliate,
            status: :online
          },
          attrs
        )
      )

    assignment |> Mica.Repo.preload(Systems.Assignment.Model.preload_graph(:down))
  end

  def create_assignment_with_consent_and_affiliate(redirect_url \\ nil, platform_name \\ nil) do
    affiliate =
      Factories.insert!(:affiliate, %{redirect_url: redirect_url, platform_name: platform_name})

    consent_agreement = Factories.insert!(:consent_agreement)
    _revision = Factories.insert!(:consent_revision, %{agreement: consent_agreement})

    auth_node = Factories.insert!(:auth_node)
    tool_auth_node = Factories.insert!(:auth_node, %{parent: auth_node})

    tool = create_tool(tool_auth_node)
    tool_ref = create_tool_ref(tool)
    workflow = create_workflow()
    _workflow_item = create_workflow_item(workflow, tool_ref)
    info = create_info("10", 100)
    crew = Factories.insert!(:crew)

    assignment =
      Factories.insert!(:assignment, %{
        info: info,
        consent_agreement: consent_agreement,
        workflow: workflow,
        crew: crew,
        auth_node: auth_node,
        affiliate: affiliate,
        status: :online
      })

    assignment |> Mica.Repo.preload(Systems.Assignment.Model.preload_graph(:down))
  end

  def add_affiliate_user(%{affiliate: affiliate} = assignment, user, identifier \\ "test-123") do
    Factories.insert!(:affiliate_user, %{
      user: user,
      affiliate: affiliate,
      identifier: identifier
    })

    assignment
  end

  def add_tester(%{crew: crew} = assignment, user) do
    # Grant tester role on crew's auth_node to make user a tester
    crew = crew |> Mica.Repo.preload([:auth_node])

    Factories.insert!(:role_assignment, %{
      node: crew.auth_node,
      role: :tester,
      principal_id: user.id
    })

    assignment
  end

  def finish_all_tasks(%{crew: crew, workflow: workflow} = assignment, user) do
    %{items: [item]} = workflow |> Mica.Repo.preload([:items])

    # Get existing member or create new one, ensuring user is preloaded
    crew = crew |> Mica.Repo.preload([:members])

    member =
      case Enum.find(crew.members, fn m -> m.user_id == user.id end) do
        nil -> Systems.Crew.Factories.create_member(crew, user)
        existing_member -> existing_member |> Mica.Repo.preload([:user])
      end

    identifier = Systems.Assignment.Private.task_identifier(assignment, item, member)

    # Create completed task using Factory helper
    Systems.Crew.Factories.create_task(crew, member, identifier, status: :completed)
  end

  def create_questionnaire_assignment(attrs \\ %{}) do
    auth_node = Factories.insert!(:auth_node)
    tool_auth_node = Factories.insert!(:auth_node, %{parent: auth_node})

    tool = create_tool(tool_auth_node)
    tool_ref = create_tool_ref(tool)
    workflow = create_workflow()
    _workflow_item = create_workflow_item(workflow, tool_ref)
    info = create_info("10", 100)
    crew = Factories.insert!(:crew)

    assignment =
      Factories.insert!(
        :assignment,
        Map.merge(
          %{
            info: info,
            consent_agreement: nil,
            workflow: workflow,
            crew: crew,
            auth_node: auth_node,
            special: :questionnaire,
            status: :online
          },
          attrs
        )
      )

    assignment |> Mica.Repo.preload(Systems.Assignment.Model.preload_graph(:down))
  end

  def create_assignment_with_multiple_tasks do
    auth_node = Factories.insert!(:auth_node)
    tool_auth_node = Factories.insert!(:auth_node, %{parent: auth_node})

    tool = create_tool(tool_auth_node)
    tool_ref = create_tool_ref(tool)
    workflow = create_workflow()

    # Create multiple workflow items
    create_workflow_item(workflow, tool_ref, "Task 1", 0)
    create_workflow_item(workflow, tool_ref, "Task 2", 1)

    info = create_info("10", 100)

    assignment =
      create_assignment(
        info,
        nil,
        workflow,
        auth_node,
        :online
      )

    assignment |> Mica.Repo.preload(Systems.Assignment.Model.preload_graph(:down))
  end

  def create_assignment_with_feldspar_tool do
    auth_node = Factories.insert!(:auth_node)
    tool_auth_node = Factories.insert!(:auth_node, %{parent: auth_node})

    feldspar_tool =
      Factories.insert!(:feldspar_tool, %{
        archive_ref: "https://example.com/feldspar-app",
        auth_node: tool_auth_node
      })

    tool_ref = Factories.insert!(:tool_ref, %{feldspar_tool: feldspar_tool})
    workflow = create_workflow()
    create_workflow_item(workflow, tool_ref, "Feldspar Task", 0)

    info = create_info("10", 100)

    assignment =
      create_assignment(
        info,
        nil,
        workflow,
        auth_node,
        :online
      )

    assignment |> Mica.Repo.preload(Systems.Assignment.Model.preload_graph(:down))
  end

  def create_feldspar_assignment_with_affiliate do
    affiliate = Factories.insert!(:affiliate, %{redirect_url: nil, platform_name: nil})

    auth_node = Factories.insert!(:auth_node)
    tool_auth_node = Factories.insert!(:auth_node, %{parent: auth_node})

    feldspar_tool =
      Factories.insert!(:feldspar_tool, %{
        archive_ref: "https://example.com/feldspar-app",
        auth_node: tool_auth_node
      })

    tool_ref = Factories.insert!(:tool_ref, %{feldspar_tool: feldspar_tool})
    workflow = create_workflow()
    create_workflow_item(workflow, tool_ref, "Feldspar Task", 0)

    info = create_info("10", 100)
    crew = Factories.insert!(:crew)

    assignment =
      Factories.insert!(:assignment, %{
        info: info,
        consent_agreement: nil,
        workflow: workflow,
        crew: crew,
        auth_node: auth_node,
        affiliate: affiliate,
        status: :online
      })

    assignment |> Mica.Repo.preload(Systems.Assignment.Model.preload_graph(:down))
  end
end
