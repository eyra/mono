defmodule Systems.DataDonation.InstitutionModel do
  use Ecto.Schema

  embedded_schema do
    field(:name, :string)
    field(:image, :string)
  end
end
