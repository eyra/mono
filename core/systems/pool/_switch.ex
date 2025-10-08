defmodule Systems.Pool.Switch do
  use Frameworks.Signal.Handler
  require Logger

  alias Systems.Pool
  alias Systems.Account
  alias Systems.Pool.AccountPostActionHandler
  alias Systems.NextAction
  alias Systems.Account.NextActions.FillinCharacteristics
  alias Systems.Monitor

  @impl true
  def intercept(
        {:criteria, :updated} = signal,
        %{criteria: %{submission_id: submission_id}} = message
      ) do
    submission = Pool.Public.get_submission!(submission_id)
    dispatch!({:submission, signal}, Map.merge(message, %{submission: submission}))
    :ok
  end

  @impl true
  def intercept(
        {:submission, _} = signal,
        %{submission: submission, from_pid: from_pid} = message
      ) do
    update_page(Pool.SubmissionPage, submission, from_pid)
    pool = Pool.Public.get_by_submission!(submission)
    dispatch!({:pool, signal}, Map.merge(message, %{pool: pool}))
    :ok
  end

  @impl true
  def intercept({:pool, _}, %{pool: pool, from_pid: from_pid}) do
    update_page(Pool.DetailPage, pool, from_pid)
    :ok
  end

  @impl true
  def intercept({:account, :post_signin}, %{user: %Account.User{} = user, action: action}) do
    AccountPostActionHandler.handle(user, action)
    :ok
  end

  @impl true
  def intercept({:account, :post_signup}, %{user: %Account.User{} = user, action: action}) do
    AccountPostActionHandler.handle(user, action)
    handle_fillin_characteristics_next_action(%{user_id: user.id})
    :ok
  end

  @impl true
  def intercept(:features_updated, %{features: features}) do
    Monitor.Public.log({features, :updated, features.user_id})
    handle_fillin_characteristics_next_action(%{user_id: features.user_id})
    :ok
  end

  defp update_page(page, %{id: id} = model, from_pid) do
    dispatch!({:page, page}, %{id: id, model: model, from_pid: from_pid})
  end

  defp handle_fillin_characteristics_next_action(%{user_id: user_id}) do
    user = Account.Public.get_user!(user_id)

    if participant?(user) do
      features = Account.Public.get_features(user)

      if features_complete?(features) do
        NextAction.Public.clear_next_action(user, FillinCharacteristics)
      else
        NextAction.Public.create_next_action(user, FillinCharacteristics)
      end
    end
  end

  defp participant?(user) do
    Pool.Public.list_by_participant(user) != []
  end

  # Check if features are considered complete
  # For now, we consider features complete if both gender and birth_year are filled
  defp features_complete?(%{gender: gender, birth_year: birth_year}) do
    gender != nil && birth_year != nil
  end

  defp features_complete?(_), do: false
end
