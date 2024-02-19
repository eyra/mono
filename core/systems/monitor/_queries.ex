defmodule Systems.Monitor.Queries do
  # import Frameworks.Utility.Query, only: [build: 3]
  import Ecto.Query

  alias Core.Repo
  alias Ecto.Multi
  alias Systems.Monitor

  def upsert_event([_ | _] = identifier, value) do
    Multi.new()
    |> upsert_event(identifier, value)
    |> Repo.transaction()
  end

  def upsert_event(%Multi{} = multi, [_ | _] = identifier, value) do
    Multi.insert(
      multi,
      :metric,
      %Monitor.EventModel{
        identifier: identifier,
        value: value
      }
    )
  end

  def clear(event) do
    event_query()
    |> where([event: event], event.identifier == ^event)
    |> Repo.delete_all()
  end

  def event_query() do
    from(Monitor.EventModel, as: :event)
  end

  def event_query([_ | _] = event_template) do
    event_query()
    |> where([event: event], fragment("?::text[] @> ?", event.identifier, ^event_template))
  end

  def count(event_template) do
    event_query(event_template)
    |> select([event: event], count(event.id))
    |> Repo.one()
  end

  def unique([_ | _] = event_template) do
    event_query(event_template)
    |> select([event: event], count(event.identifier, :distinct))
    |> Repo.one()
  end

  def sum([_ | _] = event_template) do
    result =
      event_query(event_template)
      |> select([event: event], sum(event.value))
      |> Repo.one()

    case result do
      nil -> 0
      value -> value
    end
  end
end
