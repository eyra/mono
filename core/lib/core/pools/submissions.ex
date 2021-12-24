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

  def update(%Submission{} = _submisson, %Changeset{} = changeset) do
    with {:ok, %{submisson: submisson}} <-
           Multi.new()
           |> Multi.update(:submisson, changeset)
           |> Repo.transaction() do
      Signal.Context.dispatch!(:submisson_updated, submisson)
      {:ok, notify_when_submitted(submisson, changeset)}
    end
  end

  def update(%Submission{} = submisson, attrs) do
    changeset = Submission.changeset(submisson, attrs)
    __MODULE__.update(submisson, changeset)
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
    %Submission{}
    |> Submission.changeset(Map.from_struct(submission))
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
    Core.Pools.Submissions.update(submission, changeset)
  end
end
