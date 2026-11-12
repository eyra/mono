defmodule Systems.Notify.ChannelName do
  @moduledoc """
  The channel of a `Systems.Notify.MessageModel`: a string column whose names
  are checked against `Mica.SaaS.notify_channels/0` at runtime, not at compile
  time.

  - `cast/1` accepts an atom or a string that names a channel of the
    composition and returns the atom. Any other name is an error.
  - `dump/1` writes the name as a string.
  - `load/1` returns the atom for a channel of the composition. A stored name
    the composition doesn't have loads as the string itself, so the row still
    loads and only its own message fails (`Systems.Notify.Channel.adapter/1`
    returns `{:error, :unknown_channel}`).
  """
  use Ecto.Type

  @impl true
  def type, do: :string

  @impl true
  def cast(name) when is_atom(name) or is_binary(name) do
    case known(name) do
      nil -> :error
      channel -> {:ok, channel}
    end
  end

  def cast(_), do: :error

  @impl true
  def dump(name) when is_atom(name) and not is_nil(name), do: {:ok, Atom.to_string(name)}
  def dump(name) when is_binary(name), do: {:ok, name}
  def dump(_), do: :error

  @impl true
  def load(name) when is_binary(name), do: {:ok, known(name) || name}
  def load(_), do: :error

  defp known(name) do
    name = to_string(name)
    Mica.SaaS.notify_channels() |> Map.keys() |> Enum.find(&(Atom.to_string(&1) == name))
  end
end
