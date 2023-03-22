defmodule Systems.Student.Course do
  @moduledoc """
    Defines student course using organisation nodes.
  """

  alias Frameworks.Utility.Identifier

  alias Systems.{
    Org
  }

  # FIXME POOL Backwards compatible from new organisation node identifier (course) to old pool name format (intentionally ugly code)
  def pool_name(%{identifier: identifier} = _course), do: Identifier.to_string(identifier)
  def currency(%{identifier: identifier} = _course), do: Identifier.to_string(identifier)

  def get_by_wallet(%{identifier: identifier}), do: get_by_wallet(identifier)

  def get_by_wallet(["wallet", currency_name, _]) do
    Identifier.from_string(currency_name, true)
    |> Org.Public.get_node()
  end
end
