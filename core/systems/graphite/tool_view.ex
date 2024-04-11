defmodule Systems.Graphite.ToolView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias CoreWeb.UI.Timestamp
  alias Systems.Graphite

  @impl true
  def update(%{tool: tool, user: user}, socket) do
    timezone = Map.get(socket.assigns, :timezone, nil)

    {
      :ok,
      socket
      |> assign(
        tool: tool,
        user: user,
        timezone: timezone
      )
      |> send_event(:parent, "tool_initialized")
      |> update_humanized_deadline()
      |> update_submission()
      |> update_open_for_submissions()
      |> update_leaderboard_description()
      |> update_leaderboard_button()
      |> update_done_button()
      |> compose_child(:submission_form)
    }
  end

  defp update_humanized_deadline(%{assigns: %{timezone: nil}} = socket) do
    assign(socket, humanized_deadline: "<deadline?>")
  end

  defp update_humanized_deadline(%{assigns: %{tool: %{deadline: nil}}} = socket) do
    assign(socket, humanized_deadline: "<deadline?>")
  end

  defp update_humanized_deadline(
         %{assigns: %{tool: %{deadline: deadline}, timezone: timezone}} = socket
       ) do
    humanized_deadline =
      deadline
      |> Timestamp.convert(timezone)
      |> Timestamp.humanize(always_include_time: true)

    assign(socket, humanized_deadline: humanized_deadline)
  end

  defp update_submission(%{assigns: %{tool: tool, user: user}} = socket) do
    submission = Graphite.Public.get_submission(tool, user, :owner)
    assign(socket, submission: submission)
  end

  defp update_open_for_submissions(%{assigns: %{tool: tool}} = socket) do
    socket
    |> assign(open_for_submissions?: Graphite.Public.open_for_submissions?(tool))
  end

  defp update_leaderboard_description(
         %{assigns: %{open_for_submissions?: true, humanized_deadline: humanized_deadline}} =
           socket
       ) do
    leaderboard_description =
      dgettext("eyra-graphite", "leaderboard.open.description", deadline: humanized_deadline)

    assign(socket, leaderboard_description: leaderboard_description)
  end

  defp update_leaderboard_description(%{assigns: %{open_for_submissions?: false}} = socket) do
    leaderboard_description = dgettext("eyra-graphite", "leaderboard.closed.description")
    assign(socket, leaderboard_description: leaderboard_description)
  end

  defp update_leaderboard_button(%{assigns: %{tool: %{leaderboard: nil}}} = socket) do
    assign(socket, leaderboard_button: nil)
  end

  defp update_leaderboard_button(socket) do
    leaderboard_button = %{
      action: %{type: :send, event: "go_to_leaderboard"},
      face: %{
        type: :plain,
        icon: :forward,
        label: dgettext("eyra-graphite", "leaderboard.button")
      }
    }

    assign(socket, leaderboard_button: leaderboard_button)
  end

  defp update_done_button(socket) do
    done_button = %{
      action: %{type: :send, event: "done"},
      face: %{type: :primary, label: dgettext("eyra-ui", "done.button")}
    }

    assign(socket, done_button: done_button)
  end

  @impl true
  def compose(:submission_form, %{open_for_submissions?: false}), do: nil

  @impl true
  def compose(:submission_form, %{tool: tool, user: user}) do
    %{
      module: Systems.Graphite.SubmissionForm,
      params: %{
        tool: tool,
        user: user
      }
    }
  end

  @impl true
  def handle_event("go_to_leaderboard", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("submitted", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "complete_task")}
  end

  @impl true
  def handle_event("done", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "complete_task")}
  end

  @impl true
  def handle_event("cancel", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "cancel_task")}
  end

  @impl true
  def handle_event("timezone", timezone, socket) do
    {
      :noreply,
      socket
      |> assign(timezone: timezone)
      |> update_humanized_deadline()
      |> update_child(:submissions_form)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div id={"#{@id}_timezone"} class="timezone" phx-hook="TimeZone">
        <Area.content>
          <Margin.y id={:page_top} />
          <Text.title2><%= dgettext("eyra-graphite", "submission.title") %></Text.title2>
          <.spacing value="M" />
          <%= if exists?(@fabric, :submission_form) do %>
            <.child name={:submission_form} fabric={@fabric} />
          <% else %>
            <Text.body><%= dgettext("eyra-graphite", "submission.round.closed.description") %></Text.body>
            <.spacing value="S" />
            <%= if @submission do %>
              <Text.body><%= @submission.description %></Text.body>
              <Text.body><%= @submission.url %></Text.body>
            <% else %>
              <Text.body><%= dgettext("eyra-graphite", "no.submission.message") %></Text.body>
            <% end %>
          <% end %>
          <.spacing value="L" />

          <Text.title2><%= dgettext("eyra-graphite", "leaderboard.title") %></Text.title2>
          <.spacing value="M" />
          <Text.body><%= @leaderboard_description %></Text.body>
          <.spacing value="M" />

          <%= if @leaderboard_button do %>
            <Text.body><%= dgettext("eyra-graphite", "leaderboard.description") %></Text.body>
            <Button.dynamic_bar buttons={[@leaderboard_button]} />
          <% end %>
          <.spacing value="L" />

          <%= if @done_button do %>
            <Button.dynamic_bar buttons={[@done_button]} />
          <% end %>
        </Area.content>
     </div>
    """
  end
end
