defmodule Systems.DataDonation.PortModelData do
  defmodule NoResultsError do
    @moduledoc false
    defexception [:message]
  end

  alias Systems.DataDonation.PortModel

  defp data(),
    do: [
      %PortModel{
        id: 1,
        storage: :azure,
        storage_info: %{key: "d3i/pilot"}
      }
    ]

  def get(id) when is_binary(id), do: get(String.to_integer(id))

  def get(id) when is_integer(id) do
    case data() |> Enum.find(&(&1.id == id)) do
      nil -> raise NoResultsError, "Could not find model for data donation flow #{id}"
      value -> value
    end
  end
end

defimpl Plug.Exception, for: Systems.DataDonation.PortModelData.NoResultsError do
  def status(_exception), do: 404
  def actions(_), do: []
end
