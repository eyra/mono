defmodule Link.Pool.Submission do
  @moduledoc """
   The submission page for a campaign.
  """
  use CoreWeb, :live_view
  use CoreWeb.MultiFormAutoSave
  use CoreWeb.Layouts.Workspace.Component, :pool_submission
  use CoreWeb.UI.Dialog

  import CoreWeb.Gettext

  alias Core.Pools.{Submissions, Submission}

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias CoreWeb.UI.Navigation.ActionBar

  alias Link.Pool.Form.AdminSubmission, as: SubmissionForm
  alias Link.Pool.Form.AdminSubmissionCriteria, as: SubmissionCriteriaForm

  alias EyraUI.Text.{Title1, SubHead}

  data(submission_id, :any)
  data(title, :any)
  data(byline, :any)
  data(accepted?, :any)
  data(validate?, :any)
  data(preview_path, :any)

  @impl true
  def mount(%{"id" => submission_id}, _session, socket) do

    submission = Submissions.get!(submission_id)
    accepted? = submission.status == :accepted
    validate? = accepted?

    update_at =
      submission.updated_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    byline = dgettext("eyra-submission", "byline", timestamp: update_at)

    preview_path = Routes.live_path(socket, Link.Promotion.Public, submission.promotion_id, preview: true)

    {
      :ok,
      socket
      |> assign(
        submission_id: submission_id,
        title: submission.promotion.title,
        byline: byline,
        accepted?: accepted?,
        validate?: validate?,
        preview_path: preview_path,
        changesets: %{},
        save_timer: nil,
        hide_flash_timer: nil,
        dialog: nil
      )
      |> update_menus()
    }
  end

  @impl true
  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  def handle_info({:claim_focus, :submission_form}, socket) do
    send_update(SubmissionCriteriaForm, id: :submission_criteria_form, focus: "")
    {:noreply, socket}
  end

  def handle_info({:claim_focus, :submission_criteria_form}, socket) do
    send_update(SubmissionForm, id: :submission_form, focus: "")
    {:noreply, socket}
  end

  @impl true
  def handle_event("reset_focus", _, socket) do
    send_update(SubmissionForm, id: :submission_form, focus: "")
    send_update(SubmissionCriteriaForm, id: :submission_criteria_form, focus: "")
    {:noreply, socket}
  end

  @impl true
  def handle_event("accept", _params, %{assigns: %{submission_id: submission_id}} = socket) do
    submission = Submissions.get!(submission_id)

    socket =
      if ready_for_publish?(submission) do
        {:ok, _submission} = Submissions.update(submission, %{status: :accepted})

        title = dgettext("eyra-submission", "accept.success.title")
        text = dgettext("eyra-submission", "accept.success.text")

        socket
        |> assign(accepted?: true)
        |> inform(title, text)
      else
        title = dgettext("eyra-submission", "accept.error.title")
        text = dgettext("eyra-submission", "accept.error.text")

        socket
        |> assign(validate?: true)
        |> inform(title, text)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("retract", _params, %{assigns: %{submission_id: submission_id}} = socket) do
    submission = Submissions.get!(submission_id)
    {:ok, _submission} = Submissions.update(submission, %{status: :submitted})

    title = dgettext("eyra-submission", "retract.admin.success.title")
    text = dgettext("eyra-submission", "retract.admin.success.text")

    {
      :noreply,
      socket
      |> assign(accepted?: false)
      |> inform(title, text)
    }
  end

  @impl true
  def handle_event("inform_ok", _params, socket) do
    {:noreply, socket |> assign(dialog: nil)}
  end

  defp ready_for_publish?(submission) do
    changeset =
      Submission.operational_changeset(submission, %{})
      |> Submission.operational_validation()

    changeset.valid?
  end

  defp create_actions(%{accepted?: accepted?} = assigns) do
    create_actions(assigns, accepted?)
  end

  defp create_actions(%{preview_path: preview_path}, false) do
    accept = %{
      action: %{type: :send, event: "accept"},
      face: %{type: :primary, label: dgettext("link-ui", "submit.button"), bg_color: "bg-success"}
    }

    preview = %{
      action: %{type: :redirect, to: preview_path},
      face: %{type: :primary, label: dgettext("link-ui", "preview.button"), bg_color: "bg-primary"}
    }

    [accept, preview]
  end

  defp create_actions(%{preview_path: preview_path}, true) do
    preview = %{
      action: %{type: :redirect, to: preview_path},
      face: %{type: :primary, label: dgettext("link-ui", "preview.button"), bg_color: "bg-primary"}
    }

    retract = %{
      action: %{type: :send, event: "retract"},
      face: %{type: :icon, icon: :retract, alt: dgettext("link-ui", "retract.button")}
    }

    [preview, retract]
  end

  defp create_actions(_, _), do: []

  defp show_dialog?(nil), do: false
  defp show_dialog?(_), do: true

  @impl true
  def render(assigns) do
    ~H"""
      <Workspace
        title={{ dgettext("link-studentpool", "submission.title") }}
        menus={{ @menus }}
      >
        <div :if={{ show_dialog?(@dialog) }} class="fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-20">
          <div class="flex flex-row items-center justify-center w-full h-full">
            <Dialog vm={{ @dialog }} />
          </div>
        </div>
        <ActionBar right_bar_buttons={{ create_actions(assigns) }} more_buttons={{ [] }} hide_seperator={{ true }} />
        <div phx-click="reset_focus">
          <MarginY id={{:actionbar}} />
          <ContentArea>
            <MarginY id={{:page_top}} />
            <Title1>{{@title}}</Title1>
            <Spacing value="L" />
            <SubHead>{{ @byline }}</SubHead>
            <Spacing value="L" />
          </ContentArea>

          <SubmissionCriteriaForm id={{:submission_criteria_form}} props={{ %{entity_id: @submission_id, validate?: @validate?} }}/>
          <Spacing value="XL" />
          <SubmissionForm id={{:submission_form}} props={{ %{entity_id: @submission_id, validate?: @validate?} }}/>
        </div>
      </Workspace>
    """
  end
end
