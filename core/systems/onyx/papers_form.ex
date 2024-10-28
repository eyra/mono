defmodule Systems.Onyx.PapersForm do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader, accept: ~w(.ris)

  @impl true
  def process_file(socket, {_path, _url, _original_filename}) do
    socket
  end

  @impl true
  def update(_params, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>TBD</div>
    """
  end
end
