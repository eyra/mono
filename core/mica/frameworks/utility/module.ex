defmodule Frameworks.Utility.Module do
  def optional_apply(module, function, params, default \\ nil)
      when is_atom(module) and is_atom(function) and is_list(params) do
    if function_exported?(module, function, Enum.count(params)) do
      "#{module}.#{function}/#{Enum.count(params)} called"
      apply(module, function, params)
    else
      "#{module}.#{function}/#{Enum.count(params)} skipped"
      default
    end
  end

  def get(nil, _name), do: nil

  def get(system, name) when is_atom(system),
    do: get(Atom.to_string(system), name)

  # A Mica system's module (`Systems.<System>.<name>`), or else the SaaS system's
  # (`<SaaS namespace>.Systems.<System>.<name>`, such as `Next.Systems.Student.Director`).
  def get(system, name) when is_binary(system) do
    system = Macro.camelize(system)
    mica = Module.concat(["Systems", system, name])

    if Code.ensure_loaded?(mica) do
      mica
    else
      saas = Mica.SaaS.module() |> Module.split() |> hd()
      saas_module = Module.concat([saas, "Systems", system, name])
      if Code.ensure_loaded?(saas_module), do: saas_module, else: mica
    end
  end

  def to_system(module) when is_atom(module) do
    to_system(split(module))
  end

  def to_system(["Elixir", "Systems", system | _]), do: system
  def to_system(["Elixir", _saas, "Systems", system | _]), do: system
  def to_system([system]) when is_binary(system), do: system
  def to_system(_), do: nil

  @doc "The system namespace a module is in (`[\"Systems\", \"Assignment\"]`), or nil."
  def system_namespace(module) when is_atom(module) do
    case split(module) do
      ["Elixir", "Systems", system | _] -> ["Systems", system]
      ["Elixir", saas, "Systems", system | _] -> [saas, "Systems", system]
      _ -> nil
    end
  end

  def to_model(module) when is_atom(module) do
    to_model(split(module))
  end

  # A SaaS system's model is named like a Mica system's: Next.Systems.Graphite.ToolModel
  # is "graphite_tool".
  def to_model(["Elixir", _saas, "Systems" | rest]), do: to_model(["Elixir", "Systems" | rest])

  def to_model(["Elixir", "Systems", system, item]) do
    if String.contains?(item, "Model") do
      to_model([system, String.replace(item, "Model", "")])
    else
      raise ArgumentError, "Module is not a model"
    end
  end

  def to_model(["Elixir", "Systems", system, special, item]) do
    if String.contains?(item, "Model") do
      to_model([system, special, String.replace(item, "Model", "")])
    else
      raise ArgumentError, "Module is not a model"
    end
  end

  def to_model([system, ""]), do: to_model(system)
  def to_model([system, item]), do: to_model("#{system}_#{item}")
  def to_model([system, special, item]), do: to_model("#{system}_#{special}_#{item}")
  def to_model(model) when is_binary(model), do: String.downcase(model)

  defp split(module) when is_atom(module) do
    String.split(Atom.to_string(module), ".")
  end
end
