defmodule Core.Pools.Submissions do
  @moduledoc """
  """
  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Ecto.Changeset
  alias Core.Repo
  alias Core.Content.{Nodes, Node}
  alias Core.Pools.{Submission, Criteria}
  alias Core.Promotions.Promotion
  alias Core.Accounts

  alias Systems.NextAction

  def list do
    Repo.all(Submission)
  end

  def list(status, preload \\ [:criteria, :promotion, :content_node]) do
    from(submission in Submission,
      where: submission.status == ^status,
      preload: ^preload
    )
    |> Repo.all()
  end

  def get!(term, preload \\ [:criteria, :promotion, :content_node])

  def get!(%Promotion{} = promotion, preload) do
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

  def update(%Submission{} = submisson, %Changeset{} = changeset) do
    node = Nodes.get!(submisson.content_node_id)
    node_changeset = Submission.node_changeset(node, submisson, changeset.changes)

    with {:ok, %{submisson: submisson}} <-
           Multi.new()
           |> Multi.update(:submisson, changeset)
           |> Multi.update(:content_node, node_changeset)
           |> Repo.transaction() do
      {:ok, notify_when_submitted(submisson, changeset)}
    end
  end

  def update(%Submission{} = submisson, attrs) do
    changeset = Submission.changeset(submisson, attrs)
    __MODULE__.update(submisson, changeset)
  end

  def create(promotion, pool, %Node{} = content_node) do
    submission_changeset =
      %Submission{}
      |> Submission.changeset(%{status: :idle})
      |> Ecto.Changeset.put_assoc(:promotion, promotion)
      |> Ecto.Changeset.put_assoc(:pool, pool)
      |> Ecto.Changeset.put_assoc(:content_node, content_node)

    criteria_changeset =
      %Criteria{}
      |> Criteria.changeset(%{study_program_codes: [:bk_1, :bk_1_h, :iba_1, :iba_1_h]})
      |> Ecto.Changeset.put_assoc(:submission, submission_changeset)

    criteria = Repo.insert!(criteria_changeset)

    {:ok, criteria.submission}
  end

  defp notify_when_submitted(%Submission{} = submission, %Ecto.Changeset{} = changeset) do
    if Ecto.Changeset.get_change(changeset, :status) === :submitted do
      for user <- Accounts.list_pool_admins do
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
