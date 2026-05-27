defmodule Systems.Assignment.ParticipantsView do
  use CoreWeb, :live_component

  require Logger

  use Gettext, backend: CoreWeb.Gettext
  use Systems.Assignment.PaidSlotsLogic

  alias Frameworks.Pixel.InlineBlock
  alias Frameworks.Pixel.Logo
  alias Systems.Affiliate
  alias Systems.Advert
  alias Systems.NextAction
  alias Systems.Pool
  alias Systems.Assignment
  alias Systems.Assignment.PaidSlotsLogic

  @impl true
  def update(
        %{
          id: id,
          assignment: %{info: info} = assignment,
          title: title,
          content_flags: content_flags,
          user: user,
          viewport: viewport,
          breakpoint: breakpoint
        },
        socket
      ) do
    external_panel_link? = assignment.external_panel != nil

    {
      :ok,
      socket
      |> assign(
        id: id,
        assignment: assignment,
        entity: info,
        title: title,
        content_flags: content_flags,
        user: user,
        external_panel_link?: external_panel_link?,
        viewport: viewport,
        breakpoint: breakpoint
      )
      |> compose_child(:general)
      |> update_advert_button()
      |> update_affiliate_title()
      |> update_affiliate_url()
      |> update_affiliate_annotation()
      |> update_recruit_title()
      |> update_recruit_url()
      |> update_recruit_annotation()
      |> update_invite_title()
      |> update_invite_url()
      |> update_invite_annotation()
      |> assign_pending_approvals()
      |> PaidSlotsLogic.assign_paid_slots_state()
    }
  end

  @impl true
  def compose(:general, %{
        assignment: %{info: info},
        viewport: viewport,
        breakpoint: breakpoint,
        content_flags: content_flags
      }) do
    %{
      module: Assignment.GeneralForm,
      params: %{
        entity: info,
        viewport: viewport,
        breakpoint: breakpoint,
        content_flags: content_flags
      }
    }
  end

  @impl true
  def compose(:payout_modal, %{assignment: %{id: assignment_id}}) do
    %{
      module: Assignment.PayoutModal,
      params: %{assignment_id: assignment_id}
    }
  end

  @impl true
  def handle_event(
        "create_advert",
        _payload,
        %{assigns: %{assignment: assignment, user: user}} = socket
      ) do
    if pool = Pool.Public.get_panl() do
      Advert.Assembly.create(assignment, user, pool)
    else
      Logger.error("Panl pool not found")
      Frameworks.Pixel.Flash.push_error(socket, "Panl pool not found")
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("open_payout_modal", _, socket) do
    {
      :noreply,
      socket
      |> compose_child(:payout_modal)
      |> show_modal(:payout_modal, :compact)
    }
  end

  @impl true
  def handle_event("payout_modal_close", _, socket) do
    {
      :noreply,
      socket
      |> hide_modal(:payout_modal)
      |> PaidSlotsLogic.refresh_assignment()
      |> assign_pending_approvals()
    }
  end

  defp assign_pending_approvals(%{assigns: %{assignment: assignment}} = socket) do
    assign(socket, pending_approvals: Assignment.Public.list_pending_payouts(assignment))
  end

  def update_advert_button(%{assigns: %{assignment: %{adverts: []}}} = socket) do
    advert_button = %{
      action: %{type: :send, event: "create_advert"},
      face: %{
        type: :primary,
        bg_color: "bg-tertiary",
        text_color: "text-grey1",
        label: dgettext("eyra-assignment", "advert.create.button")
      },
      testid: "create-advert-button"
    }

    assign(socket, advert_button: advert_button)
  end

  def update_advert_button(%{assigns: %{assignment: %{adverts: [%{id: advert_id} | _]}}} = socket) do
    advert_button = %{
      action: %{type: :redirect, to: ~p"/advert/#{advert_id}/content"},
      face: %{
        type: :plain,
        icon: :forward,
        label: dgettext("eyra-assignment", "advert.goto.button")
      },
      testid: "goto-advert-button"
    }

    assign(socket, advert_button: advert_button)
  end

  defp update_invite_title(socket) do
    invite_title = dgettext("eyra-assignment", "invite.panel.title")
    assign(socket, invite_title: invite_title)
  end

  defp update_invite_annotation(socket) do
    annotation = dgettext("eyra-assignment", "invite.panel.annotation")
    assign(socket, invite_annotation: annotation)
  end

  defp update_invite_url(%{assigns: %{assignment: assignment}} = socket) do
    url = Affiliate.Public.url_for_resource(assignment) <> "?p=participant_id"
    assign(socket, invite_url: url)
  end

  defp update_affiliate_title(
         %{assigns: %{assignment: %{external_panel: external_panel}}} = socket
       )
       when not is_nil(external_panel) do
    # backward compatibility using deprecated Assignment.external_panel field
    affiliate_title = dgettext("eyra-assignment", "external.panel.title")
    assign(socket, affiliate_title: affiliate_title)
  end

  defp update_affiliate_title(socket) do
    affiliate_title = dgettext("eyra-assignment", "affiliate.panel.title")
    assign(socket, affiliate_title: affiliate_title)
  end

  defp update_affiliate_annotation(
         %{assigns: %{assignment: %{external_panel: external_panel}}} = socket
       )
       when not is_nil(external_panel) do
    # backward compatibility using deprecated Assignment.external_panel field
    annotation = dgettext("eyra-assignment", "external.panel.annotation")
    assign(socket, affiliate_annotation: annotation)
  end

  defp update_affiliate_annotation(socket) do
    annotation = dgettext("eyra-assignment", "affiliate.panel.annotation")
    assign(socket, affiliate_annotation: annotation)
  end

  defp update_affiliate_url(%{assigns: %{assignment: assignment}} = socket) do
    url = Affiliate.Public.url_for_resource(assignment) <> "?p=participant_id"
    assign(socket, affiliate_url: url)
  end

  defp update_recruit_title(socket) do
    title = dgettext("eyra-assignment", "recruit.panel.title")
    assign(socket, recruit_title: title)
  end

  defp update_recruit_url(%{assigns: %{assignment: assignment}} = socket) do
    url = Affiliate.Public.recruit_url_for_resource(assignment)
    assign(socket, recruit_url: url)
  end

  defp update_recruit_annotation(socket) do
    annotation = dgettext("eyra-assignment", "recruit.panel.annotation")
    assign(socket, recruit_annotation: annotation)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <div class="flex flex-row items-baseline gap-3">
            <Text.title2 margin=""><%= @title %></Text.title2>
            <%= if @content_flags[:paid_slots] do %>
              <div class="text-title2 font-title2 text-primary">
                <%= @entity.subject_count %>
              </div>
            <% end %>
          </div>
          <.spacing value="L" />

          <.child name={:general} fabric={@fabric} >
            <:footer>
              <.spacing value="L" />
            </:footer>
          </.child>

          <.spacing value="L" />

          <.pending_approvals_banner pending_approvals={@pending_approvals} target={@myself} />

          <%= if @content_flags[:paid_slots] do %>
            <.paid_slots
              entity={@entity}
              transactions={@transactions}
              add_button={@add_button}
              target={@myself}
            />
            <.spacing value="L" />
          <% end %>

          <div class="flex flex-col gap-8">
            <%= if @content_flags[:advert_in_pool] do %>
              <InlineBlock.inline_block
                title={dgettext("eyra-assignment", "advert.title")}
                description={dgettext("eyra-assignment", "advert.body")}
                button={@advert_button}
                icon={Logo.path(:panl, {:product, :standing})}
              />
            <% end %>

            <%= if @content_flags[:recruit_participants] do %>
              <Affiliate.Html.url_panel title={@recruit_title} annotation={@recruit_annotation} url={@recruit_url} />
            <% end %>

            <%= if @content_flags[:invite_participants] do %>
              <Affiliate.Html.url_panel title={@invite_title} annotation={@invite_annotation} url={@invite_url} />
            <% end %>

            <%= if @content_flags[:affiliate] do %>
              <Affiliate.Html.url_panel title={@affiliate_title} annotation={@affiliate_annotation} url={@affiliate_url} />
            <% end %>
          </div>
        </Area.content>
      </div>
    """
  end

  @doc """
  Banner that surfaces participants whose rewards are awaiting researcher
  approval. Renders nothing when `pending_approvals` is empty so the
  enclosing layout stays compact in the common case.
  """
  attr(:pending_approvals, :list, required: true)
  attr(:target, :any, required: true)

  def pending_approvals_banner(assigns) do
    ~H"""
    <%= if Enum.any?(@pending_approvals) do %>
      <div data-testid="pending-approvals-cta">
        <NextAction.View.highlight
          title={dgettext("eyra-assignment", "panl_participants.pending_approvals.title")}
          description={dgettext("eyra-assignment", "panl_participants.pending_approvals.description")}
          cta_label={dgettext("eyra-assignment", "panl_participants.pending_approvals.open.button")}
          cta_action={%{type: :send, event: "open_payout_modal", target: @target}}
        />
      </div>
      <.spacing value="L" />
    <% end %>
    """
  end
end
