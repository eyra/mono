defmodule Systems.Pool.SubmissionPage do
  @moduledoc """
   The submission page for a campaign.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :pool_submission
  use CoreWeb.UI.PlainDialog

  import CoreWeb.Gettext

  alias Core.Pools.{Submissions, Submission}

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias CoreWeb.UI.Navigation.ButtonBar
  alias CoreWeb.UI.Member
  alias CoreWeb.UI.Timestamp

  alias Systems.Pool.SubmissionView, as: SubmissionForm
  alias Systems.Pool.SubmissionCriteriaView, as: SubmissionCriteriaForm

  alias Frameworks.Pixel.Text.{Title1, SubHead}

  @impl true
  def mount(%{"id" => submission_id}, _session, socket) do
    model = %{id: String.to_integer(submission_id), director: :pool}

    {
      :ok,
      socket
      |> assign(
        model: model,
        changesets: %{},
        dialog: nil
      )
      |> observe_view_model()
      |> update_menus()
    }
  end

  defoverridable handle_uri: 1

  @impl true
  def handle_uri(
        %{assigns: %{uri_path: uri_path, vm: %{submission: %{promotion: %{id: promotion_id}}}}} =
          socket
      ) do
    preview_path =
      Routes.live_path(socket, Systems.Promotion.LandingPage, promotion_id,
        preview: true,
        back: uri_path
      )

    super(assign(socket, preview_path: preview_path))
  end

  defoverridable handle_view_model_updated: 1

  def handle_view_model_updated(socket) do
    socket |> update_menus()
  end

  def handle_info({:handle_auto_save_done, _}, socket) do
    {:noreply, socket |> update_menus()}
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
  def handle_event("accept", _params, %{assigns: %{vm: %{submission: submission}}} = socket) do
    socket =
      if ready_for_publish?(submission) do
        {:ok, _submission} =
          Submissions.update(submission, %{status: :accepted, accepted_at: Timestamp.naive_now()})

        title = dgettext("eyra-submission", "accept.success.title")
        text = dgettext("eyra-submission", "accept.success.text")

        socket
        |> inform(title, text)
      else
        title = dgettext("eyra-submission", "accept.error.title")
        text = dgettext("eyra-submission", "accept.error.text")

        socket
        |> inform(title, text)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("retract", _params, %{assigns: %{vm: %{submission: submission}}} = socket) do
    {:ok, _submission} = Submissions.update(submission, %{status: :idle})

    title = dgettext("eyra-submission", "retract.admin.success.title")
    text = dgettext("eyra-submission", "retract.admin.success.text")

    {
      :noreply,
      socket
      |> inform(title, text)
    }
  end

  @impl true
  def handle_event("complete", _params, %{assigns: %{vm: %{submission: submission}}} = socket) do
    {:ok, _submission} =
      Submissions.update(submission, %{status: :completed, completed_at: Timestamp.naive_now()})

    title = dgettext("eyra-submission", "complete.admin.success.title")
    text = dgettext("eyra-submission", "complete.admin.success.text")

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

  defp action_map(%{preview_path: preview_path}) do
    preview_action = %{type: :redirect, to: preview_path}
    accept_action = %{type: :send, event: "accept"}
    retract_action = %{type: :send, event: "retract"}
    complete_action = %{type: :send, event: "complete"}

    %{
      accept: %{
        action: accept_action,
        face: %{
          type: :primary,
          label: dgettext("link-ui", "accept.button"),
          bg_color: "bg-success"
        }
      },
      preview: %{
        action: preview_action,
        face: %{
          type: :primary,
          label: dgettext("link-ui", "preview.button"),
          bg_color: "bg-primary"
        }
      },
      retract: %{
        action: retract_action,
        face: %{type: :icon, icon: :retract, alt: dgettext("link-ui", "retract.button")}
      },
      complete: %{
        action: complete_action,
        face: %{
          type: :primary,
          label: dgettext("link-ui", "complete.button"),
          text_color: "text-grey1",
          bg_color: "bg-tertiary"
        }
      }
    }
  end

  defp create_actions(%{vm: %{accepted?: accepted?, completed?: completed?}} = assigns) do
    create_actions(action_map(assigns), accepted?, completed?)
  end

  defp create_actions(%{accept: accept, preview: preview}, false, _), do: [accept, preview]
  defp create_actions(%{accept: accept, preview: preview}, _, true), do: [accept, preview]

  defp create_actions(%{preview: preview, retract: retract, complete: complete}, true, false),
    do: [complete, preview, retract]

  defp show_dialog?(nil), do: false
  defp show_dialog?(_), do: true

  @impl true
  def render(assigns) do
    ~F"""
      <Workspace
        title={dgettext("link-studentpool", "submission.title")}
        menus={@menus}
      >
        <div :if={show_dialog?(@dialog)} class="fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-20">
          <div class="flex flex-row items-center justify-center w-full h-full">
            <PlainDialog {...@dialog} />
          </div>
        </div>
        <div phx-click="reset_focus">
          <ContentArea>
            <MarginY id={:page_top} />
            <Member :if={@vm.member} vm={@vm.member} />
            <Spacing value="XL" />
            <Title1>{@vm.title}</Title1>
            <Spacing value="L" />
            <SubHead>{@vm.byline}</SubHead>
            <Spacing value="L" />
          </ContentArea>

          <SubmissionCriteriaForm id={:submission_criteria_form} props={%{entity: @vm.submission.criteria}}/>
          <Spacing value="XL" />
          <SubmissionForm id={:submission_form} props={%{entity: @vm.submission, validate?: @vm.validate?}}/>
        </div>
        <ContentArea>
          <MarginY id={:button_bar_top} />
          <ButtonBar buttons={create_actions(assigns)} />
        </ContentArea>
      </Workspace>
    """
  end
end
