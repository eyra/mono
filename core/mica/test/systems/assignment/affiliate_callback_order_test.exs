defmodule Systems.Assignment.AffiliateCallbackOrderTest do
  # Mocks the URL check globally and runs its own Oban instance.
  use Mica.DataCase, async: false

  import Mock

  @moduletag :capture_log

  alias Frameworks.Utility.OutboundUrl
  alias Systems.Assignment
  alias Systems.Crew

  # The callback server is local, which the URL check refuses. The request of
  # the first event takes this much longer to reach it.
  @first_delay_ms 500

  setup_with_mocks([
    {OutboundUrl, [:passthrough],
     [
       request: fn method, url, headers, body, options ->
         if url =~ "progress=task_finished", do: Process.sleep(@first_delay_ms)
         :hackney.request(method, url, headers, body, options)
       end
     ]}
  ]) do
    :ok
  end

  setup do
    test = self()
    bypass = Bypass.open()

    Bypass.stub(bypass, "GET", "/callback", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      send(test, {:callback, conn.query_params["progress"]})
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
      Factories.insert!(:assignment, %{affiliate: affiliate, workflow: workflow})

    %{user: user} = Factories.insert!(:affiliate_user, %{affiliate: affiliate, identifier: "p1"})
    member = Crew.Factories.create_member(crew, user)
    task = Crew.Factories.create_task(crew, member, ["item=#{item.id}", "member=#{member.id}"])

    %{task: task}
  end

  test "a participant's callbacks reach the server in the order they were queued", %{
    task: task
  } do
    # Queues task_finished, then assignment_finished.
    assert {:ok, _} = Crew.Public.complete_task(task)

    start_supervised!(
      {Oban,
       name: __MODULE__.Oban,
       repo: Mica.Repo,
       queues: [affiliate_callback: 10],
       plugins: [],
       notifier: Oban.Notifiers.Isolated,
       peer: Oban.Peers.Isolated,
       stager: [interval: 100]}
    )

    assert ["task_finished", "assignment_finished"] == [next_callback(), next_callback()]

    stop_supervised!(__MODULE__.Oban)
  end

  defp next_callback do
    receive do
      {:callback, progress} -> progress
    after
      5_000 -> flunk("no callback arrived")
    end
  end
end
