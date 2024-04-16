defmodule Systems.Graphite.SubmissionForm do
  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent

  alias Systems.Graphite

  # Handle initial update
  @impl true
  def update(%{id: id, tool: tool, user: user}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        tool: tool,
        user: user,
        show_errors: false
      )
      |> update_submission()
      |> update_changeset()
      |> update_submit_button()
    }
  end

  defp update_submission(%{assigns: %{tool: tool, user: user}} = socket) do
    submission = Graphite.Public.get_submission(tool, user, :owner)
    socket |> assign(submission: submission)
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
  def handle_event("cancel", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "cancel")}
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

  defp add_submission(%{assigns: %{tool: tool, user: user}} = socket, attrs) do
    case Graphite.Public.add_submission(tool, user, attrs) do
      {:ok, %{graphite_submission: submission}} ->
        socket
        |> assign(submission: submission)
        |> send_event(:parent, "submitted")

      {:error, :graphite_submission, changeset, _} ->
        socket |> assign(show_errors: true, changeset: changeset)

      {:error, :graphite_tool, _changeset, _} ->
        socket |> put_flash(:error, dgettext("eyra-graphite", "submit.failed.message"))
    end
  end

  defp update_submission(%{assigns: %{submission: submission}} = socket, attrs) do
    case Graphite.Public.update_submission(submission, attrs) do
      {:ok, %{graphite_submission: _submission}} ->
        socket |> send_event(:parent, "submitted")

      {:error, :graphite_submission, changeset, _} ->
        socket |> assign(show_errors: true, changeset: changeset)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="submission_content" phx-hook="LiveContent" data-show-errors={true}>
      <.spacing value="XS" />
      <.form id={@id} :let={form} for={@changeset} phx-submit="submit" phx-target={@myself} >
        <.text_input form={form} field={:description} label_text={dgettext("eyra-graphite", "submission.form.description.label")}/>
        <.text_input form={form} field={:github_commit_url} placeholder="https://github/<owner>/<repo>/commit/<sha>" label_text={dgettext("eyra-graphite", "submission.form.url.label")}/>
        <.spacing value="XS" />
        <Button.dynamic_bar buttons={[@submit_button]} />
      </.form>
    </div>
    """
  end
end
