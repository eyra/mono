defmodule Systems.Scholar.Switch do
  use Frameworks.Signal.Handler

  alias Systems.{
    Scholar
  }

  alias Core.Accounts

  @impl true
  def dispatch(:features_updated, %{features: features, features_changeset: features_changeset}) do
    with %{user_id: user_id, study_program_codes: old_codes} <- features,
         %{changes: %{study_program_codes: new_codes}} <- features_changeset do
      user = Accounts.get_user!(user_id)
      Scholar.Context.handle_features_updated(user, old_codes, new_codes)
    end
  end
end
