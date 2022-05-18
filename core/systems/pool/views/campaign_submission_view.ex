defmodule Systems.Pool.CampaignSubmissionView do
  use CoreWeb.LiveForm

  alias Core.Pools
  alias Core.Enums.{Genders, DominantHands, NativeLanguages}
  alias Frameworks.Pixel.Selector.Selector
  alias Frameworks.Pixel.Text.{Title2, Title3, Title4, Title6, BodyMedium, SubHead}

  alias Systems.{
    Campaign,
    Assignment
  }

  alias Core.Pools.{Criteria}

  prop(props, :any, required: true)

  data(entity, :any)
  data(gender_labels, :any)
  data(dominanthand_labels, :any)
  data(nativelanguage_labels, :any)
  data(campaign_labels, :map)
  data(excluded_user_ids, :list)

  data(sample_size, :integer)
  data(pool_size, :integer)

  data(changeset, :any)
  data(focus, :any, default: "")

  # Handle Selector Update
  def update(
        %{
          selector_id: :exclude_campaigns,
          active_item_ids: excluded_campaign_ids,
          current_items: current_items
        },
        %{assigns: %{assignment: assignment}} = socket
      ) do
    handle_exclusion(assignment, current_items)

    excluded_user_ids = Campaign.Context.list_excluded_user_ids(excluded_campaign_ids)

    {
      :ok,
      socket
      |> assign(excluded_user_ids: excluded_user_ids)
      |> update_ui()
    }
  end

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

  # Initial update
  def update(
        %{
          id: id,
          props: %{
            entity: %{criteria: criteria, promotion_id: promotion_id} = submission,
            user: user
          }
        },
        socket
      ) do
    %{promotable_assignment: %{excluded: excluded_assignments} = assignment} =
      Campaign.Context.get_by_promotion(promotion_id, promotable_assignment: [:excluded])

    excluded_assignment_ids =
      excluded_assignments
      |> Enum.map(& &1.id)

    campaign_labels =
      Campaign.Context.list_owned_campaigns(user, preload: [:promotion, :promotable_assignment])
      |> Enum.filter(&(&1.promotion_id != promotion_id))
      |> Enum.map(&to_label(&1, excluded_assignment_ids))

    excluded_user_ids = Assignment.Context.list_user_ids(excluded_assignment_ids)

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(submission: submission)
      |> assign(assignment: assignment)
      |> assign(entity: criteria)
      |> assign(campaign_labels: campaign_labels)
      |> assign(excluded_user_ids: excluded_user_ids)
      |> update_ui()
    }
  end

  defp handle_exclusion(assignment, items) when is_list(items) do
    items |> Enum.each(&handle_exclusion(assignment, &1))
  end

  defp handle_exclusion(assignment, %{id: id, active: active} = _item) do
    handle_exclusion(assignment, Campaign.Context.get!(id, [:promotable_assignment]), active)
  end

  defp handle_exclusion(assignment, %Campaign.Model{promotable_assignment: other}, active) do
    handle_exclusion(assignment, other, active)
  end

  defp handle_exclusion(assignment, %Assignment.Model{} = other, true) do
    Assignment.Context.exclude(assignment, other)
  end

  defp handle_exclusion(assignment, %Assignment.Model{} = other, false) do
    Assignment.Context.include(assignment, other)
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

  defp update_ui(%{assigns: %{excluded_user_ids: excluded_user_ids}} = socket, criteria) do
    gender_labels = Genders.labels(criteria.genders)
    dominanthand_labels = DominantHands.labels(criteria.dominant_hands)
    nativelanguage_labels = NativeLanguages.labels(criteria.native_languages)

    pool_size = Pools.count_eligitable_users(criteria.study_program_codes)
    sample_size = Pools.count_eligitable_users(criteria, excluded_user_ids)

    socket
    |> assign(
      gender_labels: gender_labels,
      dominanthand_labels: dominanthand_labels,
      nativelanguage_labels: nativelanguage_labels,
      sample_size: sample_size,
      pool_size: pool_size
    )
  end

  # Saving
  def save(socket, %Criteria{} = entity, attrs) do
    changeset = Criteria.changeset(entity, attrs)

    socket
    |> save(changeset)
    |> update_ui()
  end

  def render(assigns) do
    ~F"""
      <ContentArea>
        <MarginY id={:page_top} />
        <Title2 margin="">{dgettext("link-campaign", "submission.criteria.title")}</Title2>
        <Spacing value="M" />
        <SubHead color="text-grey1">
          {raw(dgettext("link-campaign", "submission.criteria.status",
            sample: "<span class=\"text-primary\">#{@sample_size}</span>",
            total: @pool_size
          ))}
        </SubHead>
        <Spacing value="M" />
        <div class="flex flex-col-reverse xl:flex-row gap-8 xl:gap-14">
          <div class="xl:max-w-form">
            <Title3>{dgettext("eyra-account", "features.title")}</Title3>
            <BodyMedium>{dgettext("eyra-account", "features.content.description")}</BodyMedium>
            <Spacing value="M" />

            <Title4>{dgettext("eyra-account", "features.gender.title")}</Title4>
            <Spacing value="S" />
            <Selector id={:genders} items={@gender_labels} type={:checkbox} parent={%{type: __MODULE__, id: @id}} />
            <Spacing value="XL" />

            <Title4>{dgettext("eyra-account", "features.nativelanguage.title")}</Title4>
            <Spacing value="S" />
            <Selector id={:native_languages} items={@nativelanguage_labels} type={:checkbox} parent={%{type: __MODULE__, id: @id}} />
            <Spacing value="XL" />

            <Title4>{dgettext("eyra-account", "features.dominanthand.title")}</Title4>
            <Spacing value="S" />
            <Selector id={:dominant_hands} items={@dominanthand_labels} type={:checkbox} parent={%{type: __MODULE__, id: @id}} />
          </div>
          <div class="xl:max-w-form">
            <Title3>{dgettext("link-campaign", "exclusion.title")}</Title3>
            <BodyMedium>{dgettext("link-campaign", "exclusion.description")}</BodyMedium>
            <Spacing value="M" />
            <Title4>{dgettext("link-campaign", "exclusion.select.label")}</Title4>
            <Spacing value="S" />
            <div :if={Enum.count(@campaign_labels) == 0}>
              <Title6 color="text-grey2" margin="m-0">{dgettext("link-campaign", "no.previous.campaigns.available")}</Title6>
            </div>
            <div :if={Enum.count(@campaign_labels) > 0}>
              <Selector
                grid_options="flex flex-col flex-wrap gap-y-3"
                id={:exclude_campaigns}
                items={@campaign_labels}
                type={:checkbox}
                parent={%{type: __MODULE__, id: @id}}
               />
            </div>
            <Spacing value="XL" />
          </div>
        </div>
      </ContentArea>
    """
  end
end
