defmodule CoreWeb.Validator.Float do
  def valid_float?(value) when is_float(value), do: :ok
  def valid_float?(value) when is_integer(value), do: :ok

  def valid_float?(value) when is_binary(value) do
    case Float.parse(value) do
      {_, ""} -> :ok
      _ -> {:error, "Not a valid float"}
    end
  end

  def valid_float?(_), do: {:error, "Not a valid float"}
end
