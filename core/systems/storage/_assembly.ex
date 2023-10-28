defmodule Systems.Storage.Assembly do
  alias Core.Repo

  alias Systems.Storage
  alias Systems.Storage.AWS
  alias Systems.Storage.Azure
  alias Systems.Storage.Centerdata
  alias Systems.Storage.Yoda

  def prepare_endpoint_special(nil), do: nil

  def prepare_endpoint_special(:aws) do
    %AWS.EndpointModel{}
    |> AWS.EndpointModel.changeset(%{})
  end

  def prepare_endpoint_special(:azure) do
    %Azure.EndpointModel{}
    |> Azure.EndpointModel.changeset(%{})
  end

  def prepare_endpoint_special(:centerdata) do
    %Centerdata.EndpointModel{}
    |> Centerdata.EndpointModel.changeset(%{})
  end

  def prepare_endpoint_special(:yoda) do
    %Yoda.EndpointModel{}
    |> Yoda.EndpointModel.changeset(%{})
  end

  def delete_endpoint_special(endpoint) do
    if special = Storage.EndpointModel.special(endpoint) do
      Repo.delete(special)
    end
  end
end
