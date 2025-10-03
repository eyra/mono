defmodule Systems.Assignment.ParticipantsView do
  use CoreWeb, :live_component

  require Logger

  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Annotation
  alias Systems.Affiliate
  alias Systems.Advert
  alias Systems.Pool
  alias Systems.Assignment

  @impl true
  def update(
        %{
          id: id,
          assignment: assignment,
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
        title: title,
        content_flags: content_flags,
        user: user,
        external_panel_link?: external_panel_link?,
        viewport: viewport,
        breakpoint: breakpoint
      )
      |> compose_child(:general)
      |> update_advert_button()
      |> update_invite_title()
      |> update_invite_url()
      |> update_invite_annotation()
      |> update_affiliate_title()
      |> update_affiliate_url()
      |> update_affiliate_annotation()
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

  defp update_invite_title(socket) do
    invite_title = dgettext("eyra-assignment", "invite.panel.title")
    assign(socket, invite_title: invite_title)
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

  def update_advert_button(%{assigns: %{assignment: %{adverts: []}}} = socket) do
    advert_button = %{
      action: %{type: :send, event: "create_advert"},
      face: %{
        type: :primary,
        bg_color: "bg-tertiary",
        text_color: "text-grey1",
        label: dgettext("eyra-assignment", "advert.create.button")
      }
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
      }
    }

    assign(socket, advert_button: advert_button)
  end

  defp update_invite_annotation(socket) do
    annotation = dgettext("eyra-assignment", "invite.panel.annotation")
    assign(socket, invite_annotation: annotation)
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

  defp update_invite_url(%{assigns: %{assignment: %{id: id}}} = socket) do
    path = ~p"/assignment/#{id}/invite"
    url = get_base_url() <> path
    assign(socket, url: url)
  end

  defp update_affiliate_url(
         %{assigns: %{assignment: %{id: id, external_panel: external_panel}}} = socket
       )
       when not is_nil(external_panel) do
    # backward compatibility using deprecated Assignment.external_panel field
    url = get_base_url() <> ~p"/assignment/#{id}/participate?participant=participant_id"
    assign(socket, affiliate_url: url)
  end

  defp update_affiliate_url(%{assigns: %{assignment: assignment}} = socket) do
    url = Affiliate.Public.url_for_resource(assignment) <> "?p=participant_id"
    assign(socket, affiliate_url: url)
  end

  defp get_base_url do
    Application.get_env(:core, :base_url)
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
      Frameworks.Pixel.Flash.push_error("Panl pool not found")
    end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <Text.title2><%= @title %></Text.title2>
          <.spacing value="L" />

          <.child name={:general} fabric={@fabric} >
            <:footer>
              <.spacing value="L" />
            </:footer>
          </.child>

          <.spacing value="L" />
          <div class="flex flex-col gap-8" %>
            <%= if @content_flags[:advert_in_pool] do %>
              <div class="border-grey4 border-2 rounded p-6">
                <div class="flex flex-row">
                  <div class="flex-grow">
                    <Text.title3><%= dgettext("eyra-assignment", "advert.title") %></Text.title3>
                    <Text.body><%= dgettext("eyra-assignment", "advert.body") %></Text.body>
                    <.spacing value="S" />
                    <Button.dynamic_bar buttons={[@advert_button]} />
                  </div>
                  <div>
                    <img src={~p"/images/panl-standing.svg"} alt="Panl logo" />
                  </div>
                </div>
              </div>
            <% end %>

            <%= if @content_flags[:invite_participants] do %>
              <Panel.flat bg_color="bg-grey1">
                <:title>
                  <div class="text-title3 font-title3 text-white">
                    <%= @invite_title %>
                  </div>
                </:title>
                <.spacing value="S" />
                <%= if @invite_annotation do %>
                  <Annotation.view annotation={@invite_annotation} />
                <% end %>
                <%= if @url do %>
                  <.spacing value="S" />
                  <div class="flex flex-row gap-6 items-center">
                    <div class="flex-wrap">
                      <Text.body_large color="text-white"><span class="break-all"><%= @url %></span></Text.body_large>
                    </div>
                    <div class="flex-wrap flex-shrink-0 mt-1">
                      <div id="copy-assignment-url" class="cursor-pointer" phx-hook="Clipboard" data-text={@url}>
                        <Button.Face.label_icon
                          label={dgettext("eyra-ui", "copy.clipboard.button")}
                          icon={:clipboard_tertiary}
                          text_color="text-tertiary"
                        />
                      </div>
                    </div>
                  </div>
                <% end %>
              </Panel.flat>
            <% end %>

            <%= if @content_flags[:affiliate] do %>
              <Affiliate.Html.url_panel title={@affiliate_title} annotation={@affiliate_annotation} url={@affiliate_url} />
            <% end %>
          </div>
        </Area.content>
      </div>
    """
  end
end
