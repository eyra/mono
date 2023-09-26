defmodule Systems.Campaign.CreateForm do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text
  alias Frameworks.Concept.Directable

  alias Systems.{
    Campaign,
    Assignment,
    Pool
  }

  # Handle Tool Type Selector Update
  @impl true
  def update(
        %{active_item_id: active_item_id, selector_id: :template_selector},
        %{assigns: %{template_labels: template_labels}} = socket
      ) do
    %{id: selected_template} = Enum.find(template_labels, &(&1.id == active_item_id))

    {
      :ok,
      socket
      |> assign(selected_template: selected_template)
    }
  end

  # Handle Pool Selector Update
  @impl true
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
  @impl true
  def update(%{id: id, user: user, target: target}, socket) do
    title = dgettext("eyra-campaign", "campaign.create.title")

    {
      :ok,
      socket
      |> assign(id: id, user: user, target: target, title: title)
      |> init_templates()
      |> init_pools()
      |> init_buttons()
    }
  end

  defp init_templates(socket) do
    selected_template = :online
    template_labels = Assignment.Templates.labels(selected_template)
    socket |> assign(template_labels: template_labels, selected_template: selected_template)
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
        %{assigns: %{selected_template: selected_template, selected_pool: selected_pool}} = socket
      ) do
    campaign = create_campaign(socket, selected_template, selected_pool)
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
         template,
         %{id: currency_id} = pool
       ) do
    budget = Directable.director(pool).resolve_budget(currency_id, user_id)
    socket |> create_campaign(template, pool, budget)
  end

  defp create_campaign(%{assigns: %{user: user}} = _socket, template, pool, budget) do
    title = dgettext("eyra-dashboard", "default.study.title")
    Campaign.Assembly.create(template, user, title, pool, budget)
  end

  attr(:user, :any)
  attr(:target, :any)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.title3><%= @title %></Text.title3>
      <.spacing value="XS" />

      <Text.form_field_label id={:template_label}>
        <%= dgettext("eyra-campaign", "campaign.create.template.label") %>
      </Text.form_field_label>
      <.spacing value="XXS" />
      <.live_component
        module={Selector}
        id={:template_selector}
        items={@template_labels}
        type={:radio}
        optional?={false}
        parent={%{type: __MODULE__, id: @id}}
      />

      <.spacing value="M" />

      <Text.form_field_label id={:pool_label}>
        <%= dgettext("eyra-campaign", "campaign.create.pool.label") %>
      </Text.form_field_label>
      <.spacing value="XXS" />
      <.live_component
        module={Selector}
        id={:pool_selector}
        items={@pool_labels}
        type={:radio}
        optional?={false}
        parent={%{type: __MODULE__, id: @id}}
      />

      <.spacing value="M" />
      <div class="flex flex-row gap-4">
        <%= for button <- @buttons do %>
          <Button.dynamic {button} />
        <% end %>
      </div>
    </div>
    """
  end
end
