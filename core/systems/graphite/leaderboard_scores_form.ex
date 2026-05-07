defmodule Systems.Graphite.LeaderboardScoresForm do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader, accept: ~w(.csv)

  alias Frameworks.Pixel.Text

  alias Systems.{
    Graphite
  }

  @impl true
  def update(
        %{
          id: id,
          leaderboard: leaderboard
        },
        socket
      ) do
    headers = ["submission-id", "url", "ref", "status", "error_message" | leaderboard.metrics]

    {
      :ok,
      socket
      |> assign(
        id: id,
        label: dgettext("eyra-graphite", "scores.csv.headers.message"),
        headers: headers,
        leaderboard: leaderboard,
        placeholder: dgettext("eyra-graphite", "label.upload_file"),
        select_button: dgettext("eyra-graphite", "label.select"),
        replace_button: dgettext("eyra-graphite", "label.replace_file"),
        csv_url: nil,
        csv_remote_file: nil,
        parsed_results: nil
      )
      |> init_file_uploader(:file)
      |> prepare_submissions()
      |> prepare_submit_button(dgettext("eyra-graphite", "scores.form.submit.button"))
    }
  end

  defp prepare_submissions(%{assigns: %{leaderboard: %{tool: tool}}} = socket) do
    assign(socket, :submissions, Graphite.Public.get_submissions(tool))
  end

  defp prepare_submit_button(socket, label) do
    submit_button = %{
      action: %{type: :send, event: "submit"},
      face: %{type: :primary, label: label}
    }

    assign(socket, submit_button: submit_button)
  end

  @impl true
  def process_file(
        %{assigns: %{leaderboard: leaderboard}} = socket,
        %{public_url: csv_url, original_filename: original_filename}
      ) do
    result = Graphite.ScoresParser.from_url(csv_url, leaderboard)
    assign(socket, csv_url: csv_url, csv_remote_file: original_filename, parsed_results: result)
  end

  def handle_event(
        "submit",
        _params,
        %{assigns: %{leaderboard: leaderboard, parsed_results: parsed_results}} = socket
      ) do
    Graphite.Public.import_scores(leaderboard, parsed_results)
    {:noreply, socket |> assign(parsed_results: nil)}
  end

  def handle_event("change", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div>
      <Frameworks.Pixel.FileSelector.file_selector
        id={@id}
        label={@label}
        placeholder={@placeholder}
        filename={@csv_remote_file}
        replace_button={@replace_button}
        select_button={@select_button}
        uploads={@uploads}
        target={@myself}
      />
    </div>

      <.spacing value="L" />
      <%= if @parsed_results do %>
        <Text.title3>Error <span class="text-primary"><%= length(elem(@parsed_results.error,0)) + length(elem(@parsed_results.error,1)) %></span></Text.title3>
        <.spacing value="S" />
        <.table items={elem(@parsed_results.error,0)}/>
        <.table items={elem(@parsed_results.error,1)}/>
        <.spacing value="M" />
        <Text.title3>Success <span class="text-primary"><%= length(elem(@parsed_results.success,0)) + length(elem(@parsed_results.success,1)) %></span></Text.title3>
        <.spacing value="M" />
        <Text.sub_head color="text-success"><%= dgettext("eyra-graphite", "scores.csv.success.valid.message", count: length(elem(@parsed_results.success,0))) %></Text.sub_head>
        <%= if length(elem(@parsed_results.success,1)) > 0 do %>
          <.spacing value="M" />
          <.table items={elem(@parsed_results.success,1)}/>
        <% end %>
        <.spacing value="M" />
        <.wrap>
          <Button.dynamic {@submit_button} />
        </.wrap>

      <% end %>
    </div>
    """
  end

  attr(:items, :list, required: true)

  def table(assigns) do
    ~H"""
    <table>
      <%= for {line_nr, line, parse_errors} <- @items do %>
        <tr>
          <td class="pr-4"><Text.body>Line <%= line_nr %></Text.body></td>
          <td class="pr-4"><Text.body color="text-warning"><%= line["error_message"] %></Text.body></td>
          <td><Text.sub_head color="text-error"><%= Enum.join(parse_errors, ", ") %></Text.sub_head></td>
        </tr>
      <% end %>
    </table>
    """
  end
end
