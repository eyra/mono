defmodule Systems.Campaign.Public do
  @moduledoc """
  The Studies context.
  """
  import Ecto.Query, warn: false
  require Logger
  alias Core.Repo
  alias Core.Accounts
  alias Core.Accounts.User
  alias Core.Authorization

  alias Frameworks.GreenLight.Principal
  alias Frameworks.Signal
  alias Frameworks.Concept.Directable

  alias Systems.{
    Campaign,
    Promotion,
    Assignment,
    Alliance,
    Crew,
    Budget,
    Bookkeeping,
    Pool
  }

  def get!(id, preload \\ []) do
    from(c in Campaign.Model,
      where: c.id == ^id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def all(ids, preload \\ []) do
    from(c in Campaign.Model,
      where: c.id in ^ids,
      preload: ^preload
    )
    |> Repo.all()
  end

  def get_by_submission(submission, preload \\ [])

  def get_by_submission(%{id: id}, preload) do
    get_by_submission(id, preload)
  end

  def get_by_submission(submission_id, preload) do
    from(c in Campaign.Model,
      inner_join: cs in Campaign.SubmissionModel,
      on: cs.campaign_id == c.id,
      where: cs.submission_id == ^submission_id,
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_by_promotion(promotion, preload \\ [])

  def get_by_promotion(%{id: id}, preload) do
    get_by_promotion(id, preload)
  end

  def get_by_promotion(promotion_id, preload) do
    from(c in Campaign.Model,
      where: c.promotion_id == ^promotion_id,
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_by_promotable(promotable, preload \\ [])

  def get_by_promotable(%{id: id}, preload) do
    get_by_promotable(id, preload)
  end

  def get_by_promotable(promotable_id, preload) do
    from(c in Campaign.Model,
      where: c.promotable_assignment_id == ^promotable_id,
      preload: ^preload
    )
    |> Repo.one()
  end

  def list(opts \\ []) do
    exclude = Keyword.get(opts, :exclude, []) |> Enum.to_list()

    from(s in Campaign.Model,
      where: s.id not in ^exclude
    )
    |> Repo.all()

    # AUTH: Can be piped through auth filter.
  end

  def list_by_promotables(promotable_ids, preload) when is_list(promotable_ids) do
    from(c in Campaign.Model,
      where: c.promotable_assignment_id in ^promotable_ids,
      preload: ^preload
    )
    |> Repo.all()
  end

  def list_by_pools_and_submission_status(pools, submission_status, opts \\ [])
      when is_list(pools) and is_list(submission_status) do
    pool_ids = Enum.map(pools, & &1.id)

    preload = Keyword.get(opts, :preload, [])
    exclude = Keyword.get(opts, :exclude, []) |> Enum.to_list()

    from(c in Campaign.Model,
      inner_join: cs in Campaign.SubmissionModel,
      on: cs.campaign_id == c.id,
      inner_join: ps in Pool.SubmissionModel,
      on: ps.id == cs.submission_id,
      where: c.id not in ^exclude,
      where: ps.pool_id in ^pool_ids,
      where: ps.status in ^submission_status,
      preload: ^preload,
      order_by: [desc: ps.updated_at],
      select: c
    )
    |> Repo.all()
  end

  def list_by_budget(%Budget.Model{id: budget_id}, preload \\ []) do
    from(c in Campaign.Model,
      inner_join: a in Assignment.Model,
      on: c.promotable_assignment_id == a.id,
      where: a.budget_id == ^budget_id,
      preload: ^preload,
      order_by: [desc: c.updated_at],
      select: c
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of campaigns submitted at least once.
  """
  def list_submitted(pool, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])
    exclude = Keyword.get(opts, :exclude, []) |> Enum.to_list()

    from(c in Campaign.Model,
      inner_join: cs in Campaign.SubmissionModel,
      on: cs.campaign_id == c.id,
      inner_join: ps in Pool.SubmissionModel,
      on: ps.id == cs.submission_id,
      where: c.id not in ^exclude,
      where: ps.pool_id == ^pool.id,
      where: ps.status != :idle or not is_nil(ps.submitted_at),
      preload: ^preload,
      order_by: [desc: ps.updated_at],
      select: c
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of studies that are owned by the user.
  """
  def list_owned_campaigns(user, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    node_ids =
      Authorization.query_node_ids(
        role: :owner,
        principal: user
      )

    from(c in Campaign.Model,
      inner_join: cs in Campaign.SubmissionModel,
      on: cs.campaign_id == c.id,
      inner_join: ps in Pool.SubmissionModel,
      on: ps.id == cs.submission_id,
      where: c.auth_node_id in subquery(node_ids),
      order_by: [desc: ps.completed_at, desc: ps.updated_at],
      preload: ^preload,
      select: c
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of studies where the user is a subject.
  """
  def list_subject_campaigns(user, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    from(c in Campaign.Model,
      join: m in Crew.MemberModel,
      on: m.user_id == ^user.id,
      join: t in Crew.TaskModel,
      on: t.member_id == m.id,
      join: a in Assignment.Model,
      on: a.crew_id == m.crew_id,
      where: c.promotable_assignment_id == a.id and m.expired == false,
      preload: ^preload,
      order_by: [desc: t.updated_at],
      select: c
    )
    |> Repo.all()
  end

  def list_excluded_user_ids(campaign_ids) when is_list(campaign_ids) do
    from(u in User,
      join: m in Crew.MemberModel,
      on: m.user_id == u.id,
      join: a in Assignment.Model,
      on: a.crew_id == m.crew_id,
      join: c in Campaign.Model,
      on: c.promotable_assignment_id == a.id,
      where: c.id in ^campaign_ids,
      select: u.id
    )
    |> Repo.all()
  end

  def list_excluded_campaigns(campaigns, preload \\ []) when is_list(campaigns) do
    campaigns
    |> Enum.reduce([], fn campaign, acc ->
      acc ++ list_excluded_assignment_ids(campaign)
    end)
    |> list_by_promotables(preload)
  end

  defp list_excluded_assignment_ids(%Campaign.Model{promotable_assignment: %{excluded: excluded}})
       when is_list(excluded) do
    excluded
    |> Enum.map(& &1.id)
  end

  defp list_excluded_assignment_ids(_), do: []

  def list_owners(%Campaign.Model{} = campaign, preload \\ []) do
    owner_ids =
      campaign
      |> Authorization.list_principals()
      |> Enum.filter(fn %{roles: roles} -> MapSet.member?(roles, :owner) end)
      |> Enum.map(fn %{id: id} -> id end)

    from(u in User, where: u.id in ^owner_ids, preload: ^preload, order_by: u.id) |> Repo.all()
    # AUTH: needs to be marked save. Current user is normally not allowed to
    # access other users.
  end

  def assign_owners(campaign, users) do
    existing_owner_ids =
      Authorization.list_principals(campaign.auth_node_id)
      |> Enum.filter(fn %{roles: roles} -> MapSet.member?(roles, :owner) end)
      |> Enum.map(fn %{id: id} -> id end)
      |> Enum.into(MapSet.new())

    users
    |> Enum.filter(fn principal ->
      not MapSet.member?(existing_owner_ids, Principal.id(principal))
    end)
    |> Enum.each(&Authorization.assign_role(&1, campaign, :owner))

    new_owner_ids =
      users
      |> Enum.map(&Principal.id/1)
      |> Enum.into(MapSet.new())

    existing_owner_ids
    |> Enum.filter(fn id -> not MapSet.member?(new_owner_ids, id) end)
    |> Enum.each(&Authorization.remove_role!(%User{id: &1}, campaign, :owner))

    # AUTH: Does not modify entities, only auth. This needs checks to see if
    # the user is allowed to manage permissions? Could be implemented as part
    # of the authorization functions?
  end

  def open_spot_count(%{promotable_assignment: assignment}) do
    Assignment.Public.open_spot_count(assignment)
  end

  def open_spot_count(_campaign), do: 0

  def add_owner!(campaign, user) do
    :ok = Authorization.assign_role(user, campaign, :owner)
  end

  def remove_owner!(campaign, user) do
    Authorization.remove_role!(user, campaign, :owner)
  end

  def get_changeset(attrs \\ %{}) do
    %Campaign.Model{}
    |> Campaign.Model.changeset(attrs)
  end

  @doc """
  Creates a campaign.
  """
  def create(promotion, assignment, submissions, researcher, auth_node)
      when is_list(submissions) do
    with {:ok, campaign} <-
           %Campaign.Model{}
           |> Campaign.Model.changeset(%{})
           |> Ecto.Changeset.put_assoc(:promotion, promotion)
           |> Ecto.Changeset.put_assoc(:promotable_assignment, assignment)
           |> Ecto.Changeset.put_assoc(:submissions, submissions)
           |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
           |> Repo.insert() do
      :ok = Authorization.assign_role(researcher, campaign, :owner)
      Signal.Public.dispatch!({:campaign, :created}, %{campaign: campaign})
      {:ok, campaign}
    end
  end

  @doc """
  Updates a get_campaign.

  ## Examples

      iex> update(get_campaign, %{field: new_value})
      {:ok, %Campaign.Model{}}

      iex> update(get_campaign, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def update(%Ecto.Changeset{} = changeset) do
    changeset
    |> Repo.update()
  end

  def update(%Campaign.Model{} = campaign, attrs) do
    campaign
    |> Campaign.Model.changeset(attrs)
    |> update
  end

  def submission_updated(%Campaign.Model{
        promotable_assignment: assignment,
        submissions: [
          %{
            pool: %{id: pool_id, director: :student} = pool
          }
        ]
      }) do
    # FIXME: budget change after pool update should be handled in student submission form
    budget = Directable.director(pool).resolve_budget(pool_id, nil)
    Assignment.Public.update(assignment, budget)
  end

  def submission_updated(_), do: nil

  def delete(id) when is_number(id) do
    get!(id, Campaign.Model.preload_graph(:down))
    |> Campaign.Assembly.delete()
  end

  def change(%Campaign.Model{} = campaign, attrs \\ %{}) do
    Campaign.Model.changeset(campaign, attrs)
  end

  def copy(
        %Campaign.Model{} = campaign,
        %Promotion.Model{} = promotion,
        %Assignment.Model{} = assignment,
        submissions,
        auth_node
      )
      when is_list(submissions) do
    %Campaign.Model{}
    |> Campaign.Model.changeset(
      campaign
      |> Map.delete(:updated_at)
      |> Map.from_struct()
    )
    |> Ecto.Changeset.put_assoc(:promotion, promotion)
    |> Ecto.Changeset.put_assoc(:promotable_assignment, assignment)
    |> Ecto.Changeset.put_assoc(:submissions, submissions)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end

  def copy(authors, campaign) when is_list(authors) do
    authors |> Enum.map(&copy(&1, campaign))
  end

  def copy(%Campaign.AuthorModel{user: user} = author, campaign) do
    Campaign.AuthorModel.changeset(Map.from_struct(author))
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:campaign, campaign)
    |> Repo.insert!()
  end

  def add_author(%Campaign.Model{} = campaign, %User{} = researcher) do
    researcher
    |> Campaign.AuthorModel.from_user()
    |> Campaign.AuthorModel.changeset()
    |> Ecto.Changeset.put_assoc(:campaign, campaign)
    |> Ecto.Changeset.put_assoc(:user, researcher)
    |> Repo.insert()
  end

  def original_author(campaign) do
    campaign
    |> list_authors()
    |> List.first()
  end

  def list_authors(%{id: campaign_id}) do
    from(
      a in Campaign.AuthorModel,
      where: a.campaign_id == ^campaign_id,
      order_by: {:asc, :inserted_at},
      preload: [user: [:profile]]
    )
    |> Repo.all()
  end

  def list_tools(%Campaign.Model{} = campaign) do
    from(s in Alliance.ToolModel, where: s.campaign_id == ^campaign.id)
    |> Repo.all()
  end

  def list_tools(%Campaign.Model{} = campaign, schema) do
    from(s in schema, where: s.campaign_id == ^campaign.id)
    |> Repo.all()
  end

  def completed?(%Campaign.Model{} = campaign) do
    campaign
    |> Campaign.Model.flatten()
    |> completed?()
  end

  def completed?(%{submission: submission}) do
    Pool.SubmissionModel.completed?(submission)
  end

  def ready?(id) do
    # temp solution for checking if campaign is ready to submit,
    # TBD: replace with signal driven db field

    preload = Campaign.Model.preload_graph(:down)

    %{
      promotion: promotion,
      promotable_assignment: assignment
    } = Campaign.Public.get!(id, preload)

    Promotion.Public.ready?(promotion) &&
      Assignment.Public.ready?(assignment)
  end

  def assign_coordinators(campaign) do
    from(u in User, where: u.coordinator == true)
    |> Repo.all()
    |> Enum.each(fn user ->
      Authorization.assign_role(user, campaign, :coordinator)
    end)
  end

  def update_coordinator_role(user, value) do
    from(c in Campaign.Model)
    |> Repo.all()
    |> Enum.each(fn campaign ->
      update_coordinator_role(campaign, user, value)
    end)
  end

  defp update_coordinator_role(campaign, user, value) do
    if value do
      Authorization.assign_role(user, campaign, :coordinator)
    else
      Authorization.remove_role!(user, campaign, :coordinator)
    end
  end

  def handle_exclusion(%Assignment.Model{} = assignment, items) when is_list(items) do
    items |> Enum.each(&handle_exclusion(assignment, &1))
    Signal.Public.dispatch!({:assignment, :updated}, %{assignment: assignment})
  end

  def handle_exclusion(%Assignment.Model{} = assignment, %{id: id, active: active} = _item) do
    handle_exclusion(assignment, Campaign.Public.get!(id, [:promotable_assignment]), active)
  end

  defp handle_exclusion(
         %Assignment.Model{} = assignment,
         %Campaign.Model{promotable_assignment: other},
         active
       ) do
    handle_exclusion(assignment, other, active)
  end

  defp handle_exclusion(%Assignment.Model{} = assignment, %Assignment.Model{} = other, true) do
    Assignment.Public.exclude(assignment, other)
  end

  defp handle_exclusion(%Assignment.Model{} = assignment, %Assignment.Model{} = other, false) do
    Assignment.Public.include(assignment, other)
  end

  def reward_value(%Assignment.Model{} = assignment) do
    %{submission: %{reward_value: reward_value}} =
      assignment
      |> Campaign.Public.get_by_promotable([:submissions])
      |> Campaign.Model.flatten()

    reward_value
  end

  def validate_open(%Assignment.Model{} = assignment, user) do
    assignment
    |> get_by_promotable(Campaign.Model.preload_graph(:down))
    |> validate_open(user)
  end

  def validate_open(%Campaign.Model{} = campaign, user) do
    campaign = Campaign.Model.flatten(campaign)

    with :ok <- validate_exclusion(campaign, user),
         :ok <- validate_eligitable(campaign, user),
         :ok <- validate_open_spots(campaign),
         :ok <- validate_released(campaign),
         :ok <- validate_funded(campaign) do
      :ok
    else
      error -> error
    end
  end

  defp validate_exclusion(%{promotable: assignment}, user) do
    if Assignment.Public.excluded?(assignment, user) do
      {:error, :excluded}
    else
      :ok
    end
  end

  defp validate_eligitable(%{submission: %{criteria: criteria}}, user) do
    user_features = Accounts.get_features(user)

    if Pool.CriteriaModel.eligitable?(criteria, user_features) do
      :ok
    else
      {:error, :not_eligitable}
    end
  end

  defp validate_open_spots(%{promotable: assignment}) do
    if Assignment.Public.has_open_spots?(assignment) do
      :ok
    else
      {:error, :no_open_spots}
    end
  end

  defp validate_released(%{submission: submission}) do
    if Pool.Public.published_status(submission) == :released do
      :ok
    else
      {:error, :not_released}
    end
  end

  defp validate_funded(%{
         promotable: %{budget: %{currency: %{type: :legal}} = budget},
         submission: %{reward_value: reward_value}
       }) do
    if Budget.Model.amount_available(budget) > reward_value do
      :ok
    else
      {:error, :not_funded}
    end
  end

  defp validate_funded(%{promotable: %{budget: %{currency: %{type: _}}}}), do: :ok

  @doc """
    Marks expired tasks in online campaigns based on updated_at and estimated duration.
    If force is true (for debug purposes only), all pending tasks will be marked as expired.
  """
  def mark_expired_debug(force \\ false) do
    submission_ids =
      from(s in Pool.SubmissionModel, where: s.status == :accepted)
      |> Repo.all()
      |> Enum.map(& &1.id)

    preload = Campaign.Model.preload_graph(:down)

    from(c in Campaign.Model,
      inner_join: cs in Campaign.SubmissionModel,
      on: cs.campaign_id == c.id,
      where: cs.submission_id in ^submission_ids,
      preload: ^preload
    )
    |> Repo.all()
    |> Enum.each(&mark_expired_debug(&1, force))
  end

  @doc """
    Marks expired tasks in given campaign
  """
  def mark_expired_debug(%{promotable_assignment: assignment}, force) do
    Assignment.Public.mark_expired_debug(assignment, force)
  end

  def payout_participant(%Assignment.Model{} = assignment, %User{} = user) do
    Assignment.Public.payout_participant(assignment, user)
  end

  def rewarded_amount(%Assignment.Model{} = assignment, %User{} = user) do
    Assignment.Public.rewarded_amount(assignment, user)
  end

  def reward_amount(%Assignment.Model{id: assignment_id}) do
    from(c in Campaign.Model,
      inner_join: cs in Campaign.SubmissionModel,
      on: cs.campaign_id == c.id,
      inner_join: s in Pool.SubmissionModel,
      on: s.id == cs.submission_id,
      inner_join: ec in Pool.CriteriaModel,
      on: ec.submission_id == s.id,
      where: c.promotable_assignment_id == ^assignment_id,
      select: s.reward_value
    )
    |> Repo.one!()
  end

  @doc """
    Synchronizes accepted student tasks with bookkeeping.
  """
  def sync_student_credits() do
    from(assignment in Assignment.Model,
      inner_join: task in Crew.TaskModel,
      on: task.crew_id == assignment.crew_id,
      inner_join: node in Authorization.Node,
      on: node.id == task.auth_node_id,
      inner_join: role in Authorization.RoleAssignment,
      on: role.node_id == node.id,
      inner_join: user in User,
      on: user.id == role.principal_id,
      inner_join: budget in Budget.Model,
      on: budget.id == assignment.budget_id,
      where: role.role == :owner,
      where: task.status == :accepted,
      where: user.student == true,
      preload: [budget: [:fund, :reserve]],
      select: %{assignment: assignment, user: user}
    )
    |> Repo.all()
    |> Enum.each(&payout_participant(&1.assignment, &1.user))
  end

  def user_has_currency?(%User{} = user, currency) do
    query_user_pools_by_currency(user, currency)
    |> Repo.exists?()
  end

  def get_user_pools_by_currency(%User{} = user, currency) do
    query_user_pools_by_currency(user, currency)
    |> Repo.all()
  end

  def query_user_pools_by_currency(%User{id: user_id}, currency) do
    from(p in Pool.Model,
      inner_join: pp in Pool.ParticipantModel,
      on: pp.pool_id == p.id,
      inner_join: u in User,
      on: pp.user_id == u.id,
      inner_join: bc in Budget.CurrencyModel,
      on: bc.id == p.currency_id,
      where: bc.name == ^currency and u.id == ^user_id,
      select: p
    )
  end

  def import_student_reward(student_id, amount, session_key, currency) when is_binary(currency) do
    idempotence_key = import_idempotence_key(session_key, student_id)
    student = Core.Accounts.get_user!(student_id)

    if user_has_currency?(student, currency) do
      from = ["fund", currency]
      to = ["wallet", currency, student_id]

      journal_message =
        "Student #{student_id} earned #{amount} by import during session '#{session_key}'"

      import_student_reward(from, to, amount, idempotence_key, journal_message)
    else
      Logger.warn(
        "Import reward failed, user has no access to currency #{currency}: amount=#{amount} idempotence_key=#{idempotence_key}"
      )
    end
  end

  defp import_student_reward(from, to, amount, idempotence_key, journal_message) do
    lines = [
      %{account: from, debit: amount},
      %{account: to, credit: amount}
    ]

    payment = %{
      idempotence_key: idempotence_key,
      journal_message: journal_message,
      lines: lines
    }

    if Bookkeeping.Public.exists?(idempotence_key) do
      Logger.warn("Import reward skipped: amount=#{amount} idempotence_key=#{idempotence_key}")
    else
      result = Bookkeeping.Public.enter(payment)

      with {:error, error} <- result do
        Logger.warn("Import reward failed: idempotence_key=#{idempotence_key}, error=#{error}")
      end
    end
  end

  def import_student_reward_exists?(student_id, session_key) do
    idempotence_key = import_idempotence_key(session_key, student_id)
    Bookkeeping.Public.exists?(idempotence_key)
  end

  defp import_idempotence_key(session_key, user_id) do
    "import=#{session_key},user=#{user_id}"
  end
end
