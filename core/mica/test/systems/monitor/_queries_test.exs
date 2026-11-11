defmodule Systems.Monitor.QueriesTest do
  use Mica.DataCase

  import Ecto.Query

  alias Ecto.Adapters.SQL
  alias Mica.Repo
  alias Systems.Monitor

  # The test table is too small for the planner to prefer an index on its own.
  setup do
    Repo.query!("SET LOCAL enable_seqscan = off")
    :ok
  end

  describe "event_query/1" do
    test "count matches through the identifier index" do
      plan =
        Monitor.Queries.event_query(["assignment=1", "topic=finished", "user=1"])
        |> select([event: event], count(event.id))
        |> explain()

      assert plan =~ "monitor_events_identifier_text_index"
    end

    test "unique matches through the identifier index" do
      plan =
        Monitor.Queries.event_query(["assignment=1", "topic=started"])
        |> select([event: event], count(event.identifier, :distinct))
        |> explain()

      assert plan =~ "monitor_events_identifier_text_index"
    end

    test "sum matches through the identifier index" do
      plan =
        Monitor.Queries.event_query(["storage_endpoint=1", "topic=files"])
        |> select([event: event], sum(event.value))
        |> explain()

      assert plan =~ "monitor_events_identifier_text_index"
    end
  end

  defp explain(query), do: SQL.explain(Repo, :all, query)
end
