defmodule Systems.Assignment.AffiliateCallbackTest do
  # Mocks the URL check globally.
  use Mica.DataCase, async: false
  use Oban.Testing, repo: Mica.Repo

  import ExUnit.CaptureLog
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
      send(test, {:callback_query, conn.query_string})
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

    %{
      affiliate: affiliate,
      bypass: bypass,
      crew: crew,
      assignment: assignment,
      user: user,
      member: member,
      task: task
    }
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

  describe "the callback URL" do
    test "is built as when the event was sent directly, also when its query has the event's key",
         %{affiliate: affiliate, assignment: assignment, user: user} do
      callback_url = affiliate.callback_url <> "?progress=entered"
      Repo.update!(Ecto.Changeset.change(affiliate, callback_url: callback_url))

      {:ok, direct_url} =
        Affiliate.Private.merge(callback_url, nil, %{progress: :assignment_declined})

      assert {:ok, _} = Assignment.Public.expire_member(assignment, user)
      assert %{success: 1} = Oban.drain_queue(queue: :affiliate_callback)

      assert_received {:callback_query, query}
      assert query == URI.parse(direct_url).query
    end
  end

  describe "queueing no callback" do
    test "for a participant without an affiliate identity", %{
      assignment: assignment,
      crew: crew
    } do
      user = Factories.insert!(:member)
      Crew.Factories.create_member(crew, user)

      assert {:ok, _} = Assignment.Public.expire_member(assignment, user)

      refute_enqueued(worker: Affiliate.CallbackWorker)
    end

    test "for an affiliate without a callback URL", %{
      affiliate: affiliate,
      assignment: assignment,
      user: user
    } do
      Repo.update!(Ecto.Changeset.change(affiliate, callback_url: ""))

      assert {:ok, _} = Assignment.Public.expire_member(assignment, user)

      refute_enqueued(worker: Affiliate.CallbackWorker)
    end
  end

  describe "a failed callback" do
    test "is logged and completes the job when the server is down", %{
      bypass: bypass,
      assignment: assignment,
      user: user
    } do
      assert {:ok, _} = Assignment.Public.expire_member(assignment, user)
      Bypass.down(bypass)

      log =
        capture_log(fn ->
          assert %{success: 1, failure: 0, discard: 0} =
                   Oban.drain_queue(queue: :affiliate_callback)
        end)

      assert log =~ "Error calling callback url"
    end

    test "is logged and completes the job when the server doesn't answer in time", %{
      affiliate: affiliate,
      assignment: assignment,
      user: user
    } do
      initial_limits = Application.get_env(:mica, :affiliate_callback)
      Application.put_env(:mica, :affiliate_callback, deadline: 100)

      # The kernel accepts the connection; nobody answers the request.
      {:ok, listener} = :gen_tcp.listen(0, [:binary, active: false])
      {:ok, port} = :inet.port(listener)

      on_exit(fn ->
        :gen_tcp.close(listener)

        if initial_limits,
          do: Application.put_env(:mica, :affiliate_callback, initial_limits),
          else: Application.delete_env(:mica, :affiliate_callback)
      end)

      callback_url = "http://localhost:#{port}/callback"
      Repo.update!(Ecto.Changeset.change(affiliate, callback_url: callback_url))

      assert {:ok, _} = Assignment.Public.expire_member(assignment, user)

      log =
        capture_log(fn ->
          assert %{success: 1, failure: 0, discard: 0} =
                   Oban.drain_queue(queue: :affiliate_callback)
        end)

      assert log =~ "Error calling callback url"
      assert log =~ "deadline_exceeded"
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
