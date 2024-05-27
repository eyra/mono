defmodule Systems.Advert.SubmissionView do
  use CoreWeb.LiveForm

  alias Core.Enums.{Genders, DominantHands, NativeLanguages}
  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text
  alias Frameworks.Concept.Directable

  alias Systems.{
    Advert,
    Assignment,
    Pool
  }

  @enums_mapping %{
    genders: Genders,
    dominant_hands: DominantHands,
    native_languages: NativeLanguages
  }

  # Update adverts only
  @impl true
  def update(
        _,
        %{assigns: %{entity: _}} = socket
      ) do
    {
      :ok,
      socket
      |> update_adverts()
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
      |> update_adverts()
      |> update_ui()
    }
  end

  defp compose_inclusion_selectors(%{assigns: %{inclusion_labels: inclusion_labels}} = socket) do
    inclusion_labels
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
  def compose(key, %{inclusion_labels: inclusion_labels}) do
    items = Map.get(inclusion_labels, key)

    %{
      module: Selector,
      params: %{
        grid_options: "flex flex-col flex-wrap gap-y-3",
        items: items,
        type: :checkbox
      }
    }
  end

  defp update_adverts(%{assigns: %{user: user, submission: submission}} = socket) do
    %{id: advert_id, assignment: %{excluded: excluded_assignments} = assignment} =
      Advert.Public.get_by_submission(submission, assignment: [:excluded])

    excluded_assignment_ids =
      excluded_assignments
      |> Enum.map(& &1.id)

    advert_labels =
      Advert.Public.list_owned_adverts(user, preload: [:promotion, :assignment])
      |> Enum.filter(&(&1.id != advert_id))
      |> Enum.map(&to_label(&1, excluded_assignment_ids))

    excluded_user_ids = Assignment.Public.list_user_ids(excluded_assignment_ids)

    socket
    |> assign(assignment: assignment)
    |> assign(advert_labels: advert_labels)
    |> assign(excluded_user_ids: excluded_user_ids)
  end

  defp to_label(
         %Advert.Model{
           id: id,
           promotion: %{title: title},
           assignment_id: assignment_id
         },
         excluded_assignment_ids
       ) do
    excluded = excluded_assignment_ids |> Enum.member?(assignment_id)
    %{id: id, value: title, active: excluded}
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
             submission: %{pool: %{name: pool_name, participants: participants} = pool},
             excluded_user_ids: excluded_user_ids
           }
         } = socket,
         criteria
       ) do
    inclusion_labels =
      Directable.director(pool).inclusion_criteria()
      |> Enum.map(&get_inclusion_labels(&1, criteria))
      |> Map.new()

    included_user_ids = Enum.map(participants, & &1.id)
    pool_size = Enum.count(included_user_ids)
    pool_title = Pool.Model.title(pool_name)

    sample_size =
      Pool.Public.count_eligitable_users(criteria, included_user_ids, excluded_user_ids)

    socket
    |> assign(
      inclusion_labels: inclusion_labels,
      sample_size: sample_size,
      pool_size: pool_size,
      pool_title: pool_title
    )
  end

  defp get_inclusion_labels(field, %Pool.CriteriaModel{} = criteria) when is_atom(field) do
    case Map.get(@enums_mapping, field) do
      nil ->
        nil

      enum_module ->
        values = Map.get(criteria, field)
        {field, enum_module.labels(values)}
    end
  end

  # Saving
  def save(socket, %Pool.CriteriaModel{} = entity, attrs) do
    changeset = Pool.CriteriaModel.changeset(entity, attrs)

    socket
    |> save(changeset)
    |> update_ui()
  end

  defp inclusion_title(:genders), do: dgettext("eyra-account", "features.gender.title")

  defp inclusion_title(:native_languages),
    do: dgettext("eyra-account", "features.nativelanguage.title")

  defp inclusion_title(:dominant_hands),
    do: dgettext("eyra-account", "features.dominanthand.title")

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
    socket =
      save_closure(socket, fn socket ->
        Advert.Public.handle_exclusion(assignment, current_items)

        excluded_user_ids = Advert.Public.list_excluded_user_ids(excluded_advert_ids)

        socket
        |> assign(excluded_user_ids: excluded_user_ids)
        |> update_ui()
        |> flash_persister_saved()
      end)

    {:noreply, socket}
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
              <%= for field <- Map.keys(@inclusion_labels) do %>
              <div>
                <Text.title4><%= inclusion_title(field) %></Text.title4>
                <.spacing value="S" />
                <.child name={field} fabric={@fabric} />
              </div>
              <% end %>
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
