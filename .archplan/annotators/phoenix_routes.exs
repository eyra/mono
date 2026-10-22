# archplan annotator: entrypoint.auth for each route of the Phoenix router.
#
# A controller action or LiveView reached through one of the authn_pipelines
# needs a signed-in caller: auth=required. When its path also has a
# parameter, such as /storage/endpoint/:id/export, the request names
# something the caller may not be allowed to see or change: auth=authz,
# unless every clause of the function ignores its params (`_params`).
# Parameters in unscoped_params, such as a token that is itself the
# permission, do not count. overrides lists "Module.function=value", where
# value is required, authz, none or skip, to leave the entry point out. Routes outside the authn pipelines
# get no declaration. See archplan's format/annotator-plugins.md.

[ctx_file, out_file] = System.argv()
ctx = ctx_file |> File.read!() |> JSON.decode!()
# The repository root as the compiler saw it: the shell script runs this in
# core/, and the cwd has symlinks resolved, like the compiled source paths.
root = Path.expand("..", File.cwd!())
params = ctx["params"] || %{}
router = Module.concat([params["router"] || "CoreWeb.Router"])
authn = MapSet.new(params["authn_pipelines"] || ["require_authenticated_user"])
unscoped = MapSet.new(params["unscoped_params"] || [])

overrides =
  for o <- params["overrides"] || [], into: %{} do
    [key, value] = String.split(o, "=", parts: 2)
    {key, value}
  end

# {file, line, uses params?} of `def name` in the module's source file. A
# LiveView's mount takes the params first, a controller action second.
locate = fn mod, name ->
  source = mod.module_info(:compile)[:source] |> to_string()
  rel = Path.relative_to(source, root)
  rx = ~r/^\s*def\s+#{Regex.escape(name)}[\s(,]/

  ignored =
    if name == "mount",
      do: ~r/def\s+mount\(\s*_\w*\s*,/,
      else: ~r/,\s*_\w*\s*\)\s*(?:,\s*)?do\b/

  with false <- rel == source,
       {:ok, text} <- File.read(source),
       lines = String.split(text, "\n"),
       [i | _] = defs <-
         lines
         |> Enum.with_index()
         |> Enum.filter(&Regex.match?(rx, elem(&1, 0)))
         |> Enum.map(&elem(&1, 1)) do
    {rel, i + 1, not Enum.all?(defs, &Regex.match?(ignored, Enum.at(lines, &1)))}
  else
    _ -> nil
  end
end

# The pipelines of a route. Phoenix keeps them out of __routes__/0, so look
# the route up with a sample path.
pipelines = fn route ->
  sample = String.replace(route.path, ~r/[:*]\w+/, "1")
  verb = route.verb |> to_string() |> String.upcase()

  case Phoenix.Router.route_info(router, verb, sample, nil) do
    %{route: path, pipe_through: pipes} when path == route.path -> pipes
    _ -> []
  end
end

entries =
  for route <- router.__routes__(),
      pipes = pipelines.(route),
      Enum.any?(pipes, &MapSet.member?(authn, Atom.to_string(&1))),
      {mod, fun} =
        (case route.metadata[:phoenix_live_view] do
           {view, _action, _opts, _session} -> {view, "mount"}
           _ -> {route.plug, Atom.to_string(route.plug_opts)}
         end),
      key = "#{inspect(mod)}.#{fun}",
      overrides[key] != "skip",
      at = locate.(mod, fun),
      at != nil do
    names = Regex.scan(~r/[:*](\w+)/, route.path, capture: :all_but_first) |> List.flatten()
    scoped = Enum.reject(names, &MapSet.member?(unscoped, &1))
    {file, line, uses} = at
    value = overrides[key] || if(scoped == [] or not uses, do: "required", else: "authz")

    {key, {file, line}, value,
     "#{route.verb |> to_string() |> String.upcase()} #{route.path} (#{Enum.join(pipes, " ")})"}
  end

rank = %{"none" => 0, "required" => 1, "authz" => 2}

declarations =
  entries
  |> Enum.group_by(&elem(&1, 0))
  |> Enum.sort()
  |> Enum.map(fn {_key, [{_, {file, line}, _, _} | _] = routes} ->
    {_, _, value, _} = Enum.max_by(routes, fn {_, _, v, _} -> rank[v] end)
    [{_, _, _, first} | more] = routes
    reason = "router: " <> first <> if(more == [], do: "", else: " and #{length(more)} more")
    name = routes |> hd() |> elem(0) |> String.split(".") |> List.last()

    %{
      "target" => %{"kind" => "entrypoint", "file" => file, "line" => line, "name" => name},
      "key" => "auth",
      "value" => value,
      "reason" => reason
    }
  end)

File.write!(out_file, JSON.encode!(%{"declarations" => declarations}))
