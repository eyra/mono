defmodule CoreWeb.Validator.Integer do
  def valid_integer?(value) when is_integer(value), do: :ok

  def valid_integer?(value) when is_binary(value) do
    case Integer.parse(value) do
      {_, ""} -> :ok
      _ -> {:error, "Not a valid integer"}
    end
  end

  def valid_integer?(_), do: {:error, "Not a valid integer"}
end
