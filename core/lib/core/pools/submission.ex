defmodule Core.Pools.Submission do
  @moduledoc """
  A task (donate data) to be completed by a participant.
  """
  use Ecto.Schema
  use Core.Content.Node

  import Ecto.Changeset

  alias Core.Pools.{Criteria, Pool}
  alias Core.Promotions.Promotion

  schema "pool_submissions" do
    field(:status, Ecto.Enum, values: [:idle, :submitted, :accepted])

    has_one(:criteria, Criteria)
    belongs_to(:promotion, Promotion)
    belongs_to(:pool, Pool)

    belongs_to(:content_node, Core.Content.Node)

    timestamps()
  end

  @fields ~w(status)a

  @impl true
  def operational_fields, do: @fields

  @impl true
  def operational_validation(changeset), do: changeset

  def changeset(submission, attrs) do
    submission
    |> cast(attrs, @fields)
  end
end
