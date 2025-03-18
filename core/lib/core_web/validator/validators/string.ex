defmodule CoreWeb.Validator.String do
  def valid_non_empty?(string) when is_binary(string) do
    if String.trim(string) == "" do
      {:error, "String cannot be empty"}
    else
      :ok
    end
  end

  def valid_non_empty?(_), do: {:error, "Not a valid string"}
end
