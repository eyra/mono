defmodule Systems.License.TellWorker do
  @moduledoc """
  Tells a user how their license stands after support saved it
  (`License.Public.tell_current/3`). `License.Public.save/4` inserts the job in
  the same transaction as the change, so the tell is never lost after a save,
  nor done for a save that was rolled back. Running it again tells nothing new.
  """
  use Oban.Worker,
    queue: :default,
    max_attempts: 5

  alias Mica.Repo
  alias Systems.Account.User
  alias Systems.License

  @doc "The job that tells `user` about `license` after `by` saved it."
  def new_tell(%User{id: user_id}, license, %User{id: by_id}),
    do: new(%{"user_id" => user_id, "license" => to_string(license), "by_id" => by_id})

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id, "license" => license, "by_id" => by_id}}) do
    case {Repo.get(User, user_id), license(license)} do
      {%User{} = user, license} when not is_nil(license) ->
        License.Public.tell_current(user, license, Repo.get(User, by_id))
        :ok

      # The user deleted their account, or a release no longer has the license.
      _ ->
        :ok
    end
  end

  defp license(name), do: Enum.find(License.Model.licenses(), &(to_string(&1) == name))
end
