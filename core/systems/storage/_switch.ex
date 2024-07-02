defmodule Systems.Storage.Switch do
  use Frameworks.Signal.Handler

  alias Systems.Storage

  @impl true
  def intercept({:storage_endpoint, {:monitor, _}}, %{
        storage_endpoint: storage_endpoint,
        from_pid: from_pid
      }) do
    update_page(Storage.EndpointContentPage, storage_endpoint, from_pid)
    :ok
  end

  defp update_page(page, %{id: id} = model, from_pid) do
    dispatch!({:page, page}, %{id: id, model: model, from_pid: from_pid})
  end
end
