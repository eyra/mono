defmodule Core.NotificationCenter.Log do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notification_center_logs" do
    field(:item_type, :string)
    field(:item_id, :integer)
    field(:signal, :string)

    timestamps()
  end

  @doc false
  def changeset(%{type: type, id: id, signal: signal}) do
    %__MODULE__{}
    |> change()
    |> put_change(:item_type, to_string(type))
    |> put_change(:item_id, id)
    |> put_change(:signal, to_string(signal))
  end
end
