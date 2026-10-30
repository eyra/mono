defmodule Systems.Storage.Assembly do
  alias Mica.Repo
  alias Systems.Storage

  def delete_endpoint_special(endpoint) do
    if special = Storage.EndpointModel.special(endpoint) do
      Repo.delete(special)
    end
  end
end
