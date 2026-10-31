# The env-name parity check; run it with scripts/env_names.exs.

defmodule EnvNames do
  @accepted_file "scripts/env_names_accepted.exs"

  # The runtime config and the helpers it hands the environment to.
  @runtime_files ["config/runtime.exs", "mica/lib/core/runtime_config.ex"]
  @lib_roots ["mica", "next", "mica_saas"]
  @release_scripts ["rel/env.sh.eex", "rel/vm.args.eex"]
  # Read by the start script `mix release` generates (bin/core).
  @release_names ~w(RELEASE_COOKIE RELEASE_NODE RELEASE_DISTRIBUTION RELEASE_MODE RELEASE_TMP
                    RELEASE_VM_ARGS RELEASE_REMOTE_VM_ARGS RELEASE_SYS_CONFIG RELEASE_BOOT_SCRIPT
                    RELEASE_BOOT_SCRIPT_CLEAN)
  # Read while the release is built; setting them at runtime changes nothing.
  @build_files ["config/config.exs", "config/prod.exs"]

  def main(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [prod_unit: :string, staging_app: :string, staging_secrets: :string]
      )

    prod_unit = opts[:prod_unit] || usage!()
    app = opts[:staging_app] || "eyra-next-staging"

    secrets =
      case opts[:staging_secrets] do
        nil -> fly_secrets!(app)
        path -> File.read!(path)
      end

    {toml_file, toml} = fly_toml!(app)

    unit = File.read!(prod_unit)

    sides = %{
      prod: unit_names(unit),
      staging:
        MapSet.union(fly_env_names(toml), secret_names(secrets))
        |> MapSet.union(deploy_env_names(workflows(), toml_file))
    }

    report =
      sides
      |> compare(read_names(), build_time_names(), accepted(@accepted_file))
      |> Map.put(:conditional, conditional_unit_names(unit))

    IO.puts(format(report, app))
    if failed?(report), do: System.halt(1)
  end

  defp usage! do
    IO.puts(
      :stderr,
      "usage: elixir scripts/env_names.exs --prod-unit <bundle.service> " <>
        "[--staging-app <fly app> | --staging-secrets <file>]"
    )

    System.halt(2)
  end

  ## Sources

  @doc "Names a systemd unit sets with `Environment=\"NAME=…\"`."
  def unit_names(text) do
    ~r/^\s*Environment="?([A-Za-z_][A-Za-z0-9_]*)=/m
    |> Regex.scan(text, capture: :all_but_first)
    |> names()
  end

  @doc """
  Names a unit template sets inside a Jinja `{% if %}` block, so only when the
  inventory defines the variable.
  """
  def conditional_unit_names(text) do
    text
    |> String.split("\n")
    |> Enum.reduce({0, []}, fn line, {depth, acc} ->
      acc =
        if depth > 0,
          do:
            Regex.scan(~r/^\s*Environment="?([A-Za-z_][A-Za-z0-9_]*)=/, line,
              capture: :all_but_first
            ) ++ acc,
          else: acc

      opened = length(Regex.scan(~r/\{%-?\s*if\b/, line))
      closed = length(Regex.scan(~r/\{%-?\s*endif\b/, line))
      {depth + opened - closed, acc}
    end)
    |> elem(1)
    |> names()
  end

  @doc "Names in the `[env]` table of a fly.toml."
  def fly_env_names(toml) do
    toml
    |> String.split("\n")
    |> Enum.reduce({false, []}, fn line, {in_env, acc} ->
      line = String.trim(line)

      cond do
        String.starts_with?(line, "[") ->
          {line == "[env]", acc}

        in_env and line =~ ~r/^[A-Za-z_][A-Za-z0-9_]*\s*=/ ->
          {in_env, [line |> String.split("=") |> hd() |> String.trim() | acc]}

        true ->
          {in_env, acc}
      end
    end)
    |> elem(1)
    |> MapSet.new()
  end

  @doc "Names in the output of `fly secrets list --json`."
  def secret_names(json) do
    json |> JSON.decode!() |> Enum.map(&(&1["Name"] || &1["name"])) |> MapSet.new()
  end

  @doc "Names a deploy workflow passes with `--env NAME=…` to `flyctl deploy -c <toml_file>`."
  def deploy_env_names(workflows, toml_file) do
    for text <- workflows, text =~ "-c #{toml_file}", reduce: MapSet.new() do
      acc ->
        ~r/--env ([A-Za-z_][A-Za-z0-9_]*)=/
        |> Regex.scan(text, capture: :all_but_first)
        |> names()
        |> MapSet.union(acc)
    end
  end

  @doc """
  Names the release reads, as `%{name => :required | :optional}`. In the
  runtime files every upper-case string literal is a name; `System.fetch_env!/1`
  and `fetch!(env, name)` make it required.
  """
  def read_names do
    runtime = Enum.map(@runtime_files, &File.read!/1)
    lib = Enum.map(lib_files(), &File.read!/1)
    scripts = Enum.map(@release_scripts, &File.read!/1)

    shell =
      for text <- scripts,
          [name] <- Regex.scan(~r/\$\{?([A-Z_][A-Z0-9_]*)/, text, capture: :all_but_first),
          into: %{},
          do: {name, :optional}

    [Map.new(@release_names, &{&1, :optional}), shell | Enum.map(lib, &env_reads/1)]
    |> Enum.concat(Enum.map(runtime, &literal_names/1))
    |> Enum.reduce(%{}, &merge_reads/2)
  end

  def build_time_names do
    @build_files
    |> Enum.map(&(&1 |> File.read!() |> env_reads()))
    |> Enum.reduce(%{}, &merge_reads/2)
    |> Map.keys()
    |> MapSet.new()
  end

  @doc "Names in `System.get_env/fetch_env` calls with a literal name."
  def env_reads(source) do
    source
    |> Code.string_to_quoted!()
    |> Macro.prewalk(%{}, fn
      {{:., _, [{:__aliases__, _, [:System]}, fun]}, _, [name | _]} = node, acc
      when fun in [:get_env, :fetch_env, :fetch_env!] and is_binary(name) ->
        {node, merge_reads(%{name => requirement(fun)}, acc)}

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  end

  @doc "Every upper-case string literal, required when read with fetch_env!/fetch!."
  def literal_names(source) do
    ast = Code.string_to_quoted!(source)

    {_, literals} =
      Macro.prewalk(ast, %{}, fn
        name, acc when is_binary(name) ->
          if name =~ ~r/^[A-Z][A-Z0-9]*_[A-Z0-9_]*$/,
            do: {name, Map.put_new(acc, name, :optional)},
            else: {name, acc}

        node, acc ->
          {node, acc}
      end)

    {_, required} =
      Macro.prewalk(ast, %{}, fn
        {{:., _, [{:__aliases__, _, [:System]}, :fetch_env!]}, _, [name]} = node, acc
        when is_binary(name) ->
          {node, Map.put(acc, name, :required)}

        {:fetch!, _, [_env, name]} = node, acc when is_binary(name) ->
          {node, Map.put(acc, name, :required)}

        {{:., _, [_, :fetch!]}, _, [_env, name]} = node, acc when is_binary(name) ->
          {node, Map.put(acc, name, :required)}

        node, acc ->
          {node, acc}
      end)

    Map.merge(literals, required)
  end

  defp requirement(:fetch_env!), do: :required
  defp requirement(_), do: :optional

  defp merge_reads(reads, acc) do
    Map.merge(acc, reads, fn _, a, b -> if :required in [a, b], do: :required, else: :optional end)
  end

  defp lib_files do
    @lib_roots
    |> Enum.flat_map(&Path.wildcard("#{&1}/**/*.ex"))
    |> Enum.reject(&(&1 =~ ~r{/test/|/lib/mix/}))
    |> Kernel.--(@runtime_files)
  end

  defp workflows, do: Enum.map(Path.wildcard("../.github/workflows/*.yml"), &File.read!/1)

  defp fly_toml!(app) do
    Path.wildcard("fly*.toml")
    |> Enum.map(&{&1, File.read!(&1)})
    |> Enum.find(fn {_, toml} -> toml =~ ~r/^app\s*=\s*['"]#{Regex.escape(app)}['"]/m end) ||
      raise "no fly*.toml in #{File.cwd!()} for app #{app}"
  end

  defp fly_secrets!(app) do
    case System.cmd("fly", ["secrets", "list", "-a", app, "--json"], stderr_to_stdout: true) do
      {json, 0} -> json
      {out, status} -> raise "fly secrets list -a #{app} failed (#{status}): #{out}"
    end
  end

  defp names(scan), do: scan |> List.flatten() |> MapSet.new()

  ## Comparison

  def accepted(file) do
    if File.exists?(file), do: file |> Code.eval_file() |> elem(0), else: %{}
  end

  @doc """
  Compares the names of `sides` (`%{prod: set, staging: set}`) with what the
  release reads (`%{name => :required | :optional}`).
  """
  def compare(%{prod: prod, staging: staging}, reads, build_time, accepted) do
    read = reads |> Map.keys() |> MapSet.new()
    required = for {name, :required} <- reads, into: MapSet.new(), do: name

    differences = %{
      read_prod_only: read |> MapSet.intersection(prod) |> MapSet.difference(staging),
      read_staging_only: read |> MapSet.intersection(staging) |> MapSet.difference(prod),
      unread_prod: MapSet.difference(prod, read),
      unread_staging: MapSet.difference(staging, read)
    }

    %{
      required_missing: %{
        prod: MapSet.difference(required, prod),
        staging: MapSet.difference(required, staging)
      },
      differences: differences,
      build_time: build_time,
      unaccepted:
        differences
        |> Map.values()
        |> Enum.reduce(MapSet.new(), &MapSet.union/2)
        |> Enum.reject(&Map.has_key?(accepted, &1))
        |> MapSet.new(),
      stale_accepted:
        accepted
        |> Map.keys()
        |> Enum.reject(fn name ->
          Enum.any?(Map.values(differences), &MapSet.member?(&1, name))
        end)
        |> MapSet.new(),
      counts: %{read: MapSet.size(read), prod: MapSet.size(prod), staging: MapSet.size(staging)}
    }
  end

  def failed?(report) do
    MapSet.size(report.required_missing.prod) > 0 or
      MapSet.size(report.required_missing.staging) > 0 or
      MapSet.size(report.unaccepted) > 0
  end

  def format(report, app) do
    d = report.differences

    mark = fn name ->
      if MapSet.member?(report.unaccepted, name), do: "#{name} (new)", else: name
    end

    build = fn name ->
      if MapSet.member?(report.build_time, name), do: "#{name} (build time)", else: name
    end

    list = fn set, f ->
      if MapSet.size(set) == 0, do: "-", else: set |> Enum.sort() |> Enum.map_join(" ", f)
    end

    """
    Environment names: the release reads #{report.counts.read}, production sets #{report.counts.prod}, staging (#{app}) sets #{report.counts.staging}.

    Required, but not set:
      production: #{list.(report.required_missing.prod, & &1)}
      staging:    #{list.(report.required_missing.staging, & &1)}

    Read by the release, but set in one deployment only:
      production only: #{list.(d.read_prod_only, mark)}
      staging only:    #{list.(d.read_staging_only, mark)}

    Set, but not read at runtime:
      production: #{list.(d.unread_prod, &mark.(build.(&1)))}
      staging:    #{list.(d.unread_staging, &mark.(build.(&1)))}

    Set by production only when its inventory defines the variable: #{list.(Map.get(report, :conditional, MapSet.new()), & &1)}

    Not listed in #{@accepted_file}: #{list.(report.unaccepted, & &1)}
    Listed there, but no longer a difference: #{list.(report.stale_accepted, & &1)}
    """
  end
end
