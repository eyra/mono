defmodule Systems.Affiliate.CallbackWorker do
  @moduledoc """
  Sends an event to the affiliate's callback URL (`Systems.Affiliate.Public.queue_event/3`).

  The job is inserted in the transaction that records the event, so it runs only
  after that transaction commits and not at all when it rolls back. The
  researcher's server is called outside the transaction and outside the
  participant's process.

  A participant's events reach the affiliate in the order they were queued, as
  when they were sent from the participant's process: a job snoozes while an
  earlier job for the same affiliate and user is still waiting or running. A
  snoozing job gives its slot in the queue back, so other affiliates'
  callbacks don't wait for it.

  A callback is sent once, as before: a failed one is logged
  (`Systems.Affiliate.Private.callback/1`) and not retried. The researcher's
  server being down is not an error of ours, so the job completes.
  """
  use Oban.Worker, queue: :affiliate_callback, max_attempts: 1

  import Ecto.Query, only: [from: 2]

  alias Mica.Repo
  alias Systems.Account
  alias Systems.Affiliate

  @snooze_seconds 1
  @pending_states ~w(available scheduled executing retryable)

  def new_event(%Affiliate.Model{id: affiliate_id}, %{} = event, %Account.User{id: user_id}) do
    new(%{affiliate_id: affiliate_id, event: event, user_id: user_id})
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{"affiliate_id" => affiliate_id, "event" => event, "user_id" => user_id}
      }) do
    if earlier_job_pending?(id, affiliate_id, user_id) do
      {:snooze, @snooze_seconds}
    else
      Affiliate.Public.deliver_event(affiliate_id, atomize_keys(event), user_id)
      :ok
    end
  end

  defp earlier_job_pending?(id, affiliate_id, user_id) do
    participant = %{"affiliate_id" => affiliate_id, "user_id" => user_id}

    from(j in Oban.Job,
      where:
        j.worker == ^inspect(__MODULE__) and j.id < ^id and j.state in @pending_states and
          fragment("? @> ?", j.args, type(^participant, :map))
    )
    |> Repo.exists?()
  end

  # The event's keys were atoms when it was queued; as atoms again they keep
  # their place in the callback URL's query.
  defp atomize_keys(event) do
    Map.new(event, fn {key, value} -> {String.to_existing_atom(key), value} end)
  end
end
