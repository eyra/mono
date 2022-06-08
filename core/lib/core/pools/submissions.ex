defmodule Core.Pools.Submissions do
  @moduledoc """
  """
  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Ecto.Changeset
  alias Core.Repo
  alias Core.Pools.{Submission, Criteria}
  alias Core.Accounts

  alias Frameworks.Signal

  alias Systems.{
    Promotion,
    NextAction
  }

  def list do
    Repo.all(Submission)
  end

  def list(status, preload \\ [:criteria, :promotion]) do
    from(submission in Submission,
      where: submission.status == ^status,
      preload: ^preload
    )
    |> Repo.all()
  end

  def get!(term, preload \\ [:criteria, :promotion])

  def get!(%Promotion.Model{} = promotion, preload) do
    from(submission in Submission,
      where: submission.promotion_id == ^promotion.id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def get!(id, preload) do
    from(submission in Submission, preload: ^preload)
    |> Repo.get!(id)
  end

  def update(%Submission{} = _submission, %Changeset{} = changeset) do
    result =
      Multi.new()
      |> Multi.update(:submission, changeset)
      |> Repo.transaction()

    with {:ok, %{submission: submission}} <- result do
      Signal.Context.dispatch!(:submission_updated, submission)
      {:ok, notify_when_submitted(submission, changeset)}
    end

    result
  end

  def update(%Submission{} = submission, attrs) do
    changeset = Submission.changeset(submission, attrs)
    __MODULE__.update(submission, changeset)
  end

  def update(%Criteria{} = _criteria, %Changeset{} = changeset) do
    result =
      Multi.new()
      |> Multi.update(:criteria, changeset)
      |> Repo.transaction()

    with {:ok, %{criteria: criteria}} <- result do
      Signal.Context.dispatch!(:criteria_updated, criteria)
    end

    result
  end

  def create(%{} = attrs, promotion, pool) do
    submission_changeset =
      %Submission{}
      |> Submission.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:promotion, promotion)
      |> Ecto.Changeset.put_assoc(:pool, pool)

    criteria_changeset =
      %Criteria{}
      |> Criteria.changeset(%{study_program_codes: [:bk_1, :bk_1_h, :iba_1, :iba_1_h]})
      |> Ecto.Changeset.put_assoc(:submission, submission_changeset)

    criteria = Repo.insert!(criteria_changeset)

    {:ok, criteria.submission}
  end

  def copy(%Submission{} = submission, %Promotion.Model{} = promotion, pool) do
    attrs =
      submission
      |> Map.from_struct()
      |> Map.put(:status, :idle)
      |> Map.put(:reward_value, nil)

    %Submission{}
    |> Submission.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:promotion, promotion)
    |> Ecto.Changeset.put_assoc(:pool, pool)
    |> Repo.insert!()
  end

  def copy(%Criteria{} = criteria, %Submission{} = submission) do
    %Criteria{}
    |> Criteria.changeset(Map.from_struct(criteria))
    |> Ecto.Changeset.put_assoc(:submission, submission)
    |> Repo.insert!()
  end

  defp notify_when_submitted(%Submission{} = submission, %Ecto.Changeset{} = changeset) do
    if Ecto.Changeset.get_change(changeset, :status) === :submitted do
      for user <- Accounts.list_pool_admins() do
        NextAction.Context.create_next_action(user, Core.Pools.ReviewSubmission)
      end
    end

    submission
  end
end

defimpl Core.Persister, for: Core.Pools.Submission do
  def save(submission, changeset) do
    case Core.Pools.Submissions.update(submission, changeset) do
      {:ok, %{submission: submission}} -> {:ok, submission}
      _ -> {:error, changeset}
    end
  end
end

defimpl Core.Persister, for: Core.Pools.Criteria do
  def save(criteria, changeset) do
    case Core.Pools.Submissions.update(criteria, changeset) do
      {:ok, %{criteria: criteria}} -> {:ok, criteria}
      _ -> {:error, changeset}
    end
  end
end
