defmodule Systems.Graphite.LeaderboardUploadForm do
  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent
  use CoreWeb.FileUploader, accept: ~w(.csv)

  alias Frameworks.Pixel.Text

  alias Systems.{
    Graphite
  }

  @impl true
  def update(
        %{
          id: id,
          leaderboard: leaderboard,
          uri_origin: uri_origin,
          viewport: viewport,
          breakpoint: breakpoint
        },
        socket
      ) do
    columns = ["submission-id", "github_commit_url" | leaderboard.metrics]

    {
      :ok,
      socket
      |> assign(
        id: id,
        columns: columns,
        leaderboard: leaderboard,
        uri_origin: uri_origin,
        viewport: viewport,
        breakpoint: breakpoint,
        placeholder: dgettext("eyra-graphite", "label.upload_file"),
        select_button: dgettext("eyra-graphite", "label.select"),
        replace_button: dgettext("eyra-graphite", "label.replace_file"),
        csv_local_path: nil,
        csv_remote_file: nil,
        csv_lines: nil,
        parsed_results: nil
      )
      |> init_file_uploader(:csv)
      |> prepare_submissions()
      |> prepare_submit_button("submit")
      |> prepare_process_button(dgettext("eyra-graphite", "label.processing"))
    }
  end

  defp prepare_submissions(%{assigns: %{leaderboard: %{tool: tool}}} = socket) do
    assign(socket, :submissions, Graphite.Public.get_submissions(tool))
  end

  defp prepare_process_button(socket, label) do
    process_button = %{
      action: %{type: :send, event: "process"},
      face: %{type: :primary, label: label}
    }

    assign(socket, process_button: process_button)
  end

  defp prepare_submit_button(socket, label) do
    submit_button = %{
      action: %{type: :send, event: "submit"},
      face: %{type: :primary, label: label}
    }

    assign(socket, submit_button: submit_button)
  end

  @impl true
  def process_file(socket, {path, _url, original_file_name}) do
    socket
    |> assign(csv_local_path: path, csv_remote_file: original_file_name)
  end

  @impl true
  def handle_event(
        "process",
        _params,
        %{assigns: %{leaderboard: leaderboard, csv_local_path: csv_local_path}} = socket
      ) do
    result = Graphite.ScoresParseResult.from_file(csv_local_path, leaderboard)

    {:noreply, assign(socket, :parsed_results, result)}
  end

  def handle_event(
        "submit",
        _params,
        %{assigns: %{leaderboard: leaderboard, parsed_results: parsed_results}} = socket
      ) do
    Graphite.Public.import_scores(leaderboard, parsed_results)
    {:noreply, redirect(socket, to: ~p"/graphite/leaderboard/#{leaderboard.id}")}
  end

  def handle_event("change", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id="select_file_form" for={%{}} phx-change="change" phx-target="" >
        <div>
          <.spacing value="L" />
          <Text.title2>Scores upload</Text.title2>
          <Text.body_medium>Expecting the following columns to be present in the file: <%= Enum.join(@columns, ", ") %></Text.body_medium>
        </div>
        <div class="h-file-selector border-grey4 border-2 rounded pl-6 pr-6">
          <div class="flex flex-row items-center h-full">
            <div class="flex-grow">
              <%= if @csv_remote_file do %>
                <Text.body_large color="text-grey1"><%= @csv_remote_file %></Text.body_large>
              <% else %>
                <Text.body_large color="text-grey2"><%= @placeholder %></Text.body_large>
              <% end %>
            </div>
            <%= if @csv_remote_file do %>
              <Button.primary_label label={@replace_button} bg_color="bg-tertiary" text_color="text-grey1" field={@uploads.csv.ref} />
            <% else %>
              <Button.primary_label label={@select_button} bg_color="bg-tertiary" text_color="text-grey1" field={@uploads.csv.ref} />
            <% end %>
          </div>
          <div class="hidden">
            <.live_file_input upload={@uploads.csv} />
          </div>
        </div>
      </.form>
      <.spacing value="M" />
      <%= if @csv_local_path do %>
          <.wrap>
            <Button.dynamic {@process_button} />
          </.wrap>
      <% end %>
      <.spacing value="M" />
      <%= if @parsed_results do %>
        <Text.title3>Validate uploaded information</Text.title3>
        <Text.title4>File and leaderboard metrics</Text.title4>
        Number of submissions for leaderboard: <%= length(@submissions) %> <br />
        Number of valid submissions in file: <%= length(@parsed_results.valid) %> <br />
        Number of invalid submissions in file: <%= length(@parsed_results.rejected) %> <br />
        <.wrap>
          <Button.dynamic {@submit_button} />
        </.wrap>
      <% end %>
    </div>
    """
  end
end
