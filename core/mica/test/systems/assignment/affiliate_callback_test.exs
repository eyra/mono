defmodule Systems.Assignment.AffiliateCallbackTest do
  # Mocks the URL check globally.
  use Mica.DataCase, async: false
  use Oban.Testing, repo: Mica.Repo

  import Mock

  @moduletag :capture_log

  alias Ecto.Multi
  alias Frameworks.Utility.OutboundUrl
  alias Systems.Affiliate
  alias Systems.Assignment
  alias Systems.Crew

  # The callback server answers after this long.
  @slow_ms 300

  # The callback server is local, which the URL check refuses.
  setup_with_mocks([
    {OutboundUrl, [:passthrough], [request: &:hackney.request/5]}
  ]) do
    :ok
  end

  setup do
    test = self()
    bypass = Bypass.open()

    Bypass.stub(bypass, "GET", "/callback", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      send(test, {:callback, conn.query_params})
      Process.sleep(@slow_ms)
      Plug.Conn.resp(conn, 200, "ok")
    end)

    affiliate =
      Factories.insert!(:affiliate, %{
        callback_url: "http://localhost:#{bypass.port}/callback",
        redirect_url: nil
      })

    workflow = Assignment.Factories.create_workflow()

    tool_ref =
      Factories.build(:auth_node)
      |> Assignment.Factories.create_tool()
      |> Assignment.Factories.create_tool_ref()

    item = Assignment.Factories.create_workflow_item(workflow, tool_ref, "Fill in survey")

    %{crew: crew} =
      assignment = Factories.insert!(:assignment, %{affiliate: affiliate, workflow: workflow})

    %{user: user} = Factories.insert!(:affiliate_user, %{affiliate: affiliate, identifier: "p1"})
    member = Crew.Factories.create_member(crew, user)
    task = Crew.Factories.create_task(crew, member, ["item=#{item.id}", "member=#{member.id}"])

    %{assignment: assignment, user: user, member: member, task: task}
  end

  describe "expiring a member" do
    test "commits without calling back, then the job calls back", %{
      assignment: assignment,
      user: user,
      member: member
    } do
      assert {:ok, _} = Assignment.Public.expire_member(assignment, user)

      refute_received {:callback, _}
      assert %{expired: true} = Crew.Public.get_member!(member.id)

      assert_calls_back([%{"progress" => "assignment_declined"}])
    end

    test "sends no callback when the transaction rolls back", %{
      assignment: assignment,
      user: user,
      member: member
    } do
      assert_rolls_back(fn -> Assignment.Public.expire_member(assignment, user) end)

      assert %{expired: false} = Crew.Public.get_member!(member.id)
    end
  end

  describe "starting a crew task" do
    test "commits without calling back, then the job calls back", %{task: task} do
      assert {:ok, _} = Crew.Public.start_task(task)

      refute_received {:callback, _}
      assert %{started_at: %NaiveDateTime{}} = Crew.Public.get_task!(task.id)

      assert_calls_back([
        %{"progress" => "task_started", "task_nr" => "1", "task_slug" => "fill_in_survey"}
      ])
    end

    test "sends no callback when the transaction rolls back", %{task: task} do
      assert_rolls_back(fn -> Crew.Public.start_task(task) end)

      assert %{started_at: nil} = Crew.Public.get_task!(task.id)
    end
  end

  describe "completing a crew task" do
    test "commits without calling back, then the job calls back", %{task: task} do
      assert {:ok, _} = Crew.Public.complete_task(task)

      refute_received {:callback, _}
      assert %{status: :completed} = Crew.Public.get_task!(task.id)

      assert_calls_back([
        %{"progress" => "task_finished", "task_nr" => "1", "task_slug" => "fill_in_survey"},
        %{"progress" => "assignment_finished"}
      ])
    end

    test "sends no callback when the transaction rolls back", %{task: task} do
      assert_rolls_back(fn -> Crew.Public.complete_task(task) end)

      assert %{status: :pending} = Crew.Public.get_task!(task.id)
    end
  end

  describe "accepting a member" do
    test "returns without calling back, then the job calls back", %{
      assignment: assignment,
      user: user
    } do
      Assignment.Public.accept_member(assignment, user)

      refute_received {:callback, _}

      assert_calls_back([%{"progress" => "assignment_accepted"}])
    end
  end

  defp assert_calls_back(expected) do
    assert_enqueued(worker: Affiliate.CallbackWorker)

    count = length(expected)
    assert %{success: ^count, failure: 0} = Oban.drain_queue(queue: :affiliate_callback)

    for params <- expected do
      assert_received {:callback, ^params}
    end

    refute_received {:callback, _}
  end

  # Runs `action` in a transaction that a later step rolls back.
  defp assert_rolls_back(action) do
    assert {:error, :later_step, :failed, _} =
             Multi.new()
             |> Multi.run(:action, fn _, _ -> {:ok, action.()} end)
             |> Multi.run(:later_step, fn _, _ -> {:error, :failed} end)
             |> Repo.commit()

    refute_received {:callback, _}
    refute_enqueued(worker: Affiliate.CallbackWorker)
    assert %{success: 0, failure: 0} = Oban.drain_queue(queue: :affiliate_callback)
    refute_received {:callback, _}
  end
end
