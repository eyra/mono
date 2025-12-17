defmodule Systems.Graphite.SubmissionForm do
  use CoreWeb, :live_component

  import Frameworks.Pixel.Form

  alias CoreWeb.UI.Timestamp
  alias Systems.Graphite

  # Handle initial update
  @impl true
  def update(%{id: id, tool: tool, user: user, open?: open?, timezone: timezone}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        tool: tool,
        user: user,
        open?: open?,
        timezone: timezone,
        show_errors: false
      )
      |> update_submission()
      |> update_humanized_deadline()
      |> update_closed_message()
      |> update_open_message()
      |> update_url()
      |> update_changeset()
      |> update_submit_button()
    }
  end

  defp update_submission(%{assigns: %{tool: tool, user: user}} = socket) do
    submission = Graphite.Public.get_submission(tool, user, :owner)
    socket |> assign(submission: submission)
  end

  defp update_humanized_deadline(%{assigns: %{timezone: nil}} = socket) do
    assign(socket, humanized_deadline: "<timezone?>")
  end

  defp update_humanized_deadline(%{assigns: %{tool: %{deadline: nil}}} = socket) do
    assign(socket,
      humanized_deadline: dgettext("eyra-project", "leaderboard.unspecified.deadline.label")
    )
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

  defp update_open_message(%{assigns: %{humanized_deadline: humanized_deadline}} = socket) do
    open_message =
      dgettext("eyra-graphite", "submission.open.message", deadline: humanized_deadline)

    assign(socket, open_message: open_message)
  end

  defp update_closed_message(socket) do
    closed_message = dgettext("eyra-graphite", "submission.closed.message")
    assign(socket, closed_message: closed_message)
  end

  defp update_url(%{assigns: %{submission: %{github_commit_url: github_commit_url}}} = socket) do
    assign(socket, github_commit_url: github_commit_url)
  end

  defp update_url(socket) do
    assign(socket, github_commit_url: "")
  end

  defp update_changeset(%{assigns: %{submission: submission}} = socket) do
    changeset =
      if submission do
        Graphite.SubmissionModel.prepare(submission, %{})
      else
        Graphite.SubmissionModel.prepare(%Graphite.SubmissionModel{}, %{})
      end

    socket |> assign(changeset: changeset)
  end

  defp update_submit_button(%{assigns: %{id: id, submission: submission}} = socket) do
    submit_button_label =
      if submission do
        dgettext("eyra-graphite", "submission.form.update.button")
      else
        dgettext("eyra-graphite", "submission.form.submit.button")
      end

    submit_button = %{
      action: %{type: :submit, form_id: id},
      face: %{
        type: :primary,
        bg_color: "bg-tertiary",
        text_color: "text-grey1",
        label: submit_button_label
      }
    }

    assign(socket, submit_button: submit_button)
  end

  # Handle Events

  @impl true
  def handle_event("submit", %{"submission_model" => attrs}, socket) do
    {
      :noreply,
      socket
      |> handle_submit(attrs)
    }
  end

  @impl true
  def handle_event("cancel", _payload, %{assigns: %{id: id}} = socket) do
    {:noreply, publish_event(socket, {:cancel, %{source: %{id: id, module: __MODULE__}}})}
  end

  # Submit

  defp handle_submit(%{assigns: %{tool: tool, submission: nil}} = socket, attrs) do
    if Systems.Graphite.Public.open_for_submissions?(tool) do
      socket |> add_submission(attrs)
    else
      socket |> notify_closed_for_submissions()
    end
  end

  defp handle_submit(%{assigns: %{tool: tool}} = socket, attrs) do
    if Systems.Graphite.Public.open_for_submissions?(tool) do
      socket |> update_submission(attrs)
    else
      socket |> notify_closed_for_submissions()
    end
  end

  defp notify_closed_for_submissions(socket) do
    socket |> put_flash(:error, dgettext("eyra-graphite", "closed_for_submissions.error.message"))
  end

  defp add_submission(%{assigns: %{id: id, tool: tool, user: user}} = socket, attrs) do
    case Graphite.Public.add_submission(tool, user, attrs) do
      {:ok, %{graphite_submission: submission}} ->
        socket
        |> assign(submission: submission)
        |> publish_event({:submitted, %{source: %{id: id, module: __MODULE__}}})

      {:error, :graphite_submission, changeset, _} ->
        socket |> assign(show_errors: true, changeset: changeset)

      {:error, :graphite_tool, _changeset, _} ->
        socket |> put_flash(:error, dgettext("eyra-graphite", "submit.failed.message"))
    end
  end

  defp update_submission(%{assigns: %{id: id, submission: submission}} = socket, attrs) do
    case Graphite.Public.update_submission(submission, attrs) do
      {:ok, %{graphite_submission: _submission}} ->
        publish_event(socket, {:submitted, %{source: %{id: id, module: __MODULE__}}})

      {:error, :graphite_submission, changeset, _} ->
        socket |> assign(show_errors: true, changeset: changeset)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="submission_content" phx-hook="LiveContent" data-show-errors={true}>
      <.form id={@id} :let={form} for={@changeset} phx-submit="submit" phx-target={@myself} >
        <%= if @open? do %>
          <.text_input form={form} field={:description} label_text={dgettext("eyra-graphite", "submission.form.description.label")} reserve_error_space={false} />
          <.spacing value="M" />
          <.text_input form={form} field={:github_commit_url} placeholder="https://github/<owner>/<repo>/commit/<sha>" label_text={dgettext("eyra-graphite", "submission.form.url.label")} reserve_error_space={false} />
          <.spacing value="M" />
          <Text.sub_head color="text-success"><%= @open_message %></Text.sub_head>
          <.spacing value="M" />
          <Button.dynamic_bar buttons={[@submit_button]} />
        <% else %>
          <%= if @submission do %>
            <Text.body><%= dgettext("eyra-graphite", "locked.submission.message") %></Text.body>
            <.spacing value="M" />
            <Text.form_field_label id={:description}><%= dgettext("eyra-graphite", "submission.form.description.label") %> </Text.form_field_label>
            <.spacing value="XXS" />
            <Text.body_medium><%= @submission.description %></Text.body_medium>
            <.spacing value="M" />

            <Text.form_field_label id={:github_commit_url}><%= dgettext("eyra-graphite", "submission.form.url.label") %> </Text.form_field_label>
            <.spacing value="XXS" />
            <Text.body_medium>
              <a class="text-primary underline" href={@github_commit_url} target="_blank" ><%= @github_commit_url %></a>
            </Text.body_medium>
            <.spacing value="M" />
            <Text.sub_head color="text-error"><%= @closed_message %></Text.sub_head>
          <% else %>
            <Text.body><%= dgettext("eyra-graphite", "no.submission.message") %></Text.body>
          <% end %>
        <% end %>
      </.form>
    </div>
    """
  end
end
