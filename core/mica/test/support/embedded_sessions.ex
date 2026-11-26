defmodule Mica.Test.EmbeddedSessions do
  @moduledoc """
  Reads the sessions a rendered page hands to its LiveViews.

  Every LiveView in a page carries its session in a `data-phx-session` token.
  Phoenix signs the token but doesn't encrypt it, so whatever a session holds is
  in the page that goes to the browser. Tests use `structs/2` to check that no
  record, such as a user, rides along.
  """

  @doc """
  The sessions of all LiveViews in `html`, verified with `endpoint`.
  """
  def sessions(html, endpoint) when is_binary(html) do
    html
    |> Floki.parse_document!()
    |> Floki.attribute("[data-phx-session]", "data-phx-session")
    |> Enum.map(&verify!(&1, endpoint))
  end

  @doc """
  The modules of the structs anywhere in the sessions of `html`, deduplicated.
  """
  def structs(html, endpoint) when is_binary(html) do
    html
    |> sessions(endpoint)
    |> collect_structs()
    |> Enum.uniq()
  end

  defp verify!(token, endpoint) do
    {:ok, %{session: session}} = Phoenix.LiveView.Static.verify_token(endpoint, token)
    session
  end

  defp collect_structs(%module{} = struct) do
    [module | struct |> Map.from_struct() |> collect_structs()]
  end

  defp collect_structs(map) when is_map(map) do
    Enum.flat_map(map, fn {key, value} -> collect_structs(key) ++ collect_structs(value) end)
  end

  defp collect_structs(list) when is_list(list), do: Enum.flat_map(list, &collect_structs/1)

  defp collect_structs(tuple) when is_tuple(tuple),
    do: tuple |> Tuple.to_list() |> collect_structs()

  defp collect_structs(_), do: []
end
