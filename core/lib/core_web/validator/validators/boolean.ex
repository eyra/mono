defmodule CoreWeb.Validator.Boolean do
  def valid_boolean?(value) when value in [true, false], do: :ok
  def valid_boolean?("true"), do: :ok
  def valid_boolean?("false"), do: :ok
  def valid_boolean?(_), do: {:error, "Not a valid boolean"}
end
