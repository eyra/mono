defmodule Core.DataUploader do
  @moduledoc """

  A data uploader allows a research to ask participants to submit data. This
  data is submitted in the form of a file that is stored on the participants
  device.

  Tools are provided that allow for execution of filtering code on the device
  of the participant. This ensures that only the data that is needed for the
  research is shared with the researcher.
  """

  import Ecto.Query, warn: false
  alias Core.Repo

  alias Core.DataUploader.ClientScript
  alias Core.Authorization

  def list_client_scripts do
    Repo.all(ClientScript)
  end

  def get_client_script!(id), do: Repo.get!(ClientScript, id)
  def get_client_script(id), do: Repo.get(ClientScript, id)

  def create_client_script(attrs, study) do
    %ClientScript{}
    |> ClientScript.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:study, study)
    |> Ecto.Changeset.put_assoc(:auth_node, Authorization.make_node(study))
    |> Repo.insert()
  end

  def update_client_script(%ClientScript{} = client_script, attrs) do
    client_script
    |> ClientScript.changeset(attrs)
    |> update_client_script()
  end

  def update_client_script(changeset) do
    changeset
    |> Repo.update()
  end

  def delete_client_script(%ClientScript{} = client_script) do
    Repo.delete(client_script)
  end

  def change_client_script(%ClientScript{} = client_script, _type, attrs \\ %{}) do
    ClientScript.changeset(client_script, attrs)
  end
end
