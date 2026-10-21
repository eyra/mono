defmodule Systems.Assignment.SetupExporter.URLSource do
  @moduledoc """
  Packmatic source that downloads a URL like `{:url, url}`, but fails with
  `{:too_large, max_bytes}` as soon as more than `max_bytes` have arrived, so one
  oversized asset can't bloat the setup export. Packmatic's own URL source has no
  size limit.

  Used in a manifest entry as `source: {Systems.Assignment.SetupExporter.URLSource, {url, max_bytes}}`.
  """
  @behaviour Packmatic.Source

  alias Packmatic.Source.URL

  @enforce_keys [:source, :received, :max_bytes]
  defstruct @enforce_keys

  @impl true
  def validate({url, max_bytes}) when is_integer(max_bytes) and max_bytes >= 0,
    do: URL.validate(url)

  def validate(_), do: {:error, :invalid}

  @impl true
  def init({url, max_bytes}) do
    with {:ok, source} <- URL.init(url) do
      {:ok, %__MODULE__{source: source, received: :counters.new(1, []), max_bytes: max_bytes}}
    end
  end

  @impl true
  def read(%__MODULE__{source: source} = state) do
    case URL.read(source) do
      data when is_binary(data) or is_list(data) -> count(state, data)
      result -> result
    end
  end

  defp count(
         %{source: %URL{reader_pid: reader_pid}, received: received, max_bytes: max_bytes},
         data
       ) do
    :counters.add(received, 1, IO.iodata_length(data))

    if :counters.get(received, 1) > max_bytes do
      :ok = :gen_statem.stop(reader_pid)
      {:error, {:too_large, max_bytes}}
    else
      data
    end
  end
end
