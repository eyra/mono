defmodule Core.Pools.Submissions do
  @moduledoc """
  """
  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Core.Repo
  alias Frameworks.Signal
  alias Core.Content.{Nodes, Node}
  alias Core.Pools.{Submission, Criteria}
  alias Core.Promotions.Promotion

  def list do
    Repo.all(Submission)
  end

  def get!(term, preload \\ [:criteria, :content_node])

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

  def update(%Submission{} = submisson, attrs) do
    submission_changeset = Submission.changeset(submisson, attrs)
    node = Nodes.get!(submisson.content_node_id)
    node_changeset = Submission.node_changeset(node, submisson, attrs)

    with {:ok, %{submisson: submisson}} <-
           Multi.new()
           |> Multi.update(:submisson, submission_changeset)
           |> Multi.update(:content_node, node_changeset)
           |> Repo.transaction() do
      {:ok, notify_when_accepted(submisson, submission_changeset)}
    end
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

  defp notify_when_accepted(%Submission{} = submission, %Ecto.Changeset{} = changeset) do
    if Ecto.Changeset.get_change(changeset, :status) === :accepted do
      Signal.Context.dispatch(:submission_accepted, %{submission: submission})
    end

    submission
  end
end
