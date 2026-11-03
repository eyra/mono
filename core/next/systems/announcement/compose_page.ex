defmodule Next.Systems.Announcement.ComposePage do
  @moduledoc """
  The page to compose an announcement: `/admin/announcement/new` for a new one,
  `/admin/announcement/:id` to open one from the list on the Admin page.
  Saving stores the announcement unpublished. Publishing sends it to the
  audience chosen below the form: creators, narrowed by the Admin → Users
  filters and search. The server resolves the audience itself
  (`Next.Systems.Announcement.Public.publish_announcement/4`). Saved,
  published or cancelled, it goes back to the list.

  A published announcement opens with only its title, summary and body:
  saving shows the changes to its recipients without sending it again
  (`Next.Systems.Announcement.Public.update_announcement/2`).

  Only system admins open it, and only while the `announcements` flag is on;
  every event checks both again.
  """
  use Systems.Content.Composer, {:live_workspace, :live_nest}

  import Frameworks.Pixel.Form

  alias Frameworks.GreenLight.AccessDeniedError
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text
  alias Next.Systems.Announcement
  alias Systems.Admin

  # Org admins have the `:admin` role too, so the page checks for a system
  # admin itself.
  @impl true
  def get_model(params, _session, %{assigns: %{current_user: user}}) do
    cond do
      not feature_enabled?(:announcements) ->
        raise Ecto.NoResultsError, queryable: Announcement.Model

      not Admin.Public.admin?(user) ->
        raise AccessDeniedError, "Only system admins compose"

      true ->
        load(params)
    end
  end

  # Ids are bigints: anything else, such as 0 or a number too big for the
  # column, is an unknown announcement rather than a database error.
  @max_id 9_223_372_036_854_775_807

  defp load(%{"id" => id}) do
    with {id, ""} when id in 1..@max_id <- Integer.parse(id),
         %Announcement.Model{} = announcement <- Announcement.Public.get_announcement(id) do
      announcement
    else
      _ -> raise Ecto.NoResultsError, queryable: Announcement.Model
    end
  end

  defp load(_params), do: %Announcement.Model{kind: :release_notes, priority: :normal}

  @impl true
  def mount(_params, _session, %{assigns: %{model: announcement}} = socket) do
    {:ok, socket |> open(announcement) |> update_view_model()}
  end

  # Only `stay/2` patches the address, to the draft the page already holds.
  @impl true
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_event(event, params, socket) do
    if allowed?(socket) do
      handle_allowed_event(event, params, socket)
    else
      {:noreply, socket}
    end
  end

  # The audience search (`Frameworks.Pixel.SearchBar`).
  @impl true
  def consume_event(
        %{name: :search_query, payload: %{query: query, query_string: query_string}},
        socket
      ) do
    if allowed?(socket) do
      {
        :stop,
        socket
        |> assign(audience_query: query, audience_query_string: query_string, compose_notice: nil)
        |> update_view_model()
      }
    else
      {:stop, socket}
    end
  end

  defp allowed?(%{assigns: %{current_user: user}}),
    do: feature_enabled?(:announcements) and Admin.Public.admin?(user)

  defp handle_allowed_event("cancel_announcement", _params, socket) do
    {:noreply, back_to_list(socket)}
  end

  # Only the priority changes the view model (whether an email is sent).
  defp handle_allowed_event(
         "change_announcement",
         %{"announcement" => %{"priority" => priority}},
         %{assigns: %{priority: current}} = socket
       ) do
    case to_priority(priority) do
      ^current -> {:noreply, socket}
      priority -> {:noreply, socket |> assign(priority: priority) |> update_view_model()}
    end
  end

  defp handle_allowed_event("change_announcement", _params, socket) do
    {:noreply, socket}
  end

  # The filter chips are rendered here rather than with `Frameworks.Pixel.Selector`:
  # its client-side toggle targets every chip with the same id on the page.
  defp handle_allowed_event(
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
  defp handle_allowed_event("save_announcement", %{"announcement" => attrs} = params, socket) do
    body = params |> Map.get("announcement[body]_input", "") |> open_links_in_new_tab()
    attrs = Map.put(attrs, "body", body)

    {:noreply, submit(socket, attrs, shown_count(params))}
  end

  defp handle_allowed_event(_event, _params, socket), do: {:noreply, socket}

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
        |> assign(announcement: announcement, form: announcement_form(announcement))
        |> publish_or_close(announcement, shown_count)

      {:error, reason} when reason in [:already_published, :changed_since_loaded] ->
        show_notice(socket, reason)

      {:error, changeset} ->
        assign(socket, form: to_form(changeset, as: :announcement))
    end
  end

  defp save(%{assigns: %{announcement: %{id: nil}, current_user: user}}, attrs),
    do: Announcement.Public.create_announcement(user, attrs)

  defp save(%{assigns: %{announcement: announcement}}, attrs),
    do: Announcement.Public.update_announcement(announcement, attrs)

  defp publish_or_close(socket, _announcement, nil), do: back_to_list(socket)

  # When it isn't published the form stays open on the saved announcement,
  # with a notice that says what to change (`stay/2`).
  defp publish_or_close(
         %{assigns: %{audience_filters: filters, audience_query: query}} = socket,
         announcement,
         shown_count
       ) do
    case Announcement.Public.publish_announcement(announcement, filters, query, shown_count) do
      {:ok, _announcement} -> back_to_list(socket)
      {:error, :no_recipients} -> stay(socket, :no_recipients)
      {:error, {:audience_changed, _count}} -> stay(socket, :audience_changed)
      {:error, :already_published} -> stay(socket, :already_published)
    end
  end

  # A new announcement that stays open once saved becomes that announcement's
  # page, so a reload opens the saved draft rather than an empty form.
  defp stay(
         %{assigns: %{model: %{id: nil}, announcement: %{id: id} = announcement}} = socket,
         notice
       )
       when is_integer(id) do
    socket
    |> assign(model: announcement)
    |> show_notice(notice)
    |> push_patch(to: Announcement.Private.compose_path(id))
  end

  defp stay(socket, notice), do: show_notice(socket, notice)

  defp show_notice(socket, notice) do
    socket |> assign(compose_notice: notice) |> update_view_model()
  end

  defp back_to_list(socket) do
    push_navigate(socket, to: ~p"/admin/config?tab=announcements")
  end

  defp open(socket, %Announcement.Model{priority: priority} = announcement) do
    assign(socket,
      announcement: announcement,
      form: announcement_form(announcement),
      priority: priority,
      audience_filters: [],
      audience_query: nil,
      audience_query_string: "",
      compose_notice: nil
    )
  end

  defp announcement_form(announcement) do
    announcement |> Ecto.Changeset.change() |> to_form(as: :announcement)
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

  defp radio_items(options, value) do
    value = to_string(value)

    Enum.map(options, fn {id, label} ->
      %{id: id, value: label, active: to_string(id) == value}
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={@vm.title} menus={@menus} modal={@modal} socket={@socket}>
      <Area.content>
        <Margin.y id={:page_top} />
        <div data-testid="announcement-compose-page">
          <Text.title2><%= @vm.heading %></Text.title2>
          <.spacing value="M" />

          <%= if @vm.published do %>
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
          <% end %>

          <%= if @vm.audience do %>
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
          <% end %>
          <.spacing value="L" />
        </div>
      </Area.content>
    </.live_workspace>
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
      <%= if @publish? do %>
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
      <Button.dynamic
        action={%{type: :send, event: "cancel_announcement"}}
        face={%{type: :label, label: @labels.cancel_button}}
        testid="cancel-announcement-button"
      />
    </div>
    """
  end
end
