defmodule MicaWeb.PathCheck do
  @moduledoc ~S'''
  Checks Mica's paths (`~m`, `MicaWeb.Path`) against a SaaS's router.

  Mica has no router, so its paths can't be verified when Mica compiles. Each
  SaaS checks them against its own router instead, in two ways:

    * at compile time: `use MicaWeb.PathCheck` in the router prints a warning for
      every Mica path that fails, with the file and line of the `~m`
    * as a test that fails: `MicaWeb.PathCheck.unmatched(router) == []`

  A path passes when the router has a route for it and that route is served by
  a Mica module (a LiveView or a plug in `Mica`, `MicaWeb`, `Systems` or
  `Frameworks`). A route the SaaS put in its override routes passes too: those
  are its own pages that shadow Mica's, such as its sign-in pages. The router
  records them with `overrides/1`.

      warning: Mica path ~m"/assignment/#{id}/landng" matches no route in NextWeb.Router
      warning: Mica path ~m"/console" is served by MicaSaas.ConsolePage, not by Mica

  The check reads the paths of every module of Mica's application and of the
  router's application that uses `~m`, which includes SaaS modules that get a
  `~m` through one of Mica's macros. The compile-time warning appears when the
  router compiles; the test always checks every path.
  '''

  @mica_namespaces ~w(Mica MicaWeb Systems Frameworks)
  @verbs ~w(GET POST PUT PATCH DELETE)
  @route_macros ~w(get post put patch delete options head connect trace live forward)a

  defmacro __using__(_opts) do
    quote do
      @after_verify {MicaWeb.PathCheck, :__after_verify__}
    end
  end

  @doc false
  def __after_verify__(router), do: router |> unmatched() |> warn(router)

  @doc false
  def warn(issues, router) do
    for issue <- issues do
      IO.warn(message(issue, router), file: issue.file, line: issue.line, module: issue.module)
    end

    :ok
  end

  @doc """
  Splices `block`, the SaaS's override routes, into the router and records
  their paths, which the check accepts whoever serves them.
  """
  defmacro overrides(do: block) do
    patterns = route_patterns(block)

    quote do
      unquote(block)

      @doc false
      def __mica_override_routes__, do: unquote(patterns)
    end
  end

  @doc """
  The Mica paths that fail against `router`: `%{route:, path:, file:, line:,
  module:, reason:}`, where `reason` is `:no_route` or `{:served_by, module}`.
  `modules` defaults to every module that has Mica paths.
  """
  def unmatched(router, modules \\ nil) do
    overrides = override_routes(router)

    for module <- modules || path_modules(router),
        path <- module.__mica_paths__(),
        reason = check(router, overrides, path),
        do: path |> Map.put(:module, module) |> Map.put(:reason, reason)
  end

  @doc "The warning text of an issue from `unmatched/2`."
  def message(%{route: route, reason: :no_route}, router),
    do: "Mica path #{route} matches no route in #{inspect(router)}"

  def message(%{route: route, reason: {:served_by, module}}, _router),
    do: "Mica path #{route} is served by #{inspect(module)}, not by Mica"

  @doc "The issues from `unmatched/2` as text, one per path, with file and line."
  def format(issues, router) do
    Enum.map_join(issues, "\n", fn %{file: file, line: line, module: module} = issue ->
      "#{message(issue, router)}\n  #{Path.relative_to_cwd(file)}:#{line}: #{inspect(module)}"
    end)
  end

  @doc false
  def route_patterns(block), do: block |> patterns("/") |> Enum.uniq()

  defp check(router, overrides, %{path: path}) do
    segments = segments(path)

    if router.verified_route?([], segments) do
      served_by(router, overrides, segments)
    else
      :no_route
    end
  end

  # nil when one of the routes the path matches (whatever the verb) is Mica's or
  # an override; otherwise the module that serves it.
  defp served_by(router, overrides, segments) do
    routes =
      for verb <- @verbs,
          route = Phoenix.Router.route_info(router, verb, segments, ""),
          route != :error,
          do: route

    if routes == [] or Enum.any?(routes, &(&1.route in overrides or mica?(owner(&1)))) do
      nil
    else
      {:served_by, routes |> hd() |> owner()}
    end
  end

  defp owner(%{phoenix_live_view: {live_view, _action, _opts, _session}}), do: live_view
  defp owner(%{plug: plug}), do: plug

  defp mica?(module), do: hd(Module.split(module)) in @mica_namespaces

  # As Phoenix's route check: no fragment, no empty segments, decoded.
  defp segments(path) do
    path
    |> String.split("#")
    |> hd()
    |> String.split("/", trim: true)
    |> Enum.map(&URI.decode/1)
  end

  defp override_routes(router) do
    Code.ensure_loaded(router)

    if function_exported?(router, :__mica_override_routes__, 0),
      do: router.__mica_override_routes__(),
      else: []
  end

  defp path_modules(router) do
    beams =
      for dir <- Enum.uniq([ebin(:mica), router |> :code.which() |> ebin()]),
          dir != nil,
          file <- Path.wildcard(Path.join(dir, "Elixir.*.beam")),
          do: file |> Path.basename(".beam") |> String.to_atom()

    for module <- Enum.uniq(beams),
        Code.ensure_loaded?(module),
        function_exported?(module, :__mica_paths__, 0),
        do: module
  end

  defp ebin(app) when is_atom(app) do
    case :code.lib_dir(app) do
      {:error, _} -> nil
      dir -> Path.join(to_string(dir), "ebin")
    end
  end

  defp ebin(beam) when is_list(beam) and beam != [], do: beam |> to_string() |> Path.dirname()
  defp ebin(_), do: nil

  defp patterns({:__block__, _, exprs}, prefix), do: Enum.flat_map(exprs, &patterns(&1, prefix))

  defp patterns({:scope, _, args}, prefix) when is_list(args) do
    {head, [body]} = Enum.split(args, -1)
    patterns(Keyword.get(body, :do), join(prefix, scope_path(head)))
  end

  defp patterns({:live_session, _, args}, prefix) when is_list(args),
    do: args |> List.last() |> Keyword.get(:do) |> patterns(prefix)

  defp patterns({:match, _, [_verb, path | _]}, prefix) when is_binary(path),
    do: [join(prefix, path)]

  defp patterns({macro, _, [path | _]}, prefix) when macro in @route_macros and is_binary(path),
    do: [join(prefix, path)]

  defp patterns(_other, _prefix), do: []

  defp scope_path(head) do
    Enum.find_value(head, "", fn
      path when is_binary(path) -> path
      opts when is_list(opts) -> Keyword.keyword?(opts) && opts[:path]
      _ -> nil
    end)
  end

  defp join(prefix, path),
    do: "/" <> Enum.join(String.split(prefix <> "/" <> path, "/", trim: true), "/")
end
