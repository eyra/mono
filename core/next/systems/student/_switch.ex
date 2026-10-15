defmodule Systems.Student.Switch do
  use Frameworks.Signal.Handler

  alias Systems.{
    Student
  }

  alias Systems.Account

  @impl true
  def intercept(:features_updated, %{features: features, features_changeset: features_changeset}) do
    with %{user_id: user_id, study_program_codes: old_codes} <- features,
         %{changes: %{study_program_codes: new_codes}} <- features_changeset do
      user = Account.Public.get_user!(user_id)
      Student.Public.handle_features_updated(user, old_codes, new_codes)
    end

    :ok
  end
end
