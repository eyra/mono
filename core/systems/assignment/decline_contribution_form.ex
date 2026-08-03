defmodule Systems.Assignment.DeclineContributionForm do
  @moduledoc """
  Modal-hosted form for declining a single pending contribution. Presented via
  `LiveNest.Modal.prepare_live_component/3` from `Systems.Assignment.ContributionsView`.

  Requires a reason and a confirmation input where the researcher retypes the
  subject label (e.g. "Participant 2") — mirrors the safety pattern in
  `Systems.Storage.EmptyConfirmationView`. Rather than disabling the Decline
  button, the form runs a schemaless changeset on submit and lets the pixel
  `.text_area` / `.text_input` components surface the errors via their
  built-in error slot. `data-show-errors` on the form gates whether errors
  render, so the first render is clean until the researcher tries to submit
  an invalid form.

  On submit the form sends `{:submit_decline, %{participation_id, reason}}` to the
  parent LV process (`ContributionsView`) which runs the actual mutation.
  """
  use CoreWeb, :live_component

  import Frameworks.Pixel.Form
  import LiveNest.Event.Publisher, only: [publish_event: 3]

  alias Ecto.Changeset
  alias Frameworks.Pixel.Text

  @impl true
  def update(
        %{
          id: id,
          participation_id: participation_id,
          subject_label: subject_label,
          live_nest: %{modal: %LiveNest.Modal{controller_pid: controller_pid}}
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        participation_id: participation_id,
        subject_label: subject_label,
        controller_pid: controller_pid,
        show_errors: false,
        loading: false
      )
      |> assign_changeset(%{})
      |> update_buttons()
    }
  end

  defp assign_changeset(%{assigns: %{subject_label: subject_label}} = socket, attrs) do
    changeset =
      attrs
      |> build_changeset(subject_label)
      |> Map.put(:action, :validate)

    assign(socket, changeset: changeset)
  end

  defp build_changeset(attrs, subject_label) do
    types = %{reason: :string, confirm_input: :string}

    {%{reason: "", confirm_input: ""}, types}
    |> Changeset.cast(attrs, [:reason, :confirm_input])
    |> Changeset.update_change(:reason, &String.trim/1)
    |> Changeset.validate_required(:reason, message: "please provide a reason")
    |> Changeset.validate_change(:confirm_input, fn :confirm_input, value ->
      if value == subject_label do
        []
      else
        [confirm_input: {"type \"%{subject}\" to confirm the decline", subject: subject_label}]
      end
    end)
    |> ensure_confirm_error_when_blank(subject_label)
  end

  # `validate_change` skips blank/nil values, so an empty confirm input never
  # trips the check. Add the same error explicitly so the field warns instead
  # of silently letting an empty submission through.
  defp ensure_confirm_error_when_blank(changeset, subject_label) do
    case Changeset.get_field(changeset, :confirm_input) do
      value when value in [nil, ""] ->
        Changeset.add_error(
          changeset,
          :confirm_input,
          "type \"%{subject}\" to confirm the decline",
          subject: subject_label
        )

      _ ->
        changeset
    end
  end

  defp update_buttons(%{assigns: %{myself: myself, loading: loading}} = socket) do
    submit = %{
      action: %{type: :submit, target: myself},
      face: %{
        type: :primary,
        label: dgettext("eyra-assignment", "contributions.decline.submit.button"),
        bg_color: "bg-delete",
        loading: loading
      },
      testid: "decline-submit-button"
    }

    cancel = %{
      action: %{type: :send, target: myself, event: "cancel"},
      face: %{
        type: :label,
        label: dgettext("eyra-ui", "cancel.button"),
        text_color: "text-grey1"
      },
      testid: "decline-cancel-button"
    }

    assign(socket, submit_button: submit, cancel_button: cancel)
  end

  @impl true
  def handle_event("change", %{"decline" => attrs}, socket) do
    {:noreply, assign_changeset(socket, attrs)}
  end

  @impl true
  def handle_event(
        "submit",
        _,
        %{
          assigns: %{
            changeset: changeset,
            participation_id: participation_id,
            controller_pid: pid
          }
        } = socket
      ) do
    if changeset.valid? do
      reason = Changeset.get_field(changeset, :reason)

      socket =
        socket
        |> publish_event(
          {:submit_decline, %{participation_id: participation_id, reason: reason}},
          pid
        )
        |> assign(loading: true, show_errors: false)
        |> update_buttons()

      {:noreply, socket}
    else
      {:noreply, assign(socket, show_errors: true)}
    end
  end

  @impl true
  def handle_event("cancel", _, %{assigns: %{controller_pid: pid}} = socket) do
    {:noreply, publish_event(socket, :hide_decline_modal, pid)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} phx-hook="LiveContent" data-show-errors={@show_errors} data-testid="decline-contribution-form">
      <Text.title2><%= dgettext("eyra-assignment", "contributions.decline.modal.title") %></Text.title2>
      <.spacing value="M" />

      <.form
        :let={form}
        id={"#{@id}_form"}
        for={@changeset}
        as={:decline}
        data-show-errors={@show_errors}
        phx-change="change"
        phx-submit="submit"
        phx-target={@myself}
      >
        <div class="flex flex-col gap-8">
          <.text_area
            form={form}
            field={:reason}
            label_text={dgettext("eyra-assignment", "contributions.decline.reason.label")}
            height="h-24"
            reserve_error_space={false}
          />

          <div class="flex flex-col gap-4">
            <div class="flex flex-col gap-2">
              <Text.title6 margin=""><%= dgettext("eyra-assignment", "contributions.decline.confirm.title") %></Text.title6>
              <Text.body_medium>
                <%= raw(dgettext("eyra-assignment", "contributions.decline.confirm.body", subject: @subject_label)) %>
              </Text.body_medium>
            </div>
            <.text_input
              form={form}
              field={:confirm_input}
              debounce="0"
              placeholder={dgettext("eyra-assignment", "contributions.decline.confirm.placeholder", subject: @subject_label)}
              reserve_error_space={false}
            />
          </div>

          <div class="flex flex-row gap-4">
            <Button.dynamic {@submit_button} />
            <Button.dynamic {@cancel_button} />
          </div>
        </div>
      </.form>
    </div>
    """
  end
end
