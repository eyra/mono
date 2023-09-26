defmodule Systems.Feldspar.AppPage do
  alias Systems.Feldspar
  use CoreWeb, :live_view

  @impl true
  def mount(%{"id" => app_id}, _session, socket) do
    app_url = Feldspar.Public.get_public_url(app_id) <> "/index.html"

    {:ok, assign(socket, app_url: app_url, error: nil)}
  end

  @impl true
  def handle_uri(socket), do: socket

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col w-full h-screen">
      <%!-- Ensure that updates don't alter the hierarchy in front of the iframe.
      Changing the preceding siblings of the iframe would result in a reload of the iframe
      due to Morphdom (https://github.com/patrick-steele-idem/morphdom/issues/200).
        --%>
      <div>
        <div :if={@error} class="bg-[#ff00ff] text-white p-8 text-xl"><%= @error %></div>
      </div>
      <div phx-update="ignore"  id="web-app-frame" phx-hook="FeldsparApp">
      <iframe src={@app_url} class="grow  w-full h-screen"></iframe>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("app_event", params, socket) do
    {:noreply, assign(socket, :error, "Unsupported message: #{inspect(params)}")}
  end
end
