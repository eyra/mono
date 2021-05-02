defmodule Core.DataUploader.ClientScript do
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Studies.Study

  schema "client_scripts" do
    belongs_to(:auth_node, Core.Authorization.Node)
    belongs_to(:study, Study)

    field(:title, :string)
    field(:script, :string)

    timestamps()
  end

  @doc false
  def changeset(client_script, attrs) do
    client_script
    |> cast(attrs, [:script])
    |> validate_required([:script])
  end
end
