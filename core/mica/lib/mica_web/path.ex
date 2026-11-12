defmodule MicaWeb.Path do
  @moduledoc ~S'''
  Mica's paths: `~m`, "m for Mica path".

  Mica has no router, so it can't use Phoenix's verified `~p`. `~m` builds a
  path exactly the way `~p` does and records it in the module that uses it:

      use MicaWeb.Path

      ~m"/assignment/#{assignment}"           # "/assignment/42", through Phoenix.Param
      ~m"/project?#{[tab: "items", page: 2]}" # "/project?tab=items&page=2"
      ~m"/search?q=#{query}"                  # "/search?q=%C3%A9%26"
      ~m"/images/icons/#{"#{icon}.svg"}"      # a static path, through the endpoint
      url(socket, ~m"/user/reset-password/#{token}")

  Every SaaS checks the recorded paths against its own router, with
  `MicaWeb.PathCheck`. Paths under the static folders (`statics/0`) go through
  the endpoint's `static_path/1` and are not recorded, as with `~p`.

  Mica's web module imports `~m` (`use MicaWeb, :verified_routes` and the blocks
  that include it). SaaS code keeps Phoenix's `~p`, verified against its own
  router.
  '''

  @statics ~w(css assets fonts images js favicon logo icon apple-touch-icon robots manifest sw)

  # The endpoint the paths are built for.
  @endpoint MicaWeb.Endpoint

  @doc "The top-level folders whose paths are static files."
  def statics, do: @statics

  defmacro __using__(_opts) do
    quote do
      unquote(__MODULE__).__setup__(__MODULE__)
      import unquote(__MODULE__), only: [sigil_m: 2, url: 2]
    end
  end

  @doc false
  def __setup__(module) do
    unless Module.has_attribute?(module, :mica_paths) do
      Module.register_attribute(module, :mica_paths, accumulate: true)
      Module.put_attribute(module, :before_compile, __MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    paths = env.module |> Module.get_attribute(:mica_paths) |> Enum.reverse()

    if paths != [] do
      quote do
        @doc false
        def __mica_paths__, do: unquote(Macro.escape(paths))
      end
    end
  end

  @doc ~S'''
  Builds the path, like `~p`, and records it for `MicaWeb.PathCheck`.

  Interpolated segments are encoded with `Phoenix.Param`, an interpolated query
  (`?#{params}`) takes a keyword list or map, and a query value (`?q=#{v}`) is
  form-encoded.
  '''
  defmacro sigil_m({:<<>>, _meta, _segments} = route, modifiers) do
    if modifiers != [],
      do: raise(ArgumentError, "~m does not support modifiers, got: #{modifiers}")

    case build(route, __CALLER__) do
      {:static, path_ast} ->
        quote generated: true, do: unquote(__MODULE__).__static_path__(unquote(path_ast))

      {:route, path_ast} ->
        quote generated: true, do: unquote(__MODULE__).__path__(unquote(path_ast))
    end
  end

  @doc "The full URL of a `~m` path, for the endpoint of a conn or socket, like Phoenix's `url/2`."
  defmacro url(conn_or_socket, {:sigil_m, _, [{:<<>>, _, _} = route, _]}) do
    case build(route, __CALLER__) do
      {:static, _path_ast} ->
        # As Phoenix does for a static url: the path as written, not rewritten.
        quote generated: true do
          Phoenix.VerifiedRoutes.static_url(unquote(conn_or_socket), unquote(route))
        end

      {:route, path_ast} ->
        quote generated: true do
          context = unquote(conn_or_socket)

          Phoenix.VerifiedRoutes.unverified_url(
            context,
            Phoenix.VerifiedRoutes.unverified_path(context, nil, unquote(path_ast))
          )
        end
    end
  end

  defmacro url(_conn_or_socket, other) do
    raise ArgumentError, "expected a ~m path, got: #{Macro.to_string(other)}"
  end

  @doc false
  def __path__(path), do: Phoenix.VerifiedRoutes.unverified_path(@endpoint, nil, path)

  @doc false
  def __static_path__(path), do: Phoenix.VerifiedRoutes.static_path(@endpoint, path)

  @doc false
  def __encode_segment__(data) do
    case data do
      [] -> ""
      [str | _] when is_binary(str) -> Enum.map_join(data, "/", &encode_segment/1)
      _ -> encode_segment(data)
    end
  end

  @doc false
  def __encode_query__(dict, sort?) when is_map(dict) and not is_struct(dict) do
    dict |> Plug.Conn.Query.encode(&to_param/1) |> sort_query(sort?)
  end

  def __encode_query__(dict, sort?) when is_list(dict) do
    if dict == [] or match?([{_, _} | _], dict) do
      dict |> Plug.Conn.Query.encode(&to_param/1) |> sort_query(sort?)
    else
      raise ArgumentError,
            "expected a keyword list or map for query string encoding, got: #{inspect(dict)}. " <>
              "Use the full query string syntax instead, such as ~m\"/path?#\{[key: #{inspect(dict)}]}\""
    end
  end

  def __encode_query__(value, _sort?), do: value |> to_param() |> URI.encode_www_form()

  defp encode_segment(data) do
    data |> Phoenix.Param.to_param() |> URI.encode(&URI.char_unreserved?/1)
  end

  defp sort_query(query, true) when query != "",
    do: query |> String.split("&") |> Enum.sort() |> Enum.join("&")

  defp sort_query(query, _sort?), do: query

  defp to_param(int) when is_integer(int), do: Integer.to_string(int)
  defp to_param(bin) when is_binary(bin), do: bin
  defp to_param(false), do: "false"
  defp to_param(true), do: "true"
  defp to_param(data), do: Phoenix.Param.to_param(data)

  # Rewrites the sigil's segments the way Phoenix.VerifiedRoutes does, and records
  # the path in the calling module unless it is static.
  defp build({:<<>>, meta, segments} = route, env) do
    unless env.function do
      raise ArgumentError,
            "~m can only be used inside functions, got: ~m#{Macro.to_string(route)}"
    end

    unless Module.has_attribute?(env.module, :mica_paths) do
      raise ArgumentError, "use MicaWeb.Path (or MicaWeb's :verified_routes) before using ~m"
    end

    {path_rewrite, query_rewrite} = rewrite_segments(segments, route)
    test_path = materialize(path_rewrite)

    path_ast =
      if query_rewrite == [] do
        {:<<>>, meta, path_rewrite}
      else
        quote generated: true do
          query_str = unquote({:<<>>, meta, query_rewrite})
          path_str = unquote({:<<>>, meta, path_rewrite})
          if query_str == "", do: path_str, else: path_str <> "?" <> query_str
        end
      end

    if static?(test_path) do
      {:static, path_ast}
    else
      Module.put_attribute(env.module, :mica_paths, %{
        path: test_path,
        route: "~m" <> Macro.to_string(route),
        file: env.file,
        line: meta[:line] || env.line
      })

      {:route, path_ast}
    end
  end

  defp static?(path), do: Enum.any?(@statics, &String.starts_with?(path, "/" <> &1))

  # Dynamic segments become "1", as in Phoenix's route check.
  defp materialize(path), do: Enum.map_join(path, &if(is_binary(&1), do: &1, else: "1"))

  defp rewrite_segments(["/" <> _ | _] = segments, route),
    do: rewrite_segments(segments, route, [])

  defp rewrite_segments(_, route) do
    raise ArgumentError, "paths must begin with /, got: ~m#{Macro.to_string(route)}"
  end

  defp rewrite_segments(["/" | rest], route, acc), do: rewrite_segments(rest, route, ["/" | acc])

  defp rewrite_segments(["/" <> _ = segment | rest], route, acc) do
    case {String.split(segment, "?"), rest} do
      {[segment], _} ->
        rewrite_segments(rest, route, [URI.encode(segment) | acc])

      {[segment, static_query], dynamic_query} ->
        {Enum.reverse([URI.encode(segment) | acc]),
         rewrite_query(dynamic_query, route, [static_query])}
    end
  end

  defp rewrite_segments(["?" <> query], _route, acc), do: {Enum.reverse(acc), [query]}

  defp rewrite_segments(["?" <> static_query | rest], route, acc) do
    {Enum.reverse(acc), rewrite_query(rest, route, [static_query])}
  end

  defp rewrite_segments([segment | _], route, _acc) when is_binary(segment) do
    raise ArgumentError,
          "path segments after interpolation must begin with /, got: #{inspect(segment)} in ~m#{Macro.to_string(route)}"
  end

  defp rewrite_segments(
         [
           {:"::", m1, [{{:., m2, [Kernel, :to_string]}, m3, [dynamic]}, {:binary, _, _} = bin]}
           | rest
         ],
         route,
         [prev | _] = acc
       )
       when is_binary(prev) do
    rewrite = {:"::", m1, [{{:., m2, [__MODULE__, :__encode_segment__]}, m3, [dynamic]}, bin]}
    rewrite_segments(rest, route, [rewrite | acc])
  end

  defp rewrite_segments([_ | _], route, _acc) do
    raise ArgumentError,
          "a dynamic ~m interpolation must follow a static segment, got: ~m#{Macro.to_string(route)}"
  end

  defp rewrite_segments([], _route, acc), do: {Enum.reverse(acc), []}

  defp rewrite_query(
         [
           {:"::", m1, [{{:., m2, [Kernel, :to_string]}, m3, [arg]}, {:binary, _, _} = bin]}
           | rest
         ],
         route,
         acc
       ) do
    unless is_binary(hd(acc)) do
      raise ArgumentError,
            "interpolated query string params must be separated by &, got: ~m#{Macro.to_string(route)}"
    end

    sort? = Application.get_env(:phoenix, :sort_verified_routes_query_params, false)
    rewrite = {:"::", m1, [{{:., m2, [__MODULE__, :__encode_query__]}, m3, [arg, sort?]}, bin]}
    rewrite_query(rest, route, [rewrite | acc])
  end

  defp rewrite_query([], _route, acc), do: Enum.reverse(acc)

  defp rewrite_query(["=" | rest], route, acc), do: rewrite_query(rest, route, ["=" | acc])

  defp rewrite_query(["&" <> _ = param | rest], route, acc) do
    unless String.contains?(param, "=") do
      raise ArgumentError,
            "expected query string param key to end with = or declare a static key value pair, got: #{inspect(param)}"
    end

    rewrite_query(rest, route, [param | acc])
  end

  defp rewrite_query(_other, route, _acc) do
    raise ArgumentError,
          "expected query string param to be compile-time map or keyword list, got: ~m#{Macro.to_string(route)}"
  end
end
