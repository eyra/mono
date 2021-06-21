defmodule Core.DataUploader.UserData do
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.DataUploader.ClientScript

  schema "data_uploader_user_data" do
    field(:data, :binary)
    belongs_to(:client_script, ClientScript)

    timestamps()
  end

  @doc false
  def changeset(user_data, attrs) do
    user_data
    |> cast(attrs, [:data])
    |> put_assoc(:client_script, attrs[:client_script])
    |> validate_required([:data])
  end
end
