defmodule Systems.Assignment.ParticipantsView do
  use CoreWeb, :live_component

  require Logger

  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Annotation
  alias Systems.Assignment
  alias Systems.Advert
  alias Systems.Pool

  @impl true
  def update(%{id: id, assignment: assignment, template: template, user: user}, socket) do
    content_flags = Assignment.Template.content_flags(template)

    {
      :ok,
      socket
      |> assign(id: id, assignment: assignment, content_flags: content_flags, user: user)
      |> update_title()
      |> update_advert_button()
      |> update_annotation()
      |> update_url()
    }
  end

  defp update_title(socket) do
    title = dgettext("eyra-assignment", "invite.panel.title")
    assign(socket, title: title)
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

  defp update_annotation(socket) do
    annotation = dgettext("eyra-assignment", "invite.panel.annotation")
    assign(socket, annotation: annotation)
  end

  defp update_url(%{assigns: %{assignment: %{id: id}}} = socket) do
    path = ~p"/assignment/#{id}/invite"
    url = get_base_url() <> path
    assign(socket, url: url)
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
          <Text.title2><%= dgettext("eyra-assignment", "participants.title") %></Text.title2>
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
                    <%= @title %>
                  </div>
                </:title>
                <.spacing value="S" />
                <%= if @annotation do %>
                  <Annotation.view annotation={@annotation} />
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
          </div>
        </Area.content>
      </div>
    """
  end
end
