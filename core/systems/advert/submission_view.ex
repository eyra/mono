defmodule Systems.Advert.SubmissionView do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text
  alias Systems.Advert
  alias Systems.Pool

  @impl true
  def update(%{vm: vm}, socket) do
    {
      :ok,
      socket
      |> assign(vm: vm)
      |> build_children()
    }
  end

  defp compose_inclusion_selectors(
         %{assigns: %{vm: %{selector_option_labels: selector_option_labels}}} = socket
       ) do
    selector_option_labels
    |> Map.keys()
    |> Enum.reduce(socket, fn key, socket -> compose_child(socket, key) end)
  end

  @impl true
  def compose(:exclude_adverts, %{vm: %{advert_labels: items}}) do
    %{
      module: Selector,
      params: %{
        grid_options: "flex flex-col flex-wrap gap-y-3",
        items: items,
        type: :checkbox
      }
    }
  end

  @impl true
  def compose(:genders, %{vm: %{selector_option_labels: selector_option_labels}}) do
    items = Map.get(selector_option_labels, :genders)

    %{
      module: Selector,
      params: %{
        grid_options: "flex flex-col flex-wrap gap-y-3",
        items: items,
        type: :checkbox
      }
    }
  end

  defp persist_criteria_changes(
         %{assigns: %{vm: %{entity: %{criteria: criteria}}}} = socket,
         attrs
       ) do
    changeset = Pool.CriteriaModel.changeset(criteria, attrs)

    socket
    |> save(changeset)
    |> flash_persister_saved()
  end

  defp inclusion_criterium_title(:genders), do: dgettext("eyra-account", "features.gender.title")

  defp inclusion_criterium_title(:birth_years),
    do: dgettext("eyra-account", "features.birthyear.title")

  @impl true
  def handle_event(
        "active_item_ids",
        %{
          active_item_ids: excluded_advert_ids,
          source: %{name: :exclude_adverts},
          current_items: current_items
        },
        %{assigns: %{vm: %{assignment: assignment}}} = socket
      ) do
    Advert.Public.handle_exclusion(assignment, current_items)
    excluded_user_ids = Advert.Public.list_excluded_user_ids(excluded_advert_ids)

    {
      :noreply,
      socket
      |> assign(excluded_user_ids: excluded_user_ids)
      |> flash_persister_saved()
    }
  end

  @impl true
  def handle_event(
        "active_item_ids",
        %{
          active_item_ids: selected_values,
          source: %{name: criteria_field}
        },
        socket
      )
      when criteria_field == :genders do
    attrs = %{criteria_field => selected_values}

    {
      :noreply,
      socket
      |> persist_criteria_changes(attrs)
    }
  end

  @impl true
  def handle_event("change", %{"criteria_model" => attrs}, socket) do
    {
      :noreply,
      socket
      |> persist_criteria_changes(attrs)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2 margin=""><%= dgettext("link-advert", "submission.criteria.title") %></Text.title2>
        <.spacing value="M" />
        <Text.sub_head color="text-grey1">
          <%= raw(
            dgettext("link-advert", "submission.criteria.status",
              sample: "<span class=\"text-primary\">#{@vm.sample_size}</span>",
              total: @vm.pool_size,
              pool: @vm.pool_title
            )
          ) %>
        </Text.sub_head>
        <.spacing value="M" />
        <div class="flex flex-col-reverse xl:flex-row gap-8 xl:gap-14">
          <div class="xl:max-w-form">
            <Text.title3><%= dgettext("eyra-account", "features.title") %></Text.title3>
            <Text.body_medium><%= dgettext("eyra-account", "features.content.description") %></Text.body_medium>
            <.spacing value="M" />

            <div class="flex flex-col gap-14">
              <.render_inclusion_selectors selector_option_labels={@vm.selector_option_labels} fabric={@fabric} />

              <.render_age_inputs changeset={@vm.changeset} myself={@myself} />
            </div>

            <.spacing value="XL" />
          </div>
          <div class="xl:max-w-form">
            <Text.title3><%= dgettext("link-advert", "exclusion.title") %></Text.title3>
            <Text.body_medium><%= dgettext("link-advert", "exclusion.description") %></Text.body_medium>
            <.spacing value="M" />
            <Text.title4><%= dgettext("link-advert", "exclusion.select.label") %></Text.title4>
            <.spacing value="S" />

            <%= if Enum.count(@vm.advert_labels) == 0 do %>
              <Text.title6 color="text-grey2" margin="m-0"><%= dgettext("link-advert", "no.previous.adverts.available") %></Text.title6>
            <% else %>
              <.child name={:exclude_adverts} fabric={@fabric} />
            <% end %>
            <.spacing value="XL" />
          </div>
        </div>
      </Area.content>
    </div>
    """
  end

  defp render_age_inputs(assigns) do
    ~H"""
    <div>
      <Text.title4>
        <%= inclusion_criterium_title(:birth_years) %>
      </Text.title4>
      <.spacing value="S" />
      <.form :let={form} for={@changeset} phx-change="change" phx-target={@myself}>
        <div class="flex gap-4">
          <.number_input form={form} field={:min_birth_year} label_text={dgettext("link-advert", "submission.criteria.birth_years.min_label")} />
          <.number_input form={form} field={:max_birth_year} label_text={dgettext("link-advert", "submission.criteria.birth_years.max_label")} />
        </div>
      </.form>
    </div>
    """
  end

  defp render_inclusion_selectors(assigns) do
    ~H"""
    <div>
      <%= for field <- Map.keys(@selector_option_labels) do %>
        <div>
          <Text.title4><%= inclusion_criterium_title(field) %></Text.title4>
          <.spacing value="S" />
          <.child name={field} fabric={@fabric} />
        </div>
      <% end %>
    </div>
    """
  end

  defp build_children(socket) do
    socket
    |> compose_child(:exclude_adverts)
    |> compose_inclusion_selectors()
  end
end
