defmodule Systems.Zircon.Screening.ImportSessionView do
  use CoreWeb, :embedded_live_view

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Spinner
  alias Frameworks.Pixel.Tag
  alias Systems.Paper
  alias Systems.Zircon

  def get_model(:not_mounted_at_router, %{"session_id" => session_id}, _socket) do
    preload = Paper.RISImportSessionModel.preload_graph(:reference_file)
    Paper.Public.get_import_session!(session_id, preload)
  end

  @impl true
  def mount(
        :not_mounted_at_router,
        session,
        socket
      ) do
    title = Map.get(session, "title", nil)
    {:ok, socket |> assign(title: title)}
  end

  def handle_view_model_updated(socket) do
    socket
  end

  @impl true
  def handle_event("abort", _params, %{assigns: %{model: session}} = socket) do
    Zircon.Public.abort_import!(session)
    {:noreply, socket}
  end

  def handle_event("commit_import", _params, %{assigns: %{model: session}} = socket) do
    Paper.Public.commit_import_session!(session)
    {:noreply, socket}
  end

  def handle_event("retry", _params, %{assigns: %{model: _session}} = socket) do
    # TODO: Implement retry logic for failed imports
    # This would need to reset the session and restart the import job
    {:noreply, socket}
  end

  @impl true
  def handle_info({:signal_test, _}, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-4 sm:gap-8" data-testid="import-session-view">
      <%= if @title do %>
        <div class="flex flex-row items-center gap-6">
          <Text.title2 margin=""><%= @title %></Text.title2>
          <%= if Map.has_key?(@vm, :filename) do %>
            <Tag.tag text={@vm.filename} />
          <% end %>
        </div>
      <% else %>
        <%= if Map.has_key?(@vm, :filename) do %>
          <div>
            <Tag.tag text={@vm.filename} />
          </div>
        <% end %>
      <% end %>
      <%= for {block_type, opts} <- @vm.stack do %>
        <%= render_block(block_type, assign(assigns, block_type, opts)) %>
      <% end %>
    </div>
    """
  end

  # Block render functions

  defp render_block(:processing_status, assigns) do
    ~H"""
    <div class="flex items-center gap-3 py-4" data-testid="processing-status-block">
      <%= if @processing_status.show_spinner do %>
        <Spinner.static color="primary" />
      <% end %>
      <Text.body><%= @processing_status.message %></Text.body>
    </div>
    """
  end

  # Status-specific blocks

  defp render_block(:failed, assigns) do
    ~H"""
      <Text.body><%= @failed.message %></Text.body>
    """
  end

  defp render_block(:succeeded, assigns) do
    ~H"""
      <Text.body><%= @succeeded.message %></Text.body>
    """
  end

  defp render_block(:aborted, assigns) do
    ~H"""
      <Text.body><%= @aborted.message %></Text.body>
    """
  end

  # Phase-specific blocks for prompting

  defp render_block(:prompting_empty, assigns) do
    ~H"""
    <div data-testid="prompting-empty-block">
      <Text.body><%= @prompting_empty.description %></Text.body>
    </div>
    """
  end

  defp render_block(:prompting_errors, assigns) do
    ~H"""
    <div data-testid="prompting-errors-block">
      <Text.title4>
        <%= @prompting_errors.title %>
        <span class="text-primary ml-1"><%= @prompting_errors.count %></span>
      </Text.title4>
      <div class="mt-4">
        <%= live_render(@socket, Systems.Zircon.Screening.ImportSessionErrorsView,
          id: "errors_view",
          session: %{
            "session" => @model
          }
        ) %>
      </div>
    </div>
    """
  end

  defp render_block(:prompting_new_papers, assigns) do
    ~H"""
    <div data-testid="prompting-new-papers-block">
      <Text.title4>
        <%= @prompting_new_papers.title %>
        <span class="text-primary ml-1"><%= @prompting_new_papers.count %></span>
      </Text.title4>
      <div class="mt-4">
        <%= live_render(@socket, Systems.Zircon.Screening.ImportSessionNewPapersView,
          id: "new_papers_view",
          session: %{
            "session" => @model
          }
        ) %>
      </div>
    </div>
    """
  end

  defp render_block(:buttons, assigns) do
    ~H"""
    <div data-testid="buttons-block">
      <Button.dynamic_bar buttons={@buttons} />
    </div>
    """
  end
end
