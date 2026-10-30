# Nova migration boundary check (plan step code-layout, rule 2).
#
# Roots: mica/ (Mica), next/ (Eyra's Next SaaS) and mica_saas/ (the Self
# reference SaaS), plus config/, the shared config that Mica owns until
# code-split. Mica may not depend on any SaaS, and a SaaS may not depend on
# another SaaS: mica -> next, mica -> mica_saas, next -> mica_saas and
# mica_saas -> next are forbidden. The rules live in scripts/boundary_rules.ex,
# which the credo check MicaBoundary shares. Fails when
#   1. a file in one root references a module defined in a file in a forbidden
#      root (compile, export or runtime reference, from `mix xref graph`), or
#   2. a file names a namespace of a forbidden root that xref cannot see (for
#      example a Registry name such as Next.Systems.Paper.ImportRegistry in mica/, an
#      :"Elixir.…" atom, or a module or `config :mica, :<system>` key in config/), or
#   3. a file under mica/ or config/ contains a PaNL, VU or Eyra literal,
# unless boundary_allowlist.exs lists the file for that kind. Each entry also
# records the referenced files, the module names or the number of literal
# matches, and the check fails when these grow. When they drop it passes and asks
# for the entry to be lowered; when an entry no longer occurs it fails, so the
# list only shrinks.
#
# Usage (from core/, after `mix compile`):
#   elixir scripts/boundary_check.exs
#   elixir scripts/boundary_check.exs --write-allowlist
# --write-allowlist rewrites every entry's detail from the tree and keeps the
# reasons; new entries get a TODO reason. Review its diff: it can add coupling.
# Tests: elixir scripts/boundary_check_test.exs

Code.require_file("boundary_rules.ex", __DIR__)

defmodule BoundaryCheck do
  import BoundaryRules

  @allowlist_file "boundary_allowlist.exs"

  def main(args) do
    module_found = module_violations()
    xref_files = MapSet.new(module_found, fn {file, kind, _} -> {file, kind} end)
    found = module_found ++ name_violations(xref_files) ++ literal_violations()
    allowlist = read_allowlist(@allowlist_file)

    if "--write-allowlist" in args do
      write_allowlist(found, allowlist)
    else
      check(found, Map.new(allowlist, fn {key, {detail, _reason}} -> {key, detail} end))
    end
  end

  # {file, kind, referenced files}
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

  # {file, kind, module names}: names xref cannot see, such as a Registry name
  # atom, in files without an xref reference to that root.
  defp name_violations(xref_files) do
    owners = roots() |> Map.values() |> Enum.uniq()
    namespaces = Map.new(owners, &{&1, namespaces(&1)})

    for {root, from} <- roots(),
        to <- forbidden(from),
        file <- Path.wildcard(root <> "**/*.{ex,exs}"),
        not test_file?(file),
        not MapSet.member?(xref_files, {file, kind(to, "reference")}),
        hits = hits(file, namespaces[to]),
        hits != [] do
      {file, kind(to, "name"), hits}
    end
  end

  defp hits(file, namespaces) do
    for {name, _line} <- names(File.read!(file)), in_namespace?(name, namespaces), uniq: true do
      name
    end
  end

  # {file, kind, number of matches}
  defp literal_violations do
    for {root, "mica"} <- roots(),
        file <- Path.wildcard(root <> "**/*"),
        Path.extname(file) in source_exts(),
        not test_file?(file),
        content = File.read!(file),
        {kind, regex} <- literals(),
        Regex.match?(regex, content) do
      {file, kind, length(Regex.scan(regex, content))}
    end
  end

  defp check(found, allowlist) do
    %{new: new, grown: grown, shrunk: shrunk, stale: stale} = ratchet(found, allowlist)

    Enum.each(new, fn {file, kind, detail} ->
      IO.puts(:stderr, "boundary: new #{kind} in #{file}: #{inspect(detail)}")
    end)

    Enum.each(grown, fn {file, kind, growth} ->
      IO.puts(:stderr, "boundary: #{kind} in #{file} grew: #{describe(growth)}")
    end)

    Enum.each(shrunk, fn {file, kind, drop} ->
      IO.puts(
        "boundary: #{kind} in #{file} shrank (#{describe(drop)}); lower its entry in #{@allowlist_file}"
      )
    end)

    Enum.each(stale, fn {file, kind} ->
      IO.puts(:stderr, "boundary: #{file} (#{kind}) is fixed; remove it from #{@allowlist_file}")
    end)

    IO.puts(
      "boundary: #{map_size(allowlist)} allowlisted (#{allowed_files(allowlist)} files), " <>
        "#{length(new)} new, #{length(grown)} grown, #{length(shrunk)} shrunk, #{length(stale)} stale"
    )

    if new != [] or grown != [] or stale != [], do: System.halt(1)
  end

  defp describe({from, to}) when is_integer(from), do: "#{from} -> #{to} matches"
  defp describe({from, to}), do: "#{inspect(from)} -> #{inspect(to)}"
  defp describe(list), do: inspect(list)

  defp allowed_files(allowlist),
    do: allowlist |> Map.keys() |> Enum.map(&elem(&1, 0)) |> Enum.uniq() |> length()

  defp write_allowlist(found, allowlist) do
    sections =
      found
      |> Enum.sort()
      |> Enum.group_by(fn {file, _, _} -> section(file) end)

    body =
      Enum.map_join([:code, :config], ",\n", fn section ->
        entries =
          sections
          |> Map.get(section, [])
          |> Enum.map_join(",\n", fn {file, kind, detail} ->
            reason =
              case allowlist do
                %{{^file, ^kind} => {_detail, reason}} -> reason
                _ -> "TODO reason"
              end

            "{#{inspect(file)}, #{inspect(kind)}, #{inspect(detail, limit: :infinity)}, #{inspect(reason)}}"
          end)

        "#{section}: [\n#{entries}\n]"
      end)

    # Formatted, because .formatter.exs includes "*.{ex,exs}" at core/.
    source = """
    # Existing Nova migration boundary violations (plan rule 2), checked by
    # scripts/boundary_check.exs. Entries may only shrink. Format:
    # {file, kind, detail, reason}; detail is what the file had when it was listed:
    # the referenced files (*_reference), the module names (*_name) or the number of
    # literal matches. code: mica/, next/ and mica_saas/; config: config/.
    [
    #{body}
    ]
    """

    File.write!(@allowlist_file, [Code.format_string!(source), "\n"])

    IO.puts("boundary: wrote #{length(found)} entries to #{@allowlist_file}")
  end
end

BoundaryCheck.main(System.argv())
