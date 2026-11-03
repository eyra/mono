defmodule BoundaryRules do
  @moduledoc """
  The rules of the Nova migration boundary check (plan rule 2), shared by
  scripts/boundary_check.exs (authoritative, in CI) and the credo check
  `Credo.Check.Warning.MicaBoundary` (early feedback). Paths are relative to core/.
  """

  # Root directory => owner. config/ is the shared config, which belongs to Mica
  # until code-split gives each SaaS its own; it defines no modules, so only its
  # names and literals are checked.
  @roots %{
    "mica/" => "mica",
    "next/" => "next",
    "mica_saas/" => "mica_saas",
    "config/" => "mica"
  }
  # Owner => owners it may not reference. Tests under <root>test/ are not checked.
  @forbidden %{
    "mica" => ["next", "mica_saas"],
    "next" => ["mica_saas"],
    "mica_saas" => ["next"]
  }
  @source_exts ~w(.ex .exs .heex .eex)

  def roots, do: @roots
  def forbidden(owner), do: Map.fetch!(@forbidden, owner)
  def source_exts, do: @source_exts

  # A function, not a module attribute: OTP 28 regexes cannot be escaped into attributes.
  # Scanned in the files of Mica's roots only: a SaaS may contain instance specifics.
  def literals do
    [
      panl_atom: ~r/:panl\b/,
      panl_string: ~r/"(Panl|PaNL|PANL)"/,
      panl_domain: ~r/panl\.nl/,
      eyra_domain: ~r/eyra\.co\b/,
      eyra_service: ~r/@eyra\.service/,
      vu_code: ~r/\bvu_sbe_\w+|\bgenerate_vu\b|VUDaySchedule/
    ]
  end

  def owner(path) do
    Enum.find_value(@roots, fn {root, owner} -> if String.starts_with?(path, root), do: owner end)
  end

  def forbidden?(nil, _to), do: false
  def forbidden?(from, to), do: to in forbidden(from)

  def kind(owner, what), do: String.to_atom(owner <> "_" <> what)

  def test_file?(path), do: Enum.any?(Map.keys(@roots), &String.starts_with?(path, &1 <> "test/"))

  # Owner => the top-level namespaces its modules are in. Mica owns Mica, MicaWeb,
  # Systems and Frameworks, and every name no SaaS owns. Mix tasks keep Mix.Tasks.
  @saas_namespaces %{
    "next" => ["Next", "NextWeb"],
    "mica_saas" => ["MicaSaas", "MicaSaasWeb"]
  }

  @doc """
  Namespaces of the modules defined in the roots of `owner`, from their
  top-level `defmodule`s: `Systems.<System>` for Mica's systems, the whole SaaS
  namespaces (`Next`, `NextWeb`, `MicaSaas`, `MicaSaasWeb`), and the exact module
  for anything else. A SaaS system also gets `{"Systems.<System>", full name}`,
  so that a `config :mica, :<system>` key resolves to it.
  """
  def namespaces(owner) do
    mica_systems = if owner == "mica", do: [], else: mica_systems()

    for {root, ^owner} <- @roots,
        {_file, name} <- defined_modules(root, "**/*.ex"),
        namespace <- namespaces_of(String.split(name, "."), mica_systems),
        uniq: true,
        do: namespace
  end

  defp namespaces_of(["Systems", system | _], _mica_systems), do: ["Systems." <> system]

  defp namespaces_of([top, "Systems", system | _], mica_systems)
       when top in ["Next", "MicaSaas"] do
    key = "Systems." <> system

    if key in mica_systems,
      do: [top],
      else: [top, {key, Enum.join([top, "Systems", system], ".")}]
  end

  defp namespaces_of([top | _] = parts, _mica_systems) do
    if top in Enum.concat(Map.values(@saas_namespaces)), do: [top], else: [Enum.join(parts, ".")]
  end

  defp mica_systems do
    for {_file, "Systems." <> rest} <- defined_modules("mica/", "**/*.ex"),
        uniq: true,
        do: "Systems." <> hd(String.split(rest, "."))
  end

  # {file, name} of the top-level `defmodule`s in the files under `root` matching `glob`.
  defp defined_modules(root, glob) do
    for file <- Path.wildcard(root <> glob),
        [_, name] <- Regex.scan(~r/^defmodule\s+([\w.]+)/m, File.read!(file)),
        do: {file, name}
  end

  def in_namespace?(name, namespaces), do: owned_name(name, namespaces) != nil

  @doc """
  The name as its owner's module, when `name` is in `namespaces`, or nil. The
  name of a `config :mica, :<system>` key (`Systems.<System>`) resolves to the
  SaaS system (`Next.Systems.<System>`).
  """
  def owned_name(name, namespaces) do
    Enum.find_value(namespaces, fn
      {^name, full} -> full
      {_key, _full} -> nil
      namespace -> if name == namespace or String.starts_with?(name, namespace <> "."), do: name
    end)
  end

  @doc """
  Top-level modules defined outside their owner's namespaces, as
  `{file, module}`, tests included: a module under next/ must be in `Next` or
  `NextWeb`, one under mica_saas/ in `MicaSaas` or `MicaSaasWeb` (Mix tasks may
  keep `Mix.Tasks`), and one under mica/ or config/ in no SaaS namespace.
  """
  def misplaced_modules do
    saas_tops = Enum.concat(Map.values(@saas_namespaces))

    for {root, owner} <- @roots,
        {file, name} <- defined_modules(root, "**/*.{ex,exs}"),
        top = hd(String.split(name, ".")),
        misplaced?(owner, top, name, saas_tops),
        do: {file, name}
  end

  defp misplaced?("mica", top, _name, saas_tops), do: top in saas_tops

  defp misplaced?(owner, top, name, _saas_tops),
    do: top not in @saas_namespaces[owner] and not String.starts_with?(name, "Mix.Tasks.")

  @doc """
  The module names in `source` with their lines: aliases (grouped aliases
  expanded, aliased short names resolved), `:"Elixir.…"` atoms, and
  `config :mica, :<system>` keys as `Systems.<System>`.
  """
  def names(source) do
    {:ok, ast} = Code.string_to_quoted(source)
    aliases = aliases(ast)
    {_, names} = Macro.prewalk(ast, [], &collect(&1, &2, aliases))
    names |> Enum.uniq() |> Enum.sort()
  end

  defp collect({{:., meta, [{:__aliases__, _, base}, :{}]}, _, children}, acc, aliases) do
    names =
      for {:__aliases__, _, parts} <- children, full = resolve(base ++ parts, aliases), full do
        {full, meta[:line]}
      end

    # Skip the children: on their own they are short names.
    {:ok, names ++ acc}
  end

  defp collect({:__aliases__, meta, parts} = node, acc, aliases) do
    case resolve(parts, aliases) do
      nil -> {node, acc}
      full -> {node, [{full, meta[:line]} | acc]}
    end
  end

  defp collect({:config, meta, [:mica, key | _]} = node, acc, _aliases) when is_atom(key) do
    {node, [{"Systems." <> Macro.camelize(Atom.to_string(key)), meta[:line]} | acc]}
  end

  defp collect(atom, acc, _aliases) when is_atom(atom) do
    case Atom.to_string(atom) do
      "Elixir." <> name -> {atom, [{name, nil} | acc]}
      _ -> {atom, acc}
    end
  end

  defp collect(node, acc, _aliases), do: {node, acc}

  # Short name => full name, from the file's `alias` lines, ignoring lexical scope.
  defp aliases(ast) do
    {_, aliases} =
      Macro.prewalk(ast, %{}, fn
        {:alias, _, [{{:., _, [{:__aliases__, _, base}, :{}]}, _, children} | _]} = node, acc ->
          {node,
           Enum.reduce(children, acc, fn
             {:__aliases__, _, parts}, acc -> put_alias(acc, base ++ parts, nil)
             _, acc -> acc
           end)}

        {:alias, _, [{:__aliases__, _, parts} | opts]} = node, acc ->
          as = with [opts] <- opts, {:__aliases__, _, [as]} <- opts[:as], do: as, else: (_ -> nil)
          {node, put_alias(acc, parts, as)}

        node, acc ->
          {node, acc}
      end)

    aliases
  end

  defp put_alias(acc, parts, as) do
    if Enum.all?(parts, &is_atom/1),
      do: Map.put(acc, as || List.last(parts), Enum.join(parts, ".")),
      else: acc
  end

  defp resolve([first | rest] = parts, aliases) do
    cond do
      not Enum.all?(parts, &is_atom/1) -> nil
      Map.has_key?(aliases, first) -> Enum.join([aliases[first] | rest], ".")
      true -> Enum.join(parts, ".")
    end
  end

  @doc """
  Compares found violations `{file, kind, detail}` with the allowlist, a map of
  `{file, kind} => detail`. A detail is a list (the referenced files or module
  names) or a count (literal matches). Returns
    * `:new`: violations in a file and kind without an entry,
    * `:grown`: `{file, kind, growth}` for entries with new targets or more matches,
    * `:shrunk`: `{file, kind, drop}` for entries with fewer targets or matches,
    * `:stale`: `{file, kind}` of entries that no longer occur.
  `:new`, `:grown` and `:stale` fail the check; `:shrunk` asks for a lower entry.
  """
  def ratchet(found, allowlist) do
    found_keys = MapSet.new(found, fn {file, kind, _} -> {file, kind} end)

    compared =
      for {file, kind, detail} <- found, Map.has_key?(allowlist, {file, kind}) do
        {file, kind, compare(Map.fetch!(allowlist, {file, kind}), detail)}
      end

    %{
      new: Enum.reject(found, fn {file, kind, _} -> Map.has_key?(allowlist, {file, kind}) end),
      grown: for({file, kind, {grown, _}} <- compared, grown != nil, do: {file, kind, grown}),
      shrunk: for({file, kind, {_, shrunk}} <- compared, shrunk != nil, do: {file, kind, shrunk}),
      stale:
        allowlist |> Map.keys() |> Enum.reject(&MapSet.member?(found_keys, &1)) |> Enum.sort()
    }
  end

  # {growth or nil, drop or nil}
  defp compare(allowed, found) when is_integer(allowed) and is_integer(found) do
    cond do
      found > allowed -> {{allowed, found}, nil}
      found < allowed -> {nil, {allowed, found}}
      true -> {nil, nil}
    end
  end

  defp compare(allowed, found) when is_list(allowed) and is_list(found) do
    {nil_if_empty(found -- allowed), nil_if_empty(allowed -- found)}
  end

  defp compare(allowed, found), do: {{allowed, found}, nil}

  defp nil_if_empty([]), do: nil
  defp nil_if_empty(list), do: list

  @doc """
  Reads the allowlist: `[code: entries, config: entries]`, each entry
  `{file, kind, detail, reason}`. Returns `{file, kind} => {detail, reason}`.
  """
  def read_allowlist(file) do
    if File.exists?(file) do
      {sections, _} = Code.eval_file(file)

      for {_section, entries} <- sections, {path, kind, detail, reason} <- entries, into: %{} do
        {{path, kind}, {detail, reason}}
      end
    else
      %{}
    end
  end

  def section(path), do: if(String.starts_with?(path, "config/"), do: :config, else: :code)
end
