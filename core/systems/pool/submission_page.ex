defmodule Systems.Pool.SubmissionPage do
  @moduledoc """
   The submission page for a campaign.
  """
  use CoreWeb, :live_view
  use CoreWeb.MultiFormAutoSave
  use CoreWeb.Layouts.Workspace.Component, :pool_submission
  use CoreWeb.UI.Dialog

  import CoreWeb.Gettext

  alias Systems.{
    Campaign,
    Promotion
  }

  alias Core.Accounts.User
  alias Core.Pools.{Submissions, Submission}

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias CoreWeb.UI.Navigation.ButtonBar
  alias CoreWeb.UI.Member

  alias Systems.Pool.SubmissionView, as: SubmissionForm
  alias Systems.Pool.SubmissionCriteriaView, as: SubmissionCriteriaForm

  alias Frameworks.Pixel.Text.{Title1, SubHead}

  data(submission_id, :any)
  data(title, :any)
  data(byline, :any)
  data(accepted?, :any)
  data(validate?, :any)
  data(preview_path, :any)
  data(member, :any)
  data(buttons, :any)

  @impl true
  def mount(%{"id" => submission_id}, _session, socket) do
    submission = Submissions.get!(submission_id)
    promotion = Promotion.Context.get!(submission.promotion_id)
    campaign = Campaign.Context.get_by_promotion(submission.promotion_id)
    owners = Campaign.Context.list_owners(campaign, [:profile, :features])
    owner = List.first(owners)
    member = to_member(owner, promotion)

    accepted? = submission.status == :accepted
    validate? = accepted?

    update_at =
      campaign.updated_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    byline = dgettext("eyra-submission", "byline", timestamp: update_at)

    preview_path =
      Routes.live_path(socket, Systems.Promotion.LandingPage, submission.promotion_id,
        preview: true
      )

    {
      :ok,
      socket
      |> assign(
        member: member,
        submission_id: submission_id,
        promotion_id: submission.promotion_id,
        campaign_id: campaign.id,
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

  defoverridable handle_uri: 1

  @impl true
  def handle_uri(%{assigns: %{uri_path: uri_path, promotion_id: promotion_id}} = socket) do
    preview_path =
      Routes.live_path(socket, Systems.Promotion.LandingPage, promotion_id,
        preview: true,
        back: uri_path
      )

    super(assign(socket, preview_path: preview_path))
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

  defp action_map(%{preview_path: preview_path}) do
    preview_action = %{type: :redirect, to: preview_path}
    accept_action = %{type: :send, event: "accept"}
    retract_action = %{type: :send, event: "retract"}

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
      }
    }
  end

  defp create_actions(%{accepted?: accepted?} = assigns) do
    create_actions(action_map(assigns), accepted?)
  end

  defp create_actions(%{accept: accept, preview: preview}, false), do: [accept, preview]
  defp create_actions(%{preview: preview, retract: retract}, true), do: [preview, retract]

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
        <div phx-click="reset_focus">
          <ContentArea>
            <MarginY id={{:page_top}} />
            <Member :if={{ @member }} vm={{ @member }} />
            <Spacing value="XL" />
            <Title1>{{@title}}</Title1>
            <Spacing value="L" />
            <SubHead>{{ @byline }}</SubHead>
            <Spacing value="L" />
          </ContentArea>

          <SubmissionCriteriaForm id={{:submission_criteria_form}} props={{ %{entity_id: @submission_id, validate?: @validate?} }}/>
          <Spacing value="XL" />
          <SubmissionForm id={{:submission_form}} props={{ %{entity_id: @submission_id, validate?: @validate?} }}/>
        </div>
        <ContentArea>
          <MarginY id={{:button_bar_top}} />
          <ButtonBar buttons={{create_actions(assigns)}} />
        </ContentArea>
      </Workspace>
    """
  end

  defp to_member(
         %{
           email: email,
           profile: %{
             fullname: fullname,
             photo_url: photo_url
           }
         } = user,
         %{
           title: title
         }
       ) do
    role = dgettext("eyra-admin", "role.researcher")
    action = %{type: :href, href: "mailto:#{email}?subject=Re: #{title}"}

    %{
      title: fullname,
      subtitle: role,
      photo_url: photo_url,
      gender: User.get_gender(user),
      button_large: %{
        action: action,
        face: %{
          type: :secondary,
          label: dgettext("eyra-admin", "ticket.mailto.button"),
          border_color: "border-white",
          text_color: "text-white"
        }
      },
      button_small: %{
        action: action,
        face: %{type: :icon, icon: :contact_tertiary}
      }
    }
  end
end
