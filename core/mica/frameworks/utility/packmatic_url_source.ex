defmodule Frameworks.Utility.PackmaticURLSource do
  @moduledoc """
  Packmatic source that downloads a URL, used instead of Packmatic's own
  `{:url, url}` source. Use it in a manifest entry as
  `source: {Frameworks.Utility.PackmaticURLSource, url}` or
  `{Frameworks.Utility.PackmaticURLSource, {url, max_bytes: n}}`.

  Packmatic 2.1's URL reader crashes (`function_clause`) on a response without
  a body, and the crash takes the process that builds the zip down with it. This
  source handles those cases as results:

    * a 200 response is the entry's content, an empty body included;
    * any other status, redirects included, fails the entry with `{:http_status, status}`;
    * with `max_bytes`, more data than that fails it with `{:too_large, max_bytes}`.

  The download runs in an unlinked task that hands over one chunk at a time and
  waits until it is read, so a slow zip consumer never piles chunks up in memory.
  Retries are off: a retried download would repeat chunks already in the zip.
  """
  @behaviour Packmatic.Source

  @enforce_keys [:task, :ref, :monitor, :received, :max_bytes]
  defstruct @enforce_keys

  @impl true
  def validate({url, opts}) when is_list(opts), do: validate(url)
  def validate(url) when is_binary(url), do: Packmatic.Source.URL.validate(url)
  def validate(_), do: {:error, :invalid}

  @impl true
  def init({url, opts}), do: start(url, Keyword.get(opts, :max_bytes))
  def init(url), do: start(url, nil)

  defp start(url, max_bytes) do
    parent = self()
    ref = make_ref()
    {:ok, task} = Task.start(fn -> download(parent, ref, url) end)

    {:ok,
     %__MODULE__{
       task: task,
       ref: ref,
       monitor: Process.monitor(task),
       received: :counters.new(1, []),
       max_bytes: max_bytes
     }}
  end

  @impl true
  def read(%__MODULE__{ref: ref, monitor: monitor} = state) do
    receive do
      {^ref, {:data, data}} -> accept(state, data)
      {^ref, :eof} -> finish(state, :eof)
      {^ref, {:error, reason}} -> finish(state, {:error, reason})
      {:DOWN, ^monitor, :process, _, reason} -> {:error, {:download_failed, reason}}
    end
  end

  defp accept(%{task: task, ref: ref, received: received, max_bytes: max_bytes} = state, data) do
    :counters.add(received, 1, IO.iodata_length(data))

    if max_bytes && :counters.get(received, 1) > max_bytes do
      Process.exit(task, :kill)
      finish(state, {:error, {:too_large, max_bytes}})
    else
      send(task, {ref, :next})
      data
    end
  end

  defp finish(%{monitor: monitor}, result) do
    Process.demonitor(monitor, [:flush])
    result
  end

  defp download(parent, ref, url) do
    parent_monitor = Process.monitor(parent)

    into = fn {:data, data}, {request, response} ->
      case response do
        %Req.Response{status: 200} ->
          send(parent, {ref, {:data, data}})
          await_next(ref, parent_monitor)
          {:cont, {request, response}}

        %Req.Response{} ->
          {:halt, {request, response}}
      end
    end

    result =
      Req.request(url: url, method: :get, redirect: false, retry: false, raw: true, into: into)

    send(parent, {ref, outcome(result)})
  end

  defp await_next(ref, parent_monitor) do
    receive do
      {^ref, :next} -> :ok
      {:DOWN, ^parent_monitor, :process, _, _} -> exit(:normal)
    end
  end

  defp outcome({:ok, %Req.Response{status: 200}}), do: :eof
  defp outcome({:ok, %Req.Response{status: status}}), do: {:error, {:http_status, status}}
  defp outcome({:error, reason}), do: {:error, reason}
end
