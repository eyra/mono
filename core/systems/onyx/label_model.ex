defmodule Systems.Onyx.LabelModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Onyx
  alias Systems.Account

  schema "onxy_label" do
    field(:include?, :boolean, source: :include)

    belongs_to(:user, Account.User)
    belongs_to(:criterion, Onyx.CriterionModel)

    timestamps()
  end

  @fields ~w(include?)a
  @required_fields ~w(include?)a

  def changeset(label, attrs) do
    label
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:user), do: [user: []]
  def preload_graph(:criterion), do: [criterion: Onyx.CriterionModel.preload_graph(:down)]
end
