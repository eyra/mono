defmodule Systems.Storage.JobDataModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  @fields ~w(data status description)a
  @required_fields ~w(data)a

  schema "storage_job_data" do
    field(:data, :binary)
    field(:status, Ecto.Enum, values: [:pending, :finished], default: :pending)
    field(:description, :string)
    timestamps()
  end

  def changeset(blob, attrs) do
    blob
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def prepare(data, description \\ nil) when is_binary(data) do
    %__MODULE__{}
    |> changeset(%{data: data, description: description})
    |> validate()
  end

  def mark_finished(blob) do
    blob
    |> changeset(%{status: :finished})
  end
end
