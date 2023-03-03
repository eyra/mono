defmodule Frameworks.Utility.EctoTuple do
  use Ecto.Type
  def type, do: :list

  def cast({key, value} = tuple) when is_atom(key) and is_binary(value) do
    {:ok, tuple}
  end

  def cast(_), do: :error

  def load([key, value]) when is_binary(key) and is_binary(value) do
    {:ok, {String.to_existing_atom(key), value}}
  end

  def load(_), do: :error

  def dump({key, value}) when is_atom(key) and is_binary(value) do
    {:ok, [Atom.to_string(key), value]}
  end

  def dump(_), do: :error
end
