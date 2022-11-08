defmodule Systems.DataDonation.PortModel do
  use Ecto.Schema

  embedded_schema do
    field(:storage, :string)
    field(:storage_info, :map)
  end
end
