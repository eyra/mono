defmodule Systems.Admin.ImportRewardsModel do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:session_key, :string)
  end

  def changeset(schema, data) do
    schema
    |> cast(data, [:session_key])
    |> validate_required([:session_key])
  end
end
