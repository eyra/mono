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
      |> update_cancel_button()
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
    submit_button_face =
      if submission do
        %{type: :primary, label: dgettext("eyra-graphite", "submission.form.update.button")}
      else
        %{type: :primary, label: dgettext("eyra-graphite", "submission.form.submit.button")}
      end

    submit_button = %{
      action: %{type: :submit, form_id: id},
      face: submit_button_face
    }

    socket |> assign(submit_button: submit_button)
  end

  defp update_cancel_button(%{assigns: %{myself: myself}} = socket) do
    cancel_button = %{
      action: %{type: :send, event: "cancel", target: myself},
      face: %{type: :label, label: dgettext("eyra-ui", "cancel.button")}
    }

    socket |> assign(cancel_button: cancel_button)
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

  defp handle_submit(%{assigns: %{submission: nil, tool: tool, user: user}} = socket, attrs) do
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

  defp handle_submit(%{assigns: %{submission: submission}} = socket, attrs) do
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
        <.text_input form={form} field={:description} label_text={dgettext("eyra-graphite", "submission.form.description.label")} />
        <.text_input form={form} field={:github_commit_url} placeholder="https://github/<owner>/<repo>/commit/<sha>" label_text={dgettext("eyra-graphite", "submission.form.url.label")} />
        <.spacing value="XS" />
        <div class="flex flex-row gap-4">
          <Button.dynamic {@submit_button} />
          <Button.dynamic {@cancel_button} />
        </div>
      </.form>
    </div>
    """
  end
end
