defmodule Frameworks.Utility.ViewModel do

  def merge(vm_part1, vm_part2, resolve_type \\ :append) do
    Map.merge(vm_part1, vm_part2, &resolve(&1, &2, &3, resolve_type))
  end

  defp resolve(_key, value1, value2, :append), do: append(value1, value2)
  defp resolve(_key, _value1, value2, :overwrite), do: value2
  defp resolve(_key, value1, _value2, :skip), do: value1

  def required(vm, field, default) do
    update_in(vm, [field], &(required(&1, default)))
  end

  defp required(nil, default), do: default
  defp required(existing, _), do: existing

  def append(vm, field, extra) do
    update_in(vm, [field], &(append(&1, extra)))
  end

  defp append(existing, nil), do: existing
  defp append(nil, extra), do: extra
  defp append(existing, extra) when is_list(existing), do: existing ++ extra
  defp append(existing, extra) when is_map(existing), do: Map.merge(existing, extra)
  defp append(existing, extra), do: raise "Unable to append #{existing} with #{extra}"

end
