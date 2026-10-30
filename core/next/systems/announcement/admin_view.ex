defmodule Systems.Announcement.AdminView do
  @moduledoc """
  The Announcements tab on the Admin page: the list of announcements and the
  form to compose one. Saving stores the announcement unpublished.

  Every event checks `@vm.allowed?` (system admin, `announcements` flag on).
  """
  use CoreWeb, :embedded_live_view

  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.TrixPostProcessor
  alias Systems.Announcement
  alias Systems.Observatory

  def dependencies(), do: [:current_user, :locale]

  def get_model(:not_mounted_at_router, _session, _assigns) do
    Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, assign(socket, form: nil)}
  end

  @impl true
  def handle_event(_event, _params, %{assigns: %{vm: %{allowed?: false}}} = socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("new_announcement", _params, socket) do
    {:noreply, assign(socket, form: new_form())}
  end

  @impl true
  def handle_event("cancel_announcement", _params, socket) do
    {:noreply, assign(socket, form: nil)}
  end

  # The editor's field is named after the body field with an `_input` suffix
  # (`Frameworks.Pixel.Form.wysiwyg_area/1`).
  @impl true
  def handle_event(
        "save_announcement",
        %{"announcement" => attrs} = params,
        %{assigns: %{current_user: user}} = socket
      ) do
    body = params |> Map.get("announcement[body]_input", "") |> open_links_in_new_tab()
    attrs = Map.put(attrs, "body", body)

    case Announcement.Public.create_announcement(user, attrs) do
      {:ok, _announcement} ->
        {:noreply, socket |> assign(form: nil) |> update_view_model()}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :announcement))}
    end
  end

  # `add_target_blank/1` skips links that already have a target, and the
  # scrubber drops every target but `_blank`, so other targets go first.
  @link_target ~r/(<a\b[^>]*?)\s+target\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]+)/i

  defp open_links_in_new_tab(body) do
    body
    |> drop_link_targets()
    |> TrixPostProcessor.add_target_blank()
  end

  defp drop_link_targets(body) do
    case Regex.replace(@link_target, body, "\\1") do
      ^body -> body
      dropped -> drop_link_targets(dropped)
    end
  end

  defp new_form do
    %Announcement.Model{kind: :release_notes, priority: :normal}
    |> Ecto.Changeset.change()
    |> to_form(as: :announcement)
  end

  defp radio_items(options, value) do
    value = to_string(value)

    Enum.map(options, fn {id, label} ->
      %{id: id, value: label, active: to_string(id) == value}
    end)
  end

  @impl true
  def render(%{vm: %{allowed?: false}} = assigns) do
    ~H"""
    <div data-testid="announcement-admin-view"></div>
    """
  end

  def render(assigns) do
    ~H"""
    <div data-testid="announcement-admin-view">
      <Area.content>
        <Margin.y id={:page_top} />
        <div class="flex flex-row items-center">
          <Text.title2 margin="">
            <%= @vm.title %> <span class="text-primary"><%= @vm.count %></span>
          </Text.title2>
          <div class="flex-grow" />
          <%= if @form == nil do %>
            <Button.dynamic {@vm.new_button} testid="new-announcement-button" />
          <% end %>
        </div>
        <.spacing value="M" />

        <%= if @form do %>
          <.compose form={@form} labels={@vm.form} />
          <.spacing value="L" />
        <% end %>

        <%= if @vm.items == [] do %>
          <Text.body_large><%= @vm.empty_text %></Text.body_large>
        <% else %>
          <.announcement_list head_cells={@vm.head_cells} items={@vm.items} />
        <% end %>
      </Area.content>
    </div>
    """
  end

  attr(:form, :any, required: true)
  attr(:labels, :map, required: true)

  defp compose(assigns) do
    ~H"""
    <.form id="announcement_form" for={@form} phx-submit="save_announcement" data-testid="announcement-form">
      <.radio_group
        form={@form}
        field={:kind}
        label_text={@labels.kind}
        items={radio_items(@labels.kinds, @form[:kind].value)}
      />
      <.spacing value="S" />
      <.text_input form={@form} field={:title} label_text={@labels.title} maxlength="255" />
      <.text_input form={@form} field={:summary} label_text={@labels.summary} />
      <.wysiwyg_area form={@form} field={:body} label_text={@labels.body} attachments={false} />
      <.radio_group
        form={@form}
        field={:priority}
        label_text={@labels.priority}
        items={radio_items(@labels.priorities, @form[:priority].value)}
      />
      <.spacing value="M" />
      <div class="flex flex-row gap-4">
        <Button.dynamic
          action={%{type: :submit}}
          face={%{type: :primary, label: @labels.save_button}}
          testid="save-announcement-button"
        />
        <Button.dynamic
          action={%{type: :send, event: "cancel_announcement"}}
          face={%{type: :label, label: @labels.cancel_button}}
        />
      </div>
    </.form>
    """
  end

  attr(:head_cells, :list, required: true)
  attr(:items, :list, required: true)

  defp announcement_list(assigns) do
    ~H"""
    <table class="w-full table-fixed text-left" data-testid="announcement-list">
      <thead>
        <tr class="h-8 text-tablehead font-tablehead text-grey2">
          <%= for cell <- @head_cells do %>
            <th><%= cell %></th>
          <% end %>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <%= for item <- @items do %>
          <tr class="h-12 border-t border-grey4 font-body text-bodysmall" data-testid={"announcement-row-#{item.id}"}>
            <td><%= item.kind %></td>
            <td class="truncate pr-4"><%= item.title %></td>
            <td><%= item.priority %></td>
            <td><%= item.published %></td>
            <td><%= item.recipient_count %></td>
            <td>
              <%= for button <- item.buttons do %>
                <Button.dynamic {button} />
              <% end %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end
end
