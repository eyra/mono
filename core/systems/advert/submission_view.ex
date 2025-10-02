defmodule Systems.Advert.SubmissionView do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text

  alias Systems.Advert.AdvertHelpers
  alias Systems.Advert.SelectorLabels

  alias Systems.Advert
  alias Systems.Pool

  @impl true
  def update(
        _,
        %{assigns: %{entity: _}} = socket
      ) do
    {
      :ok,
      socket
      |> update_adverts_list()
      |> compose_child(:exclude_adverts)
      |> update_ui()
    }
  end

  # Initial update
  @impl true
  def update(
        %{
          id: id,
          entity: %{criteria: criteria} = submission,
          user: user
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(entity: criteria)
      |> assign(submission: submission)
      |> assign(user: user)
      |> assign(changeset: Pool.CriteriaModel.changeset(criteria, %{}))
      |> update_adverts_list()
      |> update_ui()
    }
  end

  defp compose_inclusion_selectors(
         %{assigns: %{selector_option_labels: selector_option_labels}} = socket
       ) do
    selector_option_labels
    |> Map.keys()
    |> Enum.reduce(socket, fn key, socket -> compose_child(socket, key) end)
  end

  @impl true
  def compose(:exclude_adverts, %{advert_labels: items}) do
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
  def compose(:genders, %{selector_option_labels: selector_option_labels}) do
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

  defp update_adverts_list(%{assigns: _} = socket) do
    socket
    |> assign(
      AdvertHelpers.update_adverts(%{
        user: socket.assigns.user,
        submission: socket.assigns.submission
      })
    )
  end

  defp update_ui(%{assigns: %{entity: criteria}} = socket) do
    socket
    |> compose_child(:exclude_adverts)
    |> update_ui(criteria)
    |> compose_inclusion_selectors()
  end

  defp update_ui(
         %{
           assigns: %{
             submission: %{pool: %{name: pool_name} = pool},
             excluded_user_ids: excluded_user_ids
           }
         } = socket,
         criteria
       ) do
    selector_option_labels = SelectorLabels.selector_option_labels(pool, criteria)

    user_ids_in_pool =
      pool
      |> Pool.Public.list_participants()
      |> Enum.map(& &1.id)

    pool_size = Enum.count(user_ids_in_pool)
    pool_title = Pool.Model.title(pool_name)

    sample_size =
      Pool.Public.count_eligitable_users(criteria, user_ids_in_pool, excluded_user_ids)

    socket
    |> assign(
      selector_option_labels: selector_option_labels,
      sample_size: sample_size,
      pool_size: pool_size,
      pool_title: pool_title
    )
  end

  def save(socket, %Pool.CriteriaModel{} = entity, attrs) do
    changeset = Pool.CriteriaModel.changeset(entity, attrs)

    socket
    |> save(changeset)
    |> update_ui()
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
        %{assigns: %{assignment: assignment}} = socket
      ) do
    Advert.Public.handle_exclusion(assignment, current_items)
    excluded_user_ids = Advert.Public.list_excluded_user_ids(excluded_advert_ids)

    {
      :noreply,
      socket
      |> assign(excluded_user_ids: excluded_user_ids)
      |> update_ui()
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
        %{
          assigns: %{entity: criteria}
        } = socket
      )
      when criteria_field == :genders do
    attrs = %{criteria_field => selected_values}

    {:noreply, save(socket, criteria, attrs)}
  end

  @impl true
  def handle_event("change", %{"criteria_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    changeset = Pool.CriteriaModel.changeset(entity, attrs)

    {
      :noreply,
      socket
      |> save(changeset)
      |> assign(entity: Ecto.Changeset.apply_changes(changeset))
      |> update_ui()
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
              sample: "<span class=\"text-primary\">#{@sample_size}</span>",
              total: @pool_size,
              pool: @pool_title
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
            <%!-- This is responsible for rendering all selector childs, with their respective options. --%>
              <%= for field <- Map.keys(@selector_option_labels) do %>
                <div>
                  <Text.title4><%= inclusion_criterium_title(field) %></Text.title4>
                  <.spacing value="S" />
                  <.child name={field} fabric={@fabric} />
                </div>
              <% end %>

              <div>
              <%!-- This renders the min-max birth years number inputs --%>
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

            </div>
            <.spacing value="XL" />
          </div>
          <div class="xl:max-w-form">
            <Text.title3><%= dgettext("link-advert", "exclusion.title") %></Text.title3>
            <Text.body_medium><%= dgettext("link-advert", "exclusion.description") %></Text.body_medium>
            <.spacing value="M" />
            <Text.title4><%= dgettext("link-advert", "exclusion.select.label") %></Text.title4>
            <.spacing value="S" />

            <%= if Enum.count(@advert_labels) == 0 do %>
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
end
