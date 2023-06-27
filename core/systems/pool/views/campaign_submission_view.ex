defmodule Systems.Pool.CampaignSubmissionView do
  use CoreWeb.LiveForm

  alias Core.Enums.{Genders, DominantHands, NativeLanguages}
  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text

  alias Systems.{
    Campaign,
    Assignment,
    Pool
  }

  @enums_mapping %{
    genders: Genders,
    dominant_hands: DominantHands,
    native_languages: NativeLanguages
  }

  # Handle Selector Update
  @impl true
  def update(
        %{
          selector_id: :exclude_campaigns,
          active_item_ids: excluded_campaign_ids,
          current_items: current_items
        },
        %{assigns: %{assignment: assignment}} = socket
      ) do
    socket =
      socket
      |> save_closure(fn socket ->
        Campaign.Public.handle_exclusion(assignment, current_items)

        excluded_user_ids = Campaign.Public.list_excluded_user_ids(excluded_campaign_ids)

        socket
        |> assign(excluded_user_ids: excluded_user_ids)
        |> update_ui()
        |> flash_persister_saved()
      end)

    {
      :ok,
      socket
    }
  end

  @impl true
  def update(
        %{active_item_ids: active_item_ids, selector_id: selector_id},
        %{assigns: %{entity: criteria}} = socket
      ) do
    {
      :ok,
      socket
      |> save(criteria, %{selector_id => active_item_ids})
    }
  end

  @impl true
  def update(
        %{active_item_id: active_item_id, selector_id: selector_id},
        %{assigns: %{entity: criteria}} = socket
      ) do
    {
      :ok,
      socket
      |> save(criteria, %{selector_id => active_item_id})
    }
  end

  # Update campaigns only
  @impl true
  def update(
        _,
        %{assigns: %{id: _}} = socket
      ) do
    {
      :ok,
      socket
      |> update_campaigns()
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
      |> update_campaigns()
      |> update_ui()
    }
  end

  defp update_campaigns(%{assigns: %{user: user, submission: submission}} = socket) do
    %{id: campaign_id, promotable_assignment: %{excluded: excluded_assignments} = assignment} =
      Campaign.Public.get_by_submission(submission, promotable_assignment: [:excluded])

    excluded_assignment_ids =
      excluded_assignments
      |> Enum.map(& &1.id)

    campaign_labels =
      Campaign.Public.list_owned_campaigns(user, preload: [:promotion, :promotable_assignment])
      |> Enum.filter(&(&1.id != campaign_id))
      |> Enum.map(&to_label(&1, excluded_assignment_ids))

    excluded_user_ids = Assignment.Public.list_user_ids(excluded_assignment_ids)

    socket
    |> assign(assignment: assignment)
    |> assign(campaign_labels: campaign_labels)
    |> assign(excluded_user_ids: excluded_user_ids)
  end

  defp to_label(
         %Campaign.Model{
           id: id,
           promotion: %{title: title},
           promotable_assignment_id: assignment_id
         },
         excluded_assignment_ids
       ) do
    excluded = excluded_assignment_ids |> Enum.member?(assignment_id)
    %{id: id, value: title, active: excluded}
  end

  defp update_ui(%{assigns: %{entity: criteria}} = socket) do
    update_ui(socket, criteria)
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
      Systems.Director.get(pool).inclusion_criteria()
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

  # data(user, :any)
  # data(entity, :any)
  # data(inclusion_labels, :any, default: nil)
  # data(campaign_labels, :map)
  # data(excluded_user_ids, :list)
  # data(sample_size, :integer)
  # data(pool_size, :integer)
  # data(pool_title, :string)
  # data(changeset, :any)

  attr(:entity, :map, required: true)
  attr(:user, :map, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2 margin=""><%= dgettext("link-campaign", "submission.criteria.title") %></Text.title2>
        <.spacing value="M" />
        <Text.sub_head color="text-grey1">
          <%= raw(
            dgettext("link-campaign", "submission.criteria.status",
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
                <.live_component
                  module={Selector}
                  id={field}
                  items={Map.get(@inclusion_labels, field)}
                  type={:checkbox}
                  parent={%{type: __MODULE__, id: @id}}
                />
              </div>
              <% end %>
            </div>
            <.spacing value="XL" />
          </div>
          <div class="xl:max-w-form">
            <Text.title3><%= dgettext("link-campaign", "exclusion.title") %></Text.title3>
            <Text.body_medium><%= dgettext("link-campaign", "exclusion.description") %></Text.body_medium>
            <.spacing value="M" />
            <Text.title4><%= dgettext("link-campaign", "exclusion.select.label") %></Text.title4>
            <.spacing value="S" />

            <%= if Enum.count(@campaign_labels) == 0 do %>
              <Text.title6 color="text-grey2" margin="m-0"><%= dgettext("link-campaign", "no.previous.campaigns.available") %></Text.title6>
            <% else %>
              <.live_component
                module={Selector}
                grid_options="flex flex-col flex-wrap gap-y-3"
                id={:exclude_campaigns}
                items={@campaign_labels}
                type={:checkbox}
                parent={%{type: __MODULE__, id: @id}}
              />
            <% end %>
            <.spacing value="XL" />
          </div>
        </div>
      </Area.content>
    </div>
    """
  end
end
