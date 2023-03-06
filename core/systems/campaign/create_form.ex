defmodule Systems.Campaign.CreateForm do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.Selector.Selector
  alias Frameworks.Pixel.Text.{Title3, FormFieldLabel}

  alias Systems.{
    Campaign,
    Assignment,
    Pool,
    Director
  }

  prop(user, :any)
  prop(target, :any)

  data(title, :string)
  data(buttons, :list)

  data(pools, :list)
  data(pool_labels, :list)
  data(tool_type_labels, :list)

  data(selected_tool_type, :map)
  data(selected_pool, :map)

  # Handle Tool Type Selector Update
  def update(
        %{active_item_id: active_item_id, selector_id: :tool_type_selector},
        %{assigns: %{tool_type_labels: tool_type_labels}} = socket
      ) do
    %{id: selected_tool_type} = Enum.find(tool_type_labels, &(&1.id == active_item_id))

    {
      :ok,
      socket
      |> assign(selected_tool_type: selected_tool_type)
    }
  end

  # Handle Pool Selector Update
  def update(
        %{active_item_id: active_item_id, selector_id: :pool_selector},
        %{assigns: %{pools: pools}} = socket
      ) do
    selected_pool = Enum.find(pools, &(&1.id == active_item_id))

    {
      :ok,
      socket
      |> assign(selected_pool: selected_pool)
    }
  end

  # Initial Update

  def update(%{id: id, user: user, target: target}, socket) do
    title = dgettext("eyra-campaign", "campaign.create.title")

    {
      :ok,
      socket
      |> assign(id: id, user: user, target: target, title: title)
      |> init_tool_types()
      |> init_pools()
      |> init_buttons()
    }
  end

  defp init_tool_types(socket) do
    selected_tool_type = :online
    tool_type_labels = Assignment.ToolTypes.labels(selected_tool_type)
    socket |> assign(tool_type_labels: tool_type_labels, selected_tool_type: selected_tool_type)
  end

  defp init_pools(socket) do
    pools = Pool.Public.list_active(Pool.Model.preload_graph(:full))

    selected_pool = List.first(pools)

    pool_labels =
      pools
      |> Enum.with_index()
      |> Enum.map(&to_label(&1))

    socket |> assign(pools: pools, pool_labels: pool_labels, selected_pool: selected_pool)
  end

  defp to_label({%Pool.Model{id: id, name: name}, index}) do
    %{id: id, value: Pool.Model.title(name), active: index == 0}
  end

  defp init_buttons(%{assigns: %{myself: myself}} = socket) do
    socket
    |> assign(
      buttons: [
        %{
          action: %{type: :send, event: "proceed", target: myself},
          face: %{
            type: :primary,
            label: dgettext("eyra-campaign", "campaign.create.proceed.button")
          }
        },
        %{
          action: %{type: :send, event: "cancel", target: myself},
          face: %{type: :label, label: dgettext("eyra-ui", "cancel.button")}
        }
      ]
    )
  end

  @impl true
  def handle_event(
        "proceed",
        _,
        %{assigns: %{selected_tool_type: selected_tool_type, selected_pool: selected_pool}} =
          socket
      ) do
    campaign = create_campaign(socket, selected_tool_type, selected_pool)
    {:noreply, socket |> redirect_to(campaign.id)}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    {:noreply, socket |> close()}
  end

  defp close(%{assigns: %{target: target}} = socket) do
    update_target(target, %{module: __MODULE__, action: :close})
    socket
  end

  defp redirect_to(%{assigns: %{target: target}} = socket, campaign_id) do
    update_target(target, %{module: __MODULE__, action: %{redirect_to: campaign_id}})
    socket
  end

  defp create_campaign(
         %{assigns: %{user: %{id: user_id}}} = socket,
         tool_type,
         %{id: currency_id} = pool
       ) do
    budget = Director.get(pool).resolve_budget(currency_id, user_id)
    socket |> create_campaign(tool_type, pool, budget)
  end

  defp create_campaign(%{assigns: %{user: user}} = _socket, tool_type, pool, budget) do
    title = dgettext("eyra-dashboard", "default.study.title")
    Campaign.Assembly.create(user, title, tool_type, pool, budget)
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <Title3>{@title}</Title3>
      <Spacing value="XS" />

      <FormFieldLabel id={:tool_type_label}>
        {dgettext("eyra-campaign", "campaign.create.tooltype.label")}
      </FormFieldLabel>
      <Spacing value="XXS" />
      <Selector
        id={:tool_type_selector}
        items={@tool_type_labels}
        type={:radio}
        optional?={false}
        parent={%{type: __MODULE__, id: @id}}
      />

      <Spacing value="M" />

      <FormFieldLabel id={:pool_label}>
        {dgettext("eyra-campaign", "campaign.create.pool.label")}
      </FormFieldLabel>
      <Spacing value="XXS" />
      <Selector
        id={:pool_selector}
        items={@pool_labels}
        type={:radio}
        optional?={false}
        parent={%{type: __MODULE__, id: @id}}
      />

      <Spacing value="M" />
      <div class="flex flex-row gap-4">
        <DynamicButton :for={button <- @buttons} vm={button} />
      </div>
    </div>
    """
  end
end
