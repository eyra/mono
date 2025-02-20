defmodule Systems.Advert.Factories do
  alias CoreWeb.UI.Timestamp

  alias Systems.{
    Assignment,
    Crew
  }

  alias Core.Factories
  use Core, :auth

  def create_advert(
        researcher,
        status,
        subject_count \\ 1,
        budget \\ nil,
        schedule_start \\ nil,
        schedule_end \\ nil
      ) do
    promotion = Factories.insert!(:promotion, %{director: :advert})

    pool = Factories.insert!(:pool, %{name: "test_pool", director: :citizen})

    submission =
      Factories.insert!(:pool_submission, %{
        pool: pool,
        reward_value: 2,
        status: status,
        schedule_start: schedule_start,
        schedule_end: schedule_end
      })

    advert_auth_node = Factories.insert!(:auth_node)
    assignment_auth_node = Factories.insert!(:auth_node, %{parent: advert_auth_node})
    tool_auth_node = Factories.insert!(:auth_node, %{parent: assignment_auth_node})

    tool = Assignment.Factories.create_tool(tool_auth_node)
    tool_ref = Assignment.Factories.create_tool_ref(tool)
    workflow = Assignment.Factories.create_workflow()
    _workflow_item = Assignment.Factories.create_workflow_item(workflow, tool_ref)
    info = Assignment.Factories.create_info("10", subject_count)

    assignment =
      Assignment.Factories.create_assignment(
        info,
        workflow,
        assignment_auth_node,
        budget
      )

    advert =
      Factories.insert!(:advert, %{
        assignment: assignment,
        promotion: promotion,
        submission: submission,
        auth_node: advert_auth_node
      })

    :ok = auth_module().assign_role(researcher, advert, :owner)

    advert
  end

  def create_task(identifier, crew, status, expired, minutes_ago) when is_boolean(expired) do
    user = Core.Factories.insert!(:member, %{creator: false})
    create_task(identifier, user, crew, status, expired, minutes_ago)
  end

  def create_task(identifier, user, crew, status, expired, minutes_ago)
      when is_boolean(expired) do
    expire_at = naive_timestamp(-1)

    member = Crew.Factories.create_member(crew, user)

    Crew.Factories.create_task(crew, member, identifier,
      status: status,
      expired: expired,
      expire_at: expire_at,
      minutes_ago: minutes_ago
    )
  end

  def timestamp(shift_minutes) do
    Timestamp.now()
    |> Timestamp.shift_minutes(shift_minutes)
  end

  def naive_timestamp(shift_minutes) do
    timestamp(shift_minutes)
    |> DateTime.to_naive()
    |> NaiveDateTime.truncate(:second)
  end
end
