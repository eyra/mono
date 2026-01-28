defmodule Systems.Project.OverviewPage do
  use Systems.Content.Composer, :live_workspace

  import Frameworks.Pixel.Empty

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.Text

  alias Systems.Account
  alias Systems.Project

  @impl true
  def get_model(_params, _session, %{assigns: %{current_user: user}}), do: user

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_view_model_updated(socket), do: socket |> update_child(:people_page)

  @impl true
  def compose(:project_form, %{active_project: project_id, vm: %{projects: projects}}) do
    project = Enum.find(projects, &(&1.id == String.to_integer(project_id)))

    %{
      module: Project.Form,
      params: %{
        project: project
      }
    }
  end

  @impl true
  def compose(:people_page, %{active_project: project_id, current_user: current_user} = _) do
    project =
      project_id
      |> String.to_integer()
      |> Project.Public.get!()

    owners = Project.Public.list_owners(project, [:profile])
    owner_ids = Enum.map(owners, & &1.id)

    creators =
      Account.Public.list_creators([:profile])
      |> Enum.reject(&Enum.member?(owner_ids, &1.id))

    %{
      module: Account.PeopleView,
      params: %{
        context: project.name,
        title: dgettext("eyra-project", "admins.title"),
        people: owners,
        users: creators,
        current_user: current_user
      }
    }
  end

  def compose(:delete_confirm, _) do
    item = dgettext("eyra-project", "delete.confirm")
    title = String.capitalize(dgettext("eyra-ui", "delete.confirm.title", item: item))
    text = String.capitalize(dgettext("eyra-ui", "delete.confirm.text", item: item))
    primary_button_label = dgettext("eyra-ui", "delete.confirm.label")

    %{
      module: CoreWeb.UI.Dialog.Plain,
      params: %{
        type: :confirm,
        id: "delete_confirm",
        title: title,
        text: text,
        primary_button_label: primary_button_label
      }
    }
  end

  @impl true
  def handle_event(
        "card_clicked",
        %{"item" => card_id},
        %{assigns: %{vm: %{cards: cards}}} = socket
      ) do
    card_id = String.to_integer(card_id)
    %{path: path} = Enum.find(cards, &(&1.id == card_id))
    {:noreply, push_navigate(socket, to: path)}
  end

  @impl true
  def handle_event(
        "rename",
        %{"item" => project_id},
        socket
      ) do
    {
      :noreply,
      socket
      |> assign(active_project: project_id)
      |> compose_child(:project_form)
      |> Fabric.ModalController.show_modal(:project_form, :compact)
    }
  end

  @impl true
  def handle_event("delete", %{"item" => project_id}, socket) do
    {
      :noreply,
      socket
      |> assign(project_id: String.to_integer(project_id))
      |> compose_child(:delete_confirm)
      |> Fabric.ModalController.show_modal(:delete_confirm, :compact)
    }
  end

  @impl true
  def handle_event("confirm_ok", _params, %{assigns: %{project_id: project_id}} = socket) do
    Project.Public.delete(project_id)

    {
      :noreply,
      socket
      |> assign(
        project_id: nil,
        dialog: nil
      )
      |> update_view_model()
      |> update_menus()
      |> Fabric.ModalController.hide_modal(:delete_confirm)
    }
  end

  @impl true
  def handle_event("confirm_cancel", _params, socket) do
    {
      :noreply,
      socket
      |> assign(project_id: nil, dialog: nil)
      |> Fabric.ModalController.hide_modal(:delete_confirm)
    }
  end

  @impl true
  def handle_event("setup_people", %{"item" => project_id}, socket) do
    {
      :noreply,
      socket
      |> assign(active_project: project_id)
      |> compose_child(:people_page)
      |> Fabric.ModalController.show_modal(:people_page, :sheet)
    }
  end

  @impl true
  def handle_event("create_project", _params, %{assigns: %{current_user: user}} = socket) do
    user
    |> Project.Public.new_project_name()
    |> Project.Assembly.create(user, :empty)

    {
      :noreply,
      socket
      |> update_view_model()
    }
  end

  @impl true
  def handle_event("add_user", %{user: user}, %{assigns: %{active_project: project_id}} = socket) do
    case project_id
         |> Project.Public.get!()
         |> Project.Public.add_owner!(user) do
      {:ok, _} ->
        {:noreply, socket}

      {:error, name, error, _} ->
        raise "Failed to add owner to project: #{name} => #{inspect(error)}"
    end
  end

  @impl true
  def handle_event(
        "remove_user",
        %{user: user},
        %{assigns: %{active_project: project_id}} = socket
      ) do
    case project_id
         |> Project.Public.get!()
         |> Project.Public.remove_owner!(user) do
      {:ok, _} ->
        {:noreply, socket}

      {:error, name, error, _} ->
        raise "Failed to remove owner from project: #{name} => #{inspect(error)}"
    end
  end

  @impl true
  def handle_event("finish", %{source: %{name: modal_view}}, socket) do
    {:noreply, socket |> Fabric.ModalController.hide_modal(modal_view)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={@vm.title} menus={@menus} modal={@modal} socket={@socket}>
      <Area.content>
        <Margin.y id={:page_top} />
        <%= if Enum.count(@vm.cards) > 0 do %>
          <div class="flex flex-row items-center justify-center">
            <div class="h-full">
              <Text.title2 margin="">
                <%= dgettext("eyra-project", "overview.header.title") %>
                <span class="text-primary"> <%= Enum.count(@vm.cards) %></span>
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
            <%= for card <- @vm.cards do %>
              <Project.CardView.dynamic card={card}/>
            <% end %>
          </Grid.dynamic>
          <.spacing value="L" />
        <% else %>
          <.empty
            title={dgettext("eyra-project", "overview.empty.title")}
            body={dgettext("eyra-project", "overview.empty.description")}
            illustration="cards"
            button={%{
              action: %{type: :send, event: "create_project"},
              face: %{type: :primary, label: dgettext("eyra-project", "add.first.button")}
            }}
          />
        <% end %>
      </Area.content>
    </.live_workspace>
    """
  end
end
