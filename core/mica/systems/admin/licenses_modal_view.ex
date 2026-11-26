defmodule Systems.Admin.LicensesModalView do
  @moduledoc """
  The Licenses dialog of a researcher on Admin → Users: Publish and Pay-in,
  each switched on or off, with an end date picked from a period or a custom
  date. Saving goes through `License.Public.save/4`, which only system admins
  pass.
  """
  use MicaWeb, :modal_live_view

  alias Frameworks.Pixel
  alias Frameworks.Pixel.Text
  alias Systems.Account
  alias Systems.License

  @modal_id "licenses-modal"

  def modal_id, do: @modal_id

  def get_model(:not_mounted_at_router, %{"user_id" => user_id}, _assigns) do
    Account.Public.get_user!(user_id)
  end

  @impl true
  def mount(:not_mounted_at_router, session, socket) do
    {
      :ok,
      assign(socket,
        locale: Map.get(session, "locale", :en),
        draft: %{},
        show_errors?: false,
        save_error: nil
      )
    }
  end

  @impl true
  def handle_event("toggle", %{"license" => license}, socket) do
    {:noreply, update_draft(socket, license, &Map.put(&1, :on?, not item(socket, license).on?))}
  end

  @impl true
  def handle_event("toggle_periods", %{"license" => license}, socket) do
    {:noreply,
     update_draft(socket, license, &Map.update(&1, :open?, true, fn open? -> not open? end))}
  end

  @impl true
  def handle_event("pick_period", %{"license" => license, "period" => period}, socket) do
    period = Enum.find(License.Public.periods() ++ [:custom], &(to_string(&1) == period))
    {:noreply, update_draft(socket, license, &Map.merge(&1, %{period: period, open?: false}))}
  end

  @impl true
  def handle_event("custom_date", %{"license" => license, "custom_date" => date}, socket) do
    {:noreply, update_draft(socket, license, &Map.put(&1, :custom_date, date))}
  end

  @impl true
  def handle_event("save", _params, %{assigns: %{vm: %{items: items}}} = socket) do
    if Enum.any?(items, &match?({:error, _}, &1.change)) do
      {:noreply, socket |> assign(show_errors?: true) |> update_view_model()}
    else
      save(socket, items)
    end
  end

  defp save(%{assigns: %{current_user: by, model: user}} = socket, items) do
    changes =
      for %{id: license, change: change} <- items,
          change != :none,
          into: %{},
          do: {license, change}

    if changes == %{}, do: {:noreply, close(socket)}, else: save(socket, by, user, changes)
  end

  # Saved, the dialog shows the saved state, so a second Save before it closes
  # changes nothing.
  defp save(socket, by, user, changes) do
    case License.Public.save(by, user, changes) do
      :ok ->
        {:noreply, socket |> assign(draft: %{}) |> update_view_model() |> close()}

      {:error, reason} ->
        {:noreply,
         socket |> assign(show_errors?: true, save_error: reason) |> update_view_model()}
    end
  end

  defp close(socket), do: publish_event(socket, {:close_modal, %{modal_id: @modal_id}})

  defp item(%{assigns: %{vm: %{items: items}}}, license),
    do: Enum.find(items, &(to_string(&1.id) == license))

  defp update_draft(socket, license_string, fun) do
    case item(socket, license_string) do
      nil ->
        socket

      %{id: license} ->
        draft = Map.update(socket.assigns.draft, license, fun.(%{}), fun)
        socket |> assign(draft: draft) |> update_view_model()
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={modal_id()} data-testid="licenses-modal" class="flex flex-col gap-8">
      <div>
        <Text.title2 margin="mb-2"><%= @vm.title %></Text.title2>
        <Text.body_small color="text-grey2"><%= @vm.user_label %></Text.body_small>
      </div>

      <%= for item <- @vm.items do %>
        <.license_item item={item} />
      <% end %>

      <%= if @vm.error do %>
        <Pixel.message_bar tone={:warning} data-testid="licenses-error"><%= @vm.error %></Pixel.message_bar>
      <% end %>

      <div>
        <Pixel.button variant={:primary} phx-click="save" data-testid="licenses-save">
          <%= @vm.save_label %>
        </Pixel.button>
      </div>
    </div>
    """
  end

  attr(:item, :map, required: true)

  defp license_item(assigns) do
    ~H"""
    <div class="flex flex-col gap-4" data-testid={"license-#{@item.id}"}>
      <label class="flex flex-row gap-3 items-center cursor-pointer w-fit">
        <Pixel.checkbox
          checked={@item.on?}
          phx-click="toggle"
          phx-value-license={@item.id}
          data-testid={"license-#{@item.id}-checkbox"}
        />
        <Text.title5 align="text-left"><%= @item.label %></Text.title5>
      </label>
      <div class="flex flex-col gap-1">
        <Text.body_small testid={"license-#{@item.id}-status"}><%= @item.status %></Text.body_small>
        <%= if @item.note do %>
          <Text.body_small color="text-grey2"><%= @item.note %></Text.body_small>
        <% end %>
      </div>

      <%= if @item.institutes do %>
        <%= if @item.institutes.warning do %>
          <div class="flex flex-col gap-2">
            <Pixel.message_bar tone={:warning} data-testid={"license-#{@item.id}-institute-warning"}>
              <%= @item.institutes.warning %>
            </Pixel.message_bar>
            <Text.body_small color="text-grey2"><%= @item.institutes.note %></Text.body_small>
          </div>
        <% else %>
          <Text.body_small testid={"license-#{@item.id}-institutes"}><%= @item.institutes.names %></Text.body_small>
        <% end %>
      <% end %>

      <%= if @item.select do %>
        <Pixel.field invalid={@item.error != nil}>
          <:label><%= @item.select.label %></:label>
          <%!-- The field is the select's own button, so a click on it reaches the select.
               It keeps white space (pre-wrap), so the value has none around it. --%>
          <Pixel.select
            phx-no-format
            invalid={@item.error != nil}
            phx-click="toggle_periods"
            phx-click-away={@item.select.open? && "toggle_periods"}
            phx-value-license={@item.id}
            data-testid={"license-#{@item.id}-select"}
          ><span class={["block text-left", @item.select.placeholder? && "text-grey2"]}><%= @item.select.value %></span><:option
              :for={option <- if(@item.select.open?, do: @item.select.options, else: [])}
              selected={option.selected?}
              phx-click="pick_period"
              phx-value-license={@item.id}
              phx-value-period={option.id}
              data-testid={"license-#{@item.id}-period-#{option.id}"}
            ><%= option.label %></:option><:icon><img src={~m"/images/icons/dropdown.svg"} alt="" /></:icon></Pixel.select>
          <:error_message :if={@item.error && not @item.custom?}><%= @item.error %></:error_message>
        </Pixel.field>
      <% end %>

      <%= if @item.custom? do %>
        <form phx-change="custom_date" data-testid={"license-#{@item.id}-custom-form"}>
          <input type="hidden" name="license" value={@item.id} />
          <Pixel.field invalid={@item.error != nil}>
            <:label><%= @item.custom_label %></:label>
            <Pixel.text_field
              type="date"
              name="custom_date"
              value={@item.custom_date}
              min={@item.min_date}
              invalid={@item.error != nil}
              data-testid={"license-#{@item.id}-custom-date"}
            />
            <:error_message :if={@item.error}><%= @item.error %></:error_message>
          </Pixel.field>
        </form>
      <% end %>
    </div>
    """
  end
end
