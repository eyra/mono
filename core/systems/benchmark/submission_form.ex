defmodule Systems.Benchmark.SubmissionForm do
  use CoreWeb.LiveForm

  alias Systems.{
    Benchmark
  }

  # Handle initial update
  @impl true
  def update(%{id: id, spot: spot, submission: submission, parent: parent}, socket) do
    close_button = %{
      action: %{type: :send, event: "close"},
      face: %{type: :icon, icon: :close}
    }

    submit_button = %{
      action: %{type: :submit, form_id: id},
      face: %{type: :primary, label: dgettext("eyra-benchmark", "submission.form.submit.button")}
    }

    changeset = Benchmark.SubmissionModel.prepare(submission, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        spot: spot,
        submission: submission,
        parent: parent,
        close_button: close_button,
        submit_button: submit_button,
        changeset: changeset,
        show_errors: false
      )
    }
  end

  # Handle Events

  @impl true
  def handle_event("close", _params, socket) do
    {:noreply, socket |> close()}
  end

  @impl true
  def handle_event("submit", %{"submission_model" => attrs}, socket) do
    {
      :noreply,
      socket
      |> handle_submit(attrs)
    }
  end

  # Submit

  defp handle_submit(
         %{assigns: %{spot: spot, submission: %{spot_id: nil} = submission}} = socket,
         attrs
       ) do
    changeset =
      submission
      |> Benchmark.SubmissionModel.change(attrs)
      |> Benchmark.SubmissionModel.validate()
      |> Ecto.Changeset.put_assoc(:spot, spot)

    socket |> upsert(changeset)
  end

  defp handle_submit(%{assigns: %{submission: submission}} = socket, attrs) do
    changeset =
      submission
      |> Benchmark.SubmissionModel.change(attrs)
      |> Benchmark.SubmissionModel.validate()

    socket |> upsert(changeset)
  end

  defp upsert(socket, changeset) do
    case Benchmark.Public.create_submission(changeset) do
      {:ok, _submission} ->
        socket |> close()

      {:error, changeset} ->
        socket |> assign(show_errors: true, changeset: changeset)
    end
  end

  defp close(%{assigns: %{parent: parent}} = socket) do
    update_target(parent, %{module: __MODULE__, action: :close})
    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="submission_content" phx-hook="LiveContent" data-show-errors={true}>
      <div class="flex flex-row">
          <div>
            <Text.title3><%= dgettext("eyra-benchmark", "submission.form.title") %></Text.title3>
          </div>
          <div class="flex-grow" />
          <Button.dynamic {@close_button} />
      </div>

      <.spacing value="XS" />
      <.form id={@id} :let={form} for={@changeset} phx-submit="submit" phx-target={@myself} >
        <.text_input form={form} field={:description} label_text={dgettext("eyra-benchmark", "submission.form.description.label")} />
        <.text_input form={form} field={:github_commit_url} placeholder="http://github/<team>/<repo>/commit/<sha>" label_text={dgettext("eyra-benchmark", "submission.form.url.label")} />
        <.spacing value="XS" />
        <Button.dynamic {@submit_button} />
      </.form>
    </div>
    """
  end
end
