defmodule Systems.Announcement.Page do
  @moduledoc """
  An announcement as its recipient reads it: title, publication date and the
  cleaned body. Opening it marks it read and clears its To-do
  (`Systems.Announcement.Public.mark_read/1`); Desktop and the To-do counter
  refresh through their own switches on `{:next_action, :cleared}`.

  Users who did not receive the announcement, and everyone while the
  `:announcements` flag is off, get not-found.
  """
  use Systems.Content.Composer, :live_workspace

  alias Systems.Announcement

  @impl true
  def get_model(%{"id" => id}, _session, %{assigns: %{current_user: user}} = _socket) do
    with true <- feature_enabled?(:announcements),
         {announcement_id, ""} <- Integer.parse(id),
         %Announcement.RecipientModel{} = recipient <-
           Announcement.Public.get_received(user, announcement_id) do
      recipient
    else
      _ -> raise Ecto.NoResultsError, queryable: Announcement.RecipientModel
    end
  end

  @impl true
  def mount(_params, _session, %{assigns: %{model: recipient}} = socket) do
    if connected?(socket) do
      Announcement.Public.mark_read(recipient)
    end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={@vm.title} menus={@menus} modal={@modal} socket={@socket}>
      <Area.content>
        <Margin.y id={:page_top} />
        <div data-testid="announcement-title">
          <Text.title2><%= @vm.announcement_title %></Text.title2>
        </div>
        <div data-testid="announcement-published">
          <Text.body_medium color="text-grey2"><%= @vm.published %></Text.body_medium>
        </div>
        <.spacing value="M" />
        <div class="wysiwyg" data-testid="announcement-body">
          <%= raw(@vm.body) %>
        </div>
      </Area.content>
    </.live_workspace>
    """
  end
end
