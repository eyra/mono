defmodule CoreWeb.DependencyResolver do
  def resolve(%{} = map, dependency) do
    [
      [dependency],
      [:private, dependency],
      [:private, :conn_session, dependency],
      [:private, :plug_session, dependency],
      [:private, :connect_info, :session, dependency]
    ]
    |> Enum.reduce(:error, fn path, acc ->
      case get_in(map, path) do
        nil -> acc
        value -> value
      end
    end)
  end
end
