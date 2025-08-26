defmodule Frameworks.Utility.UserState do
  def string_value(data, key) do
    Map.get(data, key)
  end

  def integer_value(data, key) do
    if value = Map.get(data, key) do
      try do
        value |> String.to_integer()
      rescue
        ArgumentError -> nil
      end
    else
      nil
    end
  end

  def key(%{id: user_id}, %{} = path, name) when is_binary(name) do
    "next://user-#{user_id}@#{domain()}/#{path_to_string(path)}/#{name}"
  end

  def path_to_string(path) do
    Enum.map_join(path, "/", fn {key, value} -> "#{key}/#{value}" end)
  end

  def domain do
    Application.get_env(:core, :domain, "unknown.host")
  end
end
