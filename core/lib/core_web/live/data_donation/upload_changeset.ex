defmodule CoreWeb.DataDonation.UploadChangeset do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:terms_accepted, :boolean)
  end

  def changeset(params) do
    %__MODULE__{}
    |> cast(params, [:terms_accepted])
    |> validate_required([:terms_accepted])
  end
end
