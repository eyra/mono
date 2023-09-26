defmodule Systems.DataDonation.QuestionnaireTaskModel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "data_donation_questionnaire_tasks" do
    timestamps()
  end

  @fields ~w()a
  @required_fields @fields

  def changeset(model, params) do
    model
    |> cast(params, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def ready?(task) do
    changeset =
      changeset(task, %{})
      |> validate()

    changeset.valid?()
  end
end
