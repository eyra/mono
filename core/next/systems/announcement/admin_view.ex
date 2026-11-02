defmodule Systems.Announcement.AdminView do
  @moduledoc """
  The Announcements tab on the Admin page: the list of announcements and the
  form to compose one. Saving stores the announcement unpublished; it can be
  opened again from the list. Publishing sends it to the audience chosen below
  the form: creators, narrowed by the Admin → Users filters and search. The
  server resolves the audience itself
  (`Systems.Announcement.Public.publish_announcement/4`).

  A published announcement opens with only its title, summary and body:
  saving shows the changes to its recipients without sending it again
  (`Systems.Announcement.Public.update_announcement/2`).

  Every event checks `@vm.allowed?` (system admin, `announcements` flag on).
  """
  use CoreWeb, :embedded_live_view

  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text
  alias Systems.Announcement
  alias Systems.Observatory

  def dependencies(), do: [:current_user, :locale]

  def get_model(:not_mounted_at_router, _session, _assigns) do
    Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket |> assign(form: nil) |> reset_compose()}
  end

  @impl true
  def handle_event(_event, _params, %{assigns: %{vm: %{allowed?: false}}} = socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("new_announcement", _params, socket) do
    {:noreply, socket |> reset_compose() |> assign(form: new_form()) |> update_view_model()}
  end

  @impl true
  def handle_event("edit_announcement", %{"item" => id}, socket) do
    case Announcement.Public.get_announcement(id) do
      %Announcement.Model{priority: priority} = announcement ->
        {
          :noreply,
          socket
          |> reset_compose()
          |> assign(
            announcement: announcement,
            priority: priority,
            form: announcement |> Ecto.Changeset.change() |> to_form(as: :announcement)
          )
          |> update_view_model()
        }

      _ ->
        {:noreply, update_view_model(socket)}
    end
  end

  @impl true
  def handle_event("cancel_announcement", _params, socket) do
    {:noreply, close_form(socket)}
  end

  # Only the priority changes the view model (whether an email is sent).
  @impl true
  def handle_event(
        "change_announcement",
        %{"announcement" => %{"priority" => priority}},
        %{assigns: %{priority: current}} = socket
      ) do
    case to_priority(priority) do
      ^current -> {:noreply, socket}
      priority -> {:noreply, socket |> assign(priority: priority) |> update_view_model()}
    end
  end

  @impl true
  def handle_event("change_announcement", _params, socket) do
    {:noreply, socket}
  end

  # The filter chips are rendered here rather than with `Frameworks.Pixel.Selector`:
  # its client-side toggle targets every chip with the same id on the page, and
  # the Users tab on the same Admin page has Verified and Unverified chips too.
  @impl true
  def handle_event(
        "toggle_audience_filter",
        %{"filter" => filter},
        %{assigns: %{audience_filters: filters}} = socket
      ) do
    case Enum.find(Announcement.Public.audience_filters(), &(to_string(&1) == filter)) do
      nil ->
        {:noreply, socket}

      filter ->
        filters = if filter in filters, do: List.delete(filters, filter), else: [filter | filters]

        {
          :noreply,
          socket |> assign(audience_filters: filters, compose_notice: nil) |> update_view_model()
        }
    end
  end

  # The editor's field is named after the body field with an `_input` suffix
  # (`Frameworks.Pixel.Form.wysiwyg_area/1`). The Publish button submits the
  # form with `publish` set to the recipient count the admin saw.
  @impl true
  def handle_event("save_announcement", %{"announcement" => attrs} = params, socket) do
    body = params |> Map.get("announcement[body]_input", "") |> open_links_in_new_tab()
    attrs = Map.put(attrs, "body", body)

    {:noreply, submit(socket, attrs, shown_count(params))}
  end

  @impl true
  def consume_event(
        %{name: :search_query, payload: %{query: query, query_string: query_string}},
        socket
      ) do
    {
      :stop,
      socket
      |> assign(audience_query: query, audience_query_string: query_string, compose_notice: nil)
      |> update_view_model()
    }
  end

  # `nil` for Save; for Publish the count the admin saw, or -1 when it isn't a
  # number, which never matches the audience.
  defp shown_count(%{"publish" => count}) do
    case Integer.parse(count) do
      {count, ""} -> count
      _ -> -1
    end
  end

  defp shown_count(_params), do: nil

  defp submit(socket, attrs, shown_count) do
    case save(socket, attrs) do
      {:ok, announcement} ->
        socket
        |> assign(
          announcement: announcement,
          form: announcement |> Ecto.Changeset.change() |> to_form(as: :announcement)
        )
        |> publish_or_close(announcement, shown_count)

      {:error, reason} when reason in [:already_published, :changed_since_loaded] ->
        show_notice(socket, reason)

      {:error, changeset} ->
        assign(socket, form: to_form(changeset, as: :announcement))
    end
  end

  defp save(%{assigns: %{announcement: nil, current_user: user}}, attrs),
    do: Announcement.Public.create_announcement(user, attrs)

  defp save(%{assigns: %{announcement: announcement}}, attrs),
    do: Announcement.Public.update_announcement(announcement, attrs)

  defp publish_or_close(socket, _announcement, nil), do: close_form(socket)

  # When it isn't published the form stays open on the saved announcement:
  # with no recipients the view model already says that nobody matches, and
  # a changed audience shows its new count with a notice.
  defp publish_or_close(
         %{assigns: %{audience_filters: filters, audience_query: query}} = socket,
         announcement,
         shown_count
       ) do
    case Announcement.Public.publish_announcement(announcement, filters, query, shown_count) do
      {:ok, _announcement} -> close_form(socket)
      {:error, :no_recipients} -> update_view_model(socket)
      {:error, {:audience_changed, _count}} -> show_notice(socket, :audience_changed)
      {:error, :already_published} -> show_notice(socket, :already_published)
    end
  end

  defp show_notice(socket, notice) do
    socket |> assign(compose_notice: notice) |> update_view_model()
  end

  defp close_form(socket) do
    socket |> assign(form: nil) |> reset_compose() |> update_view_model()
  end

  defp reset_compose(socket) do
    assign(socket,
      announcement: nil,
      priority: :normal,
      audience_filters: [],
      audience_query: nil,
      audience_query_string: "",
      compose_notice: nil
    )
  end

  defp to_priority(priority) do
    Enum.find(Announcement.Model.priorities(), :normal, &(to_string(&1) == priority))
  end

  # Every target is dropped first, so each link then gets `target="_blank"`;
  # an attribute that ends in `target`, such as `data-target`, is not a target.
  @link_target ~r/(<a\b[^>]*?)\s+target\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]+)/i
  @link ~r/<a\b([^>]*)>/i

  defp open_links_in_new_tab(body) do
    body
    |> drop_link_targets()
    |> add_target_blank()
  end

  defp add_target_blank(body), do: Regex.replace(@link, body, ~s|<a\\1 target="_blank">|)

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

        <%= if @form && @vm.published do %>
          <.compose form={@form} labels={@vm.form} published?={true} />
          <.spacing value="M" />
          <Text.body_medium testid="announcement-published-notice"><%= @vm.published.text %></Text.body_medium>
          <.spacing value="M" />
          <%= if @vm.published.notice do %>
            <Text.body_medium testid="announcement-compose-notice" color="text-warning">
              <%= @vm.published.notice %>
            </Text.body_medium>
            <.spacing value="S" />
          <% end %>
          <.compose_buttons labels={@vm.form} publish?={false} />
          <.spacing value="L" />
        <% end %>

        <%= if @form && @vm.audience do %>
          <.compose form={@form} labels={@vm.form} published?={false} />
          <.spacing value="M" />
          <.audience audience={@vm.audience} query_string={@audience_query_string} />
          <.spacing value="M" />
          <%= if @vm.audience.notice do %>
            <Text.body_medium testid="announcement-compose-notice" color="text-warning">
              <%= @vm.audience.notice %>
            </Text.body_medium>
            <.spacing value="S" />
          <% end %>
          <.compose_buttons
            labels={@vm.form}
            publish?={true}
            recipient_count={@vm.audience.recipient_count}
          />
          <.spacing value="L" />
        <% end %>

        <%= if @vm.items == [] do %>
          <Text.body_large><%= @vm.empty_text %></Text.body_large>
        <% else %>
          <.announcement_list head_cells={@vm.head_cells} items={@vm.items} buttons?={@form == nil} />
        <% end %>
      </Area.content>
    </div>
    """
  end

  attr(:form, :any, required: true)
  attr(:labels, :map, required: true)
  attr(:published?, :boolean, required: true)

  # Kind and priority can't change once it is published, so they are left out.
  defp compose(assigns) do
    ~H"""
    <.form
      id="announcement_form"
      for={@form}
      phx-change="change_announcement"
      phx-submit="save_announcement"
      data-testid="announcement-form"
    >
      <%= unless @published? do %>
        <.radio_group
          form={@form}
          field={:kind}
          label_text={@labels.kind}
          items={radio_items(@labels.kinds, @form[:kind].value)}
        />
        <.spacing value="S" />
      <% end %>
      <.text_input form={@form} field={:title} label_text={@labels.title} maxlength="255" />
      <.text_input form={@form} field={:summary} label_text={@labels.summary} />
      <.wysiwyg_area form={@form} field={:body} label_text={@labels.body} attachments={false} />
      <%= unless @published? do %>
        <.radio_group
          form={@form}
          field={:priority}
          label_text={@labels.priority}
          items={radio_items(@labels.priorities, @form[:priority].value)}
        />
      <% end %>
    </.form>
    """
  end

  # Outside the form: the filters and the search bar are forms of their own.
  attr(:audience, :map, required: true)
  attr(:query_string, :string, required: true)

  defp audience(assigns) do
    ~H"""
    <div data-testid="announcement-audience">
      <Text.title6><%= @audience.label %></Text.title6>
      <.spacing value="XS" />
      <div class="flex flex-row flex-wrap gap-3 items-center">
        <Selector.Item.label item={%{value: @audience.creators_label, active: true}} />
        <%= for item <- @audience.filter_labels do %>
          <div
            class="cursor-pointer select-none"
            phx-click="toggle_audience_filter"
            phx-value-filter={item.id}
            data-testid={"audience-filter-#{item.id}"}
          >
            <Selector.Item.label item={item} />
          </div>
        <% end %>
        <div class="flex-grow" />
        <div class="flex-shrink-0">
          <.live_component
            module={SearchBar}
            id={:announcement_audience_search}
            query_string={@query_string}
            placeholder={@audience.search_placeholder}
            debounce="200"
          />
        </div>
      </div>
      <.spacing value="S" />
      <Text.body_medium testid="announcement-recipient-count"><%= @audience.recipient_text %></Text.body_medium>
      <Text.body_medium testid="announcement-email-notice"><%= @audience.email_text %></Text.body_medium>
    </div>
    """
  end

  attr(:labels, :map, required: true)
  attr(:recipient_count, :integer, default: 0)
  attr(:publish?, :boolean, required: true)

  defp compose_buttons(assigns) do
    ~H"""
    <div class="flex flex-row gap-4">
      <Button.dynamic
        action={%{type: :submit, form_id: "announcement_form"}}
        face={%{type: :secondary, label: @labels.save_button}}
        testid="save-announcement-button"
      />
      <%= if @publish? and @recipient_count > 0 do %>
        <button
          type="submit"
          form="announcement_form"
          name="publish"
          value={@recipient_count}
          class="cursor-pointer focus:outline-none"
          data-testid="publish-announcement-button"
        >
          <Button.Face.primary label={@labels.publish_button} />
        </button>
      <% end %>
      <%= if @publish? and @recipient_count == 0 do %>
        <Button.dynamic
          action={%{type: :fake}}
          face={%{type: :primary, label: @labels.publish_button}}
          enabled?={false}
          testid="publish-announcement-button"
        />
      <% end %>
      <Button.dynamic
        action={%{type: :send, event: "cancel_announcement"}}
        face={%{type: :label, label: @labels.cancel_button}}
      />
    </div>
    """
  end

  attr(:head_cells, :list, required: true)
  attr(:items, :list, required: true)
  attr(:buttons?, :boolean, required: true)

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
              <%= if @buttons? do %>
                <%= for button <- item.buttons do %>
                  <Button.dynamic {button} testid={"edit-announcement-#{item.id}"} />
                <% end %>
              <% end %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end
end
