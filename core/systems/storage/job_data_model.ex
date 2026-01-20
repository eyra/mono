defmodule Systems.Storage.JobDataModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Account

  @fields ~w(data status meta_data)a
  @required_fields ~w(data)a

  schema "storage_job_data" do
    field(:data, :binary)
    field(:status, Ecto.Enum, values: [:pending, :finished], default: :pending)
    field(:meta_data, :map)
    belongs_to(:user, Account.User)
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

  def prepare(data, user \\ nil, meta_data \\ nil) when is_binary(data) do
    %__MODULE__{}
    |> changeset(%{data: data, meta_data: meta_data})
    |> maybe_put_user(user)
    |> validate()
  end

  defp maybe_put_user(changeset, nil), do: changeset
  defp maybe_put_user(changeset, user), do: put_assoc(changeset, :user, user)

  def mark_finished(blob) do
    blob
    |> changeset(%{status: :finished})
  end
end
