# Nova migration boundary check (plan step code-layout, rule 2).
#
# Roots: mica/ (Mica), next/ (Eyra's Next SaaS) and mica_saas/ (the Self
# reference SaaS). Mica may not depend on any SaaS, and a SaaS may not depend on
# another SaaS: mica -> next, mica -> mica_saas, next -> mica_saas and
# mica_saas -> next are forbidden. Fails when
#   1. a file in one root references a module defined in a file in a forbidden
#      root (compile, export or runtime reference, from `mix xref graph`), or
#   2. a file names a namespace of a forbidden root that xref cannot see (for
#      example a Registry name such as Systems.Paper.ImportRegistry in mica/), or
#   3. a file under mica/ contains a PaNL, VU or Eyra literal,
# unless the file is listed in boundary_allowlist.exs for that kind.
# Also fails when an allowlisted entry no longer occurs, so the list only shrinks.
#
# Usage (from core/, after `mix compile`):
#   elixir scripts/boundary_check.exs
#   elixir scripts/boundary_check.exs --write-allowlist

defmodule BoundaryCheck do
  @allowlist_file "boundary_allowlist.exs"
  # Root directory => owner. Paths are relative to core/.
  @roots %{"mica/" => "mica", "next/" => "next", "mica_saas/" => "mica_saas"}
  # Owner => owners it may not reference. Tests under <root>test/ are not checked.
  @forbidden %{
    "mica" => ["next", "mica_saas"],
    "next" => ["mica_saas"],
    "mica_saas" => ["next"]
  }
  @source_exts ~w(.ex .exs .heex .eex)

  # A function, not a module attribute: OTP 28 regexes cannot be escaped into attributes.
  defp literals do
    [
      panl_atom: ~r/:panl\b/,
      panl_string: ~r/"(Panl|PaNL|PANL)"/,
      panl_domain: ~r/panl\.nl/,
      eyra_domain: ~r/eyra\.co\b/,
      eyra_service: ~r/@eyra\.service/,
      vu_code: ~r/\bvu_sbe_\w+|\bgenerate_vu\b|VUDaySchedule/
    ]
  end

  def main(args) do
    module_found = module_violations()
    xref_files = MapSet.new(module_found, fn {file, kind, _} -> {file, kind} end)
    found = module_found ++ name_violations(xref_files) ++ literal_violations()

    if "--write-allowlist" in args do
      write_allowlist(found)
    else
      check(found, read_allowlist())
    end
  end

  # {file, kind, detail}
  defp module_violations do
    {dot, 0} =
      System.cmd("mix", ~w(xref graph --no-compile --format dot --output -),
        stderr_to_stdout: false
      )

    ~r/^\s*"([^"]+)" -> "([^"]+)"/m
    |> Regex.scan(dot, capture: :all_but_first)
    |> Enum.filter(fn [from, to] ->
      forbidden?(owner(from), owner(to)) and not test_file?(from)
    end)
    |> Enum.group_by(fn [from, to] -> {from, kind(owner(to), "reference")} end, fn [_, to] ->
      to
    end)
    |> Enum.map(fn {{file, kind}, targets} -> {file, kind, Enum.sort(Enum.uniq(targets))} end)
  end

  # Module names xref cannot see, such as a Registry name atom. Uses the
  # namespaces of the top-level modules defined in each forbidden root.
  defp name_violations(xref_files) do
    namespaces = Map.new(@roots, fn {root, owner} -> {owner, namespaces(root)} end)

    for {root, from} <- @roots,
        to <- Map.fetch!(@forbidden, from),
        file <- Path.wildcard(root <> "**/*.{ex,exs}"),
        not test_file?(file),
        not MapSet.member?(xref_files, {file, kind(to, "reference")}),
        hits = Enum.filter(alias_names(file), &in_namespace?(&1, namespaces[to])),
        hits != [] do
      {file, kind(to, "name"), Enum.sort(Enum.uniq(hits))}
    end
  end

  defp namespaces(root) do
    for file <- Path.wildcard(root <> "**/*.ex"),
        [_, name] <- Regex.scan(~r/^defmodule\s+([\w.]+)/m, File.read!(file)),
        uniq: true do
      case String.split(name, ".") do
        ["Systems", system | _] -> "Systems." <> system
        # A SaaS's own top-level namespace (Next.*, Self.*) is taken whole.
        [top | _] when top in ["Next", "Self"] -> top
        _ -> name
      end
    end
  end

  defp in_namespace?(name, namespaces),
    do: Enum.any?(namespaces, &(name == &1 or String.starts_with?(name, &1 <> ".")))

  defp alias_names(file) do
    {:ok, ast} = file |> File.read!() |> Code.string_to_quoted()

    {_, names} =
      Macro.prewalk(ast, [], fn
        {:__aliases__, _, parts} = node, acc when is_list(parts) ->
          if Enum.all?(parts, &is_atom/1),
            do: {node, [Enum.join(parts, ".") | acc]},
            else: {node, acc}

        node, acc ->
          {node, acc}
      end)

    names
  end

  defp literal_violations do
    for file <- Path.wildcard("mica/**/*"),
        Path.extname(file) in @source_exts,
        not test_file?(file),
        content = File.read!(file),
        {kind, regex} <- literals(),
        Regex.match?(regex, content) do
      {file, kind, length(Regex.scan(regex, content))}
    end
  end

  defp check(found, allowlist) do
    found_keys = MapSet.new(found, fn {file, kind, _} -> {file, kind} end)
    allowed_keys = MapSet.new(Map.keys(allowlist))

    new = Enum.reject(found, fn {file, kind, _} -> MapSet.member?(allowed_keys, {file, kind}) end)
    stale = MapSet.difference(allowed_keys, found_keys) |> Enum.sort()

    Enum.each(new, fn {file, kind, detail} ->
      IO.puts(:stderr, "boundary: new #{kind} in #{file}: #{inspect(detail)}")
    end)

    Enum.each(stale, fn {file, kind} ->
      IO.puts(:stderr, "boundary: #{file} (#{kind}) is fixed; remove it from #{@allowlist_file}")
    end)

    IO.puts(
      "boundary: #{MapSet.size(allowed_keys)} allowlisted (#{allowed_files(allowed_keys)} files), #{length(new)} new, #{length(stale)} stale"
    )

    if new != [] or stale != [], do: System.halt(1)
  end

  defp allowed_files(keys), do: keys |> Enum.map(&elem(&1, 0)) |> Enum.uniq() |> length()

  defp read_allowlist do
    if File.exists?(@allowlist_file) do
      {list, _} = Code.eval_file(@allowlist_file)
      Map.new(list, fn {file, kind, reason} -> {{file, kind}, reason} end)
    else
      %{}
    end
  end

  defp write_allowlist(found) do
    entries =
      found
      |> Enum.sort()
      |> Enum.map_join(",\n", fn {file, kind, detail} ->
        ~s|  {"#{file}", :#{kind}, "TODO reason; #{inspect(detail) |> String.replace("\"", "'")}"}|
      end)

    # Formatted, because .formatter.exs includes "*.{ex,exs}" at core/.
    source = "# Generated by scripts/boundary_check.exs. May only shrink.\n[\n#{entries}\n]\n"
    File.write!(@allowlist_file, [Code.format_string!(source), "\n"])

    IO.puts("boundary: wrote #{length(found)} entries to #{@allowlist_file}")
  end

  defp owner(path) do
    Enum.find_value(@roots, fn {root, owner} -> if String.starts_with?(path, root), do: owner end)
  end

  defp forbidden?(nil, _to), do: false
  defp forbidden?(from, to), do: to in Map.fetch!(@forbidden, from)

  defp kind(owner, what), do: String.to_atom(owner <> "_" <> what)

  defp test_file?(path) do
    Enum.any?(Map.keys(@roots), &String.starts_with?(path, &1 <> "test/"))
  end
end

BoundaryCheck.main(System.argv())
