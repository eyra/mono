defmodule Systems.Advert.OverviewPage do
  @moduledoc """
   The recruitment page for researchers.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :recruitment
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
    Advert
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
      |> update_adverts()
      |> update_menus()
    }
  end

  defp update_adverts(%{assigns: %{current_user: user} = assigns} = socket) do
    preload = Advert.Model.preload_graph(:down)

    adverts =
      user
      |> Advert.Public.list_owned_adverts(preload: preload)
      |> Enum.map(&ViewModelBuilder.view_model(&1, {__MODULE__, :card}, assigns))

    socket
    |> assign(
      adverts: adverts,
      dialog: nil,
      popup: nil,
      selector_dialog: nil
    )
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  @impl true
  def handle_event("delete", %{"item" => advert_id}, socket) do
    item = dgettext("link-ui", "delete.confirm.advert")
    title = String.capitalize(dgettext("eyra-ui", "delete.confirm.title", item: item))
    text = String.capitalize(dgettext("eyra-ui", "delete.confirm.text", item: item))
    confirm_label = dgettext("eyra-ui", "delete.confirm.label")

    {
      :noreply,
      socket
      |> assign(advert_id: String.to_integer(advert_id))
      |> confirm("delete", title, text, confirm_label)
    }
  end

  @impl true
  def handle_event("delete_confirm", _params, %{assigns: %{advert_id: advert_id}} = socket) do
    Advert.Public.delete(advert_id)

    {
      :noreply,
      socket
      |> assign(
        advert_id: nil,
        dialog: nil
      )
      |> update_adverts()
      |> update_menus()
    }
  end

  @impl true
  def handle_event("delete_cancel", _params, socket) do
    {:noreply, socket |> assign(advert_id: nil, dialog: nil)}
  end

  @impl true
  def handle_event("close_share_dialog", _, socket) do
    IO.puts("close_share_dialog")
    {:noreply, socket |> assign(popup: nil)}
  end

  @impl true
  def handle_event("share", %{"item" => advert_id}, %{assigns: %{current_user: user}} = socket) do
    researchers =
      Core.Accounts.list_researchers([:profile])
      # filter current user
      |> Enum.filter(&(&1.id != user.id))

    owners =
      advert_id
      |> String.to_integer()
      |> Advert.Public.get!()
      |> Advert.Public.list_owners([:profile])
      # filter current user
      |> Enum.filter(&(&1.id != user.id))

    popup = %{
      module: ShareView,
      content_id: advert_id,
      content_name: dgettext("eyra-advert", "share.dialog.content"),
      group_name: dgettext("eyra-advert", "share.dialog.group"),
      users: researchers,
      shared_users: owners
    }

    {
      :noreply,
      socket |> assign(popup: popup)
    }
  end

  @impl true
  def handle_event("duplicate", %{"item" => advert_id}, socket) do
    preload = Advert.Model.preload_graph(:down)
    advert = Advert.Public.get!(String.to_integer(advert_id), preload)

    Advert.Assembly.copy(advert)

    {
      :noreply,
      socket
      |> update_adverts()
      |> update_menus()
    }
  end

  @impl true
  def handle_event("create_advert", _params, %{assigns: %{current_user: user}} = socket) do
    popup = %{
      module: Advert.CreateForm,
      target: self(),
      user: user
    }

    {:noreply, socket |> assign(popup: popup)}
  end

  @impl true
  def handle_event(
        "card_clicked",
        %{"item" => card_id},
        %{assigns: %{adverts: adverts}} = socket
      ) do
    card_id = String.to_integer(card_id)
    %{path: path} = Enum.find(adverts, &(&1.id == card_id))
    {:noreply, push_redirect(socket, to: path)}
  end

  @impl true
  def handle_info(
        %{module: Systems.Advert.CreateForm, action: %{redirect_to: advert_id}},
        socket
      ) do
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, Advert.ContentPage, advert_id))}
  end

  @impl true
  def handle_info(%{selector: :cancel}, socket) do
    {:noreply, socket |> assign(selector_dialog: nil)}
  end

  @impl true
  def handle_info(%{module: _, action: :close}, socket) do
    {:noreply, socket |> assign(popup: nil)}
  end

  @impl true
  def handle_info(
        %{module: Frameworks.Pixel.ShareView, action: %{add: user, content_id: advert_id}},
        socket
      ) do
    advert_id
    |> Advert.Public.get!()
    |> Advert.Public.add_owner!(user)

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        %{module: Frameworks.Pixel.ShareView, action: %{remove: user, content_id: advert_id}},
        socket
      ) do
    advert_id
    |> Advert.Public.get!()
    |> Advert.Public.remove_owner!(user)

    {:noreply, socket}
  end

  # data(adverts, :list, default: [])
  # data(popup, :any)
  # data(selector_dialog, :map)
  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={dgettext("eyra-alliance", "title")} menus={@menus}>

      <%= if @popup do %>
        <.popup>
          <div class="p-8 w-popup-md bg-white shadow-floating rounded">
            <.live_component id={:advert_overview_popup} module={@popup.module} {@popup} />
          </div>
        </.popup>
      <% end %>

      <%= if @dialog do %>
        <.popup>
          <div class="flex-wrap">
            <.plain_dialog {@dialog} />
          </div>
        </.popup>
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
        <%= if Enum.count(@adverts) > 0 do %>
          <div class="flex flex-row items-center justify-center">
            <div class="h-full">
              <Text.title2 margin=""><%= dgettext("eyra-alliance", "advert.overview.title") %></Text.title2>
            </div>
            <div class="flex-grow">
            </div>
            <div class="h-full pt-2px lg:pt-1">
              <Button.Action.send event="create_advert">
                <div class="sm:hidden">
                  <Button.Face.plain_icon label={dgettext("eyra-alliance", "add.new.button.short")} icon={:forward} />
                </div>
                <div class="hidden sm:block">
                  <Button.Face.plain_icon label={dgettext("eyra-alliance", "add.new.button")} icon={:forward} />
                </div>
              </Button.Action.send>
            </div>
          </div>
          <Margin.y id={:title2_bottom} />
          <Grid.dynamic>
            <%= for advert <- @adverts do %>
              <Advert.CardView.dynamic card={advert} />
            <% end %>
          </Grid.dynamic>
          <.spacing value="L" />
        <% else %>
          <.empty
            title={dgettext("eyra-alliance", "empty.title")}
            body={dgettext("eyra-alliance", "empty.description")}
            illustration="cards"
          />
          <.spacing value="L" />
          <Button.primary_live_view
            label={dgettext("eyra-alliance", "add.first.button")}
            event="create_advert"
          />
        <% end %>
      </Area.content>
    </.workspace>
    """
  end
end
