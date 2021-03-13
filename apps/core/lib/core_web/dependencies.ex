defmodule CoreWeb.Dependencies.Injector do
  @moduledoc """
  Should be used as a plug in a bundle endpoint to inject modules that are needed by :core otp_app

  ### Required options
    - path_provider

  ### Example
    plug(CoreWeb.Dependencies.Injector, [path_provider: LinkWeb.PathProvider])

  """
  @behaviour Plug

  alias Plug.Conn

  @impl true
  def init(opts) do
    opts
  end

  @impl true
  def call(conn, opts) do
    path_provider = Keyword.fetch!(opts, :path_provider)

    Conn.fetch_session(conn)
    |> Conn.put_session(:path_provider, path_provider)
  end
end

defmodule CoreWeb.Dependencies.Resolver do
  def resolve(conn, dependency) when is_atom(dependency) do
    [
      [dependency],
      [:assigns, dependency],
      [:private, dependency],
      [:private, :conn_session, Atom.to_string(dependency)],
      [:private, :plug_session, Atom.to_string(dependency)],
      [:private, :connect_info, :session, Atom.to_string(dependency)]
    ]
    |> find(conn)
  end

  def find(paths, conn) when is_list(paths) do
    paths
    |> Enum.find_value(:error, &find_value(conn, &1))
  end

  defp find_value(nil, _), do: nil
  defp find_value(_, []), do: nil
  defp find_value(map_or_struct, [head | []]), do: Map.get(map_or_struct, head)

  defp find_value(map_or_struct, [head | tail]),
    do: find_value(Map.get(map_or_struct, head), tail)
end
