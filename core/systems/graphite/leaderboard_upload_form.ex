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
    columns = ["submission" | leaderboard.metrics]

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
        csv_lines: nil
      )
      |> init_file_uploader(:csv)
      |> prepare_process_button(dgettext("eyra-graphite", "label.processing"))
    }
  end

  defp prepare_process_button(socket, label) do
    process_button = %{
      action: %{type: :send, event: "process"},
      face: %{type: :primary, label: label}
    }

    assign(socket, process_button: process_button)
  end

  @impl true
  def process_file(socket, {path, _url, original_file_name}) do
    socket
    |> assign(csv_local_path: path, csv_remote_file: original_file_name)
  end

  @impl true
  def handle_event("process", _params, %{assigns: %{csv_local_path: csv_local_path}} = socket) do
    %{assigns: %{leaderboard: leaderboard}} = socket

    lines =
      csv_local_path
      |> File.stream!()
      |> CSV.decode(headers: true)

    lines_ok =
      lines
      |> Stream.filter(&filter_ok/1)
      |> Stream.map(fn {:ok, line} -> line end)
      |> Enum.filter(fn line -> check_line(line, leaderboard) end)

    Graphite.Public.import_csv_lines(socket.assigns.leaderboard, lines_ok)
    {:noreply, assign(socket, csv_lines: lines_ok)}
  end

  def handle_event("change", _params, socket) do
    {:noreply, socket}
  end

  defp filter_ok({:ok, _line}), do: true
  defp filter_ok({:error, _line}), do: false

  defp check_line(%{} = line, %Graphite.LeaderboardModel{} = leaderboard) do
    with :ok <- contains_all_metrics?(line, leaderboard.metrics),
         :ok <- has_valid_submission?(line) do
      true
    else
      _ ->
        false
    end
  end

  defp contains_all_metrics?(line, metrics) do
    if Enum.all?(metrics, fn metric -> Map.has_key?(line, metric) end) do
      :ok
    else
      {:error, "Not all required metrics for a leaderboard entry are present."}
    end
  end

  defp has_valid_submission?(line) do
    # TODO check whether the provided submissions actually connects to the leaderboard
    # the score is being uploaded for?
    case Graphite.Public.get_submission(line["submission"]) do
      nil -> {:error, "Submission not found"}
      _ -> :ok
    end
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
      <%= if @csv_lines do %>
        Uploaded <%= length(@csv_lines) %> scores.
      <% end %>
    </div>
    """
  end
end
