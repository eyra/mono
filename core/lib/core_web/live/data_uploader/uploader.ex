defmodule CoreWeb.DataUploader.Uploader do
  use CoreWeb, :live_view
  alias Core.DataUploader
  # alias EyraUI.Form.Checkbox
  # alias Surface.Components.Form

  defmodule UploadChangeset do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field(:terms_accepted, :boolean)
    end

    def changeset(params) do
      %UploadChangeset{}
      |> cast(params, [:terms_accepted])
      |> validate_required([:terms_accepted])
    end
  end

  data(result, :any)
  data(script, :any)
  data(ready, :boolean, default: false)

  def mount(%{"id" => script_id}, _session, socket) do
    client_script = DataUploader.get_client_script!(script_id)

    {:ok,
     socket
     |> assign(:result, nil)
     |> assign(:client_script, client_script)
     |> assign(:changeset, UploadChangeset.changeset(%{}))}
  end

  @impl true
  def handle_event("script-initialized", _params, socket) do
    {:noreply, socket |> assign(:ready, true)}
  end

  def handle_event(
        "script-result",
        %{"data" => data},
        %{assigns: %{client_script: client_script}} = socket
      ) do
    DataUploader.store_results(client_script, data)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Data Uploader</h1>

    <div id="controls" phx-hook="PythonUploader">
      <p :if={{not @ready}} id="loading-indicator">Loading...</p>
      <div :if={{@ready}}>
        <input type="file" id="fileItem">
        <button data-role="process-trigger">Process</button>
      </div>
      <div class="results" hidden>
        <p class="summary" />
        <p class="extracted" />
        <button data-role="share-trigger">Share results</button>
      </div>
      <pre><code>{{ @client_script.script }}</code></pre>
    </div>


    """
  end
end
