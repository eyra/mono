defmodule Systems.Monitor.Factories do
  @moduledoc false
  alias Core.Factories
  alias Systems.Account
  alias Systems.Assignment

  def create_monitor_event_consent_declined(%Assignment.Model{id: assignment_id}, user_ref) do
    user_id = Account.User.user_id(user_ref)

    Factories.insert!(:monitor_event, %{
      identifier: ["assignment=#{assignment_id}", "topic=declined", "user=#{user_id}"]
    })
  end
end
