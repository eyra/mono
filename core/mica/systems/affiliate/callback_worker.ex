defmodule Systems.Affiliate.CallbackWorker do
  @moduledoc """
  Sends an event to the affiliate's callback URL (`Systems.Affiliate.Public.queue_event/3`).

  The job is inserted in the transaction that records the event, so it runs only
  after that transaction commits and not at all when it rolls back. The
  researcher's server is called outside the transaction and outside the
  participant's process. A callback is sent once, as before: a failed one is not
  retried.
  """
  use Oban.Worker, queue: :affiliate_callback, max_attempts: 1

  alias Systems.Account
  alias Systems.Affiliate

  def new_event(%Affiliate.Model{id: affiliate_id}, %{} = event, %Account.User{id: user_id}) do
    new(%{affiliate_id: affiliate_id, event: event, user_id: user_id})
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"affiliate_id" => affiliate_id, "event" => event, "user_id" => user_id}
      }) do
    case Affiliate.Public.deliver_event(affiliate_id, atomize_keys(event), user_id) do
      {:ok, _status} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  # The event's keys were atoms when it was queued; as atoms again they keep
  # their place in the callback URL's query.
  defp atomize_keys(event) do
    Map.new(event, fn {key, value} -> {String.to_existing_atom(key), value} end)
  end
end
