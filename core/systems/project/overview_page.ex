defmodule Systems.Project.OverviewPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :projects
  use CoreWeb.UI.PlainDialog

  import CoreWeb.Layouts.Workspace.Component
  alias CoreWeb.UI.SelectorDialog

  alias Frameworks.Utility.ViewModelBuilder
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.ShareView

  alias Systems.{
    Project
  }

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(
        dialog: nil,
        popup: nil,
        selector_dialog: nil
      )
      |> update_projects()
      |> update_menus()
    }
  end

  defp update_projects(%{assigns: %{current_user: user}} = socket) do
    preload = Project.Model.preload_graph(:full)

    projects =
      user
      |> Project.Public.list_owned_projects(preload: preload)
      |> Enum.map(
        &ViewModelBuilder.view_model(&1, {__MODULE__, :card}, user, url_resolver(socket))
      )

    socket
    |> assign(
      projects: projects,
      dialog: nil,
      popup: nil,
      selector_dialog: nil
    )
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  @impl true
  def handle_event("delete", %{"item" => project_id}, socket) do
    item = dgettext("eyra-project", "delete.confirm")
    title = String.capitalize(dgettext("eyra-ui", "delete.confirm.title", item: item))
    text = String.capitalize(dgettext("eyra-ui", "delete.confirm.text", item: item))
    confirm_label = dgettext("eyra-ui", "delete.confirm.label")

    {
      :noreply,
      socket
      |> assign(project_id: String.to_integer(project_id))
      |> confirm("delete", title, text, confirm_label)
    }
  end

  @impl true
  def handle_event("delete_confirm", _params, %{assigns: %{project_id: project_id}} = socket) do
    Project.Public.delete(project_id)

    {
      :noreply,
      socket
      |> assign(
        project_id: nil,
        dialog: nil
      )
      |> update_projects()
      |> update_menus()
    }
  end

  @impl true
  def handle_event("delete_cancel", _params, socket) do
    {:noreply, socket |> assign(project_id: nil, dialog: nil)}
  end

  @impl true
  def handle_event("close_share_dialog", _, socket) do
    IO.puts("close_share_dialog")
    {:noreply, socket |> assign(popup: nil)}
  end

  @impl true
  def handle_event("share", %{"item" => project_id}, %{assigns: %{current_user: user}} = socket) do
    researchers =
      Core.Accounts.list_researchers([:profile])
      # filter current user
      |> Enum.filter(&(&1.id != user.id))

    owners =
      project_id
      |> String.to_integer()
      |> Project.Public.get!()
      |> Project.Public.list_owners([:profile])
      # filter current user
      |> Enum.filter(&(&1.id != user.id))

    popup = %{
      module: ShareView,
      content_id: project_id,
      content_name: dgettext("eyra-project", "share.dialog.content"),
      group_name: dgettext("eyra-project", "share.dialog.group"),
      users: researchers,
      shared_users: owners
    }

    {
      :noreply,
      socket |> assign(popup: popup)
    }
  end

  @impl true
  def handle_event("duplicate", %{"item" => project_id}, socket) do
    preload = Project.Model.preload_graph(:full)
    _project = Project.Public.get!(String.to_integer(project_id), preload)

    # Project.Assembly.copy(project)

    {
      :noreply,
      socket
      |> update_projects()
      |> update_menus()
    }
  end

  @impl true
  def handle_event("create_project", _params, %{assigns: %{current_user: user}} = socket) do
    name = dgettext("eyra-project", "default.project.name")
    {:ok, %{project: project}} = Project.Assembly.create(name, user)

    {
      :noreply,
      socket
      |> push_redirect(to: ~p"/projects/#{project.id}/content")
    }
  end

  @impl true
  def handle_info(%{selector: :cancel}, socket) do
    {:noreply, socket |> assign(selector_dialog: nil)}
  end

  @impl true
  def handle_info({:card_click, %{action: :edit, id: id}}, socket) do
    {:noreply,
     push_redirect(socket, to: CoreWeb.Router.Helpers.live_path(socket, Project.ContentPage, id))}
  end

  @impl true
  def handle_info(%{module: _, action: :close}, socket) do
    {:noreply, socket |> assign(popup: nil)}
  end

  @impl true
  def handle_info(
        %{module: Frameworks.Pixel.ShareView, action: %{add: user, content_id: project_id}},
        socket
      ) do
    project_id
    |> Project.Public.get!()
    |> Project.Public.add_owner!(user)

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        %{module: Frameworks.Pixel.ShareView, action: %{remove: user, content_id: project_id}},
        socket
      ) do
    project_id
    |> Project.Public.get!()
    |> Project.Public.remove_owner!(user)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={dgettext("eyra-project", "overview.title")} menus={@menus}>

      <%= if @popup do %>
        <.popup>
          <div class="p-8 w-popup-md bg-white shadow-2xl rounded">
            <.live_component id={:project_overview_popup} module={@popup.module} {@popup} />
          </div>
        </.popup>
      <% end %>

      <%= if @dialog do %>
        <div class="fixed z-40 left-0 top-0 w-full h-full bg-black bg-opacity-20">
          <div class="flex flex-row items-center justify-center w-full h-full">
            <.plain_dialog {@dialog} />
          </div>
        </div>
      <% end %>

      <%= if @selector_dialog do %>
        <div class="fixed z-40 left-0 top-0 w-full h-full bg-black bg-opacity-20">
          <div class="flex flex-row items-center justify-center w-full h-full">
            <.live_component module={SelectorDialog} id={:selector_dialog} {@selector_dialog} />
          </div>
        </div>
      <% end %>

      <Area.content>
        <Margin.y id={:page_top} />
        <%= if Enum.count(@projects) > 0 do %>
          <div class="flex flex-row items-center justify-center">
            <div class="h-full">
              <Text.title2 margin="">
                <%= dgettext("eyra-project", "overview.header.title") %>
                <span class="text-primary"> <%= Enum.count(@projects) %></span>
              </Text.title2>
            </div>
            <div class="flex-grow">
            </div>
            <div class="h-full pt-2px lg:pt-1">
              <Button.Action.send event="create_project">
                <div class="sm:hidden">
                  <Button.Face.plain_icon label={dgettext("eyra-project", "add.new.button.short")} icon={:forward} />
                </div>
                <div class="hidden sm:block">
                  <Button.Face.plain_icon label={dgettext("eyra-project", "add.new.button")} icon={:forward} />
                </div>
              </Button.Action.send>
            </div>
          </div>
          <Margin.y id={:title2_bottom} />
          <Grid.dynamic>
            <%= for projects <- @projects do %>
              <Project.CardView.dynamic
                card={projects}
                click_event_data={%{action: :edit, id: projects.id}}
              />
            <% end %>
          </Grid.dynamic>
          <.spacing value="L" />
        <% else %>
          <.empty
            title={dgettext("eyra-project", "overview.empty.title")}
            body={dgettext("eyra-project", "overview.empty.description")}
            illustration="cards"
          />
          <.spacing value="L" />
          <Button.primary_live_view
            label={dgettext("eyra-project", "add.first.button")}
            event="create_project"
          />
        <% end %>
      </Area.content>
    </.workspace>
    """
  end
end
