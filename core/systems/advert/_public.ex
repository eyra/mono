defmodule Systems.Advert.Public do
  use Core, :public

  @moduledoc """
  The Studies context.
  """
  import Ecto.Query, warn: false
  import Systems.Advert.Queries

  require Logger
  alias Core.Repo
  alias Systems.Account.User

  alias Frameworks.GreenLight.Principal
  alias Frameworks.Signal
  alias Frameworks.Concept.Directable

  alias Systems.Account

  alias Systems.Advert
  alias Systems.Promotion
  alias Systems.Assignment
  alias Systems.Alliance
  alias Systems.Crew
  alias Systems.Budget
  alias Systems.Bookkeeping
  alias Systems.Pool

  def get!(id, preload \\ []) do
    from(c in Advert.Model,
      where: c.id == ^id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def all(ids, preload \\ []) do
    from(c in Advert.Model,
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
    from(c in Advert.Model,
      where: c.submission_id == ^submission_id,
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_by_promotion(promotion, preload \\ [])

  def get_by_promotion(%{id: id}, preload) do
    get_by_promotion(id, preload)
  end

  def get_by_promotion(promotion_id, preload) do
    from(c in Advert.Model,
      where: c.promotion_id == ^promotion_id,
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_by_assignment(assignment, preload \\ [])

  def get_by_assignment(%{id: id}, preload) do
    get_by_assignment(id, preload)
  end

  def get_by_assignment(assignment_id, preload) do
    from(c in Advert.Model,
      where: c.assignment_id == ^assignment_id,
      preload: ^preload
    )
    |> Repo.one()
  end

  def list(opts \\ []) do
    exclude = Keyword.get(opts, :exclude, []) |> Enum.to_list()

    from(s in Advert.Model,
      where: s.id not in ^exclude
    )
    |> Repo.all()

    # AUTH: Can be piped through auth filter.
  end

  def list_by_assignments(assignment_ids, preload) when is_list(assignment_ids) do
    from(c in Advert.Model,
      where: c.assignment_id in ^assignment_ids,
      preload: ^preload
    )
    |> Repo.all()
  end

  def list_by_pools_and_submission_status(pools, submission_status, opts \\ [])
      when is_list(pools) and is_list(submission_status) do
    pool_ids = Enum.map(pools, & &1.id)

    preload = Keyword.get(opts, :preload, [])
    exclude = Keyword.get(opts, :exclude, []) |> Enum.to_list()

    from(c in Advert.Model,
      inner_join: ps in Pool.SubmissionModel,
      on: ps.id == c.submission_id,
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
    from(c in Advert.Model,
      inner_join: a in Assignment.Model,
      on: c.assignment_id == a.id,
      where: a.budget_id == ^budget_id,
      preload: ^preload,
      order_by: [desc: c.updated_at],
      select: c
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of adverts submitted at least once.
  """
  def list_submitted(pool, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])
    exclude = Keyword.get(opts, :exclude, []) |> Enum.to_list()

    from(c in Advert.Model,
      inner_join: ps in Pool.SubmissionModel,
      on: ps.id == c.submission_id,
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
  Returns the list of adverts where the user has the specified role
  """
  def list_by_participant(user, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    advert_query(user, :participant)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_by_status(status, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    advert_query(status)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_excluded_user_ids(advert_ids) when is_list(advert_ids) do
    from(u in User,
      join: m in Crew.MemberModel,
      on: m.user_id == u.id,
      join: a in Assignment.Model,
      on: a.crew_id == m.crew_id,
      join: c in Advert.Model,
      on: c.assignment_id == a.id,
      where: c.id in ^advert_ids,
      select: u.id
    )
    |> Repo.all()
  end

  def list_excluded_adverts(adverts, preload \\ []) when is_list(adverts) do
    adverts
    |> Enum.reduce([], fn advert, acc ->
      acc ++ list_excluded_assignment_ids(advert)
    end)
    |> list_by_assignments(preload)
  end

  defp list_excluded_assignment_ids(%Advert.Model{assignment: %{excluded: excluded}})
       when is_list(excluded) do
    excluded
    |> Enum.map(& &1.id)
  end

  defp list_excluded_assignment_ids(_), do: []

  def list_owners(%Advert.Model{} = advert, preload \\ []) do
    owner_ids =
      advert
      |> auth_module().list_principals()
      |> Enum.filter(fn %{roles: roles} -> MapSet.member?(roles, :owner) end)
      |> Enum.map(fn %{id: id} -> id end)

    from(u in User, where: u.id in ^owner_ids, preload: ^preload, order_by: u.id) |> Repo.all()
    # AUTH: needs to be marked save. Current user is normally not allowed to
    # access other users.
  end

  def assign_owners(advert, users) do
    existing_owner_ids =
      auth_module().list_principals(advert.auth_node_id)
      |> Enum.filter(fn %{roles: roles} -> MapSet.member?(roles, :owner) end)
      |> Enum.map(fn %{id: id} -> id end)
      |> Enum.into(MapSet.new())

    users
    |> Enum.filter(fn principal ->
      not MapSet.member?(existing_owner_ids, Principal.id(principal))
    end)
    |> Enum.each(&auth_module().assign_role(&1, advert, :owner))

    new_owner_ids =
      users
      |> Enum.map(&Principal.id/1)
      |> Enum.into(MapSet.new())

    existing_owner_ids
    |> Enum.filter(fn id -> not MapSet.member?(new_owner_ids, id) end)
    |> Enum.each(&auth_module().remove_role!(%User{id: &1}, advert, :owner))

    # AUTH: Does not modify entities, only auth. This needs checks to see if
    # the user is allowed to manage permissions? Could be implemented as part
    # of the authorization functions?
  end

  def open_spot_count(%{assignment: assignment}) do
    Assignment.Public.open_spot_count(assignment)
  end

  def open_spot_count(_advert), do: 0

  def get_changeset(attrs \\ %{}) do
    %Advert.Model{}
    |> Advert.Model.changeset(attrs)
  end

  @doc """
  Creates a advert.
  """
  def create(promotion, assignment, submission, researcher, auth_node) do
    with {:ok, advert} <-
           %Advert.Model{}
           |> Advert.Model.changeset(%{})
           |> Ecto.Changeset.put_assoc(:promotion, promotion)
           |> Ecto.Changeset.put_assoc(:assignment, assignment)
           |> Ecto.Changeset.put_assoc(:submission, submission)
           |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
           |> Repo.insert() do
      :ok = auth_module().assign_role(researcher, advert, :owner)
      Signal.Public.dispatch!({:advert, :created}, %{advert: advert})
      {:ok, advert}
    end
  end

  @doc """
  Updates a get_advert.

  ## Examples

      iex> update(get_advert, %{field: new_value})
      {:ok, %Advert.Model{}}

      iex> update(get_advert, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def update(%Ecto.Changeset{} = changeset) do
    changeset
    |> Repo.update()
  end

  def update(%Advert.Model{} = advert, attrs) do
    advert
    |> Advert.Model.changeset(attrs)
    |> update
  end

  def submission_updated(%Advert.Model{
        assignment: assignment,
        submission: %{
          pool: %{id: pool_id, director: :student} = pool
        }
      }) do
    # FIXME: budget change after pool update should be handled in student submission form
    budget = Directable.director(pool).resolve_budget(pool_id, nil)
    Assignment.Public.update_budget(assignment, budget)
  end

  def submission_updated(_), do: nil

  def delete(id) when is_number(id) do
    get!(id, Advert.Model.preload_graph(:down))
    |> Advert.Assembly.delete()
  end

  def change(%Advert.Model{} = advert, attrs \\ %{}) do
    Advert.Model.changeset(advert, attrs)
  end

  def copy(
        %Advert.Model{} = advert,
        %Promotion.Model{} = promotion,
        %Assignment.Model{} = assignment,
        %Pool.SubmissionModel{} = submission,
        auth_node
      ) do
    %Advert.Model{}
    |> Advert.Model.changeset(
      advert
      |> Map.delete(:updated_at)
      |> Map.from_struct()
    )
    |> Ecto.Changeset.put_assoc(:promotion, promotion)
    |> Ecto.Changeset.put_assoc(:assignment, assignment)
    |> Ecto.Changeset.put_assoc(:submission, submission)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end

  def list_tools(%Advert.Model{} = advert) do
    from(s in Alliance.ToolModel, where: s.advert_id == ^advert.id)
    |> Repo.all()
  end

  def list_tools(%Advert.Model{} = advert, schema) do
    from(s in schema, where: s.advert_id == ^advert.id)
    |> Repo.all()
  end

  def completed?(%Advert.Model{} = advert) do
    advert
    |> completed?()
  end

  def completed?(%{submission: submission}) do
    Pool.SubmissionModel.completed?(submission)
  end

  def ready?(id) do
    # temp solution for checking if advert is ready to submit,
    # TBD: replace with signal driven db field

    preload = Advert.Model.preload_graph(:down)

    %{
      promotion: promotion,
      assignment: assignment
    } = Advert.Public.get!(id, preload)

    Promotion.Public.ready?(promotion) &&
      Assignment.Public.ready?(assignment)
  end

  def handle_exclusion(%Assignment.Model{} = assignment, items) when is_list(items) do
    items |> Enum.each(&handle_exclusion(assignment, &1))
    Signal.Public.dispatch!({:assignment, :updated}, %{assignment: assignment})
  end

  def handle_exclusion(%Assignment.Model{} = assignment, %{id: id, active: active} = _item) do
    handle_exclusion(assignment, Advert.Public.get!(id, [:assignment]), active)
  end

  defp handle_exclusion(
         %Assignment.Model{} = assignment,
         %Advert.Model{assignment: other},
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
      |> Advert.Public.get_by_assignment([:submission])

    reward_value
  end

  def validate_open(%Assignment.Model{} = assignment, user) do
    assignment
    |> get_by_assignment(Advert.Model.preload_graph(:down))
    |> validate_open(user)
  end

  def validate_open(%Advert.Model{} = advert, user) do
    with :ok <- validate_member(advert, user),
         :ok <- validate_exclusion(advert, user),
         :ok <- validate_eligitable(advert, user),
         :ok <- validate_open_spots(advert),
         :ok <- validate_released(advert),
         :ok <- validate_funded(advert) do
      :ok
    else
      error -> error
    end
  end

  def validate_open(%Advert.Model{} = advert) do
    with :ok <- validate_open_spots(advert),
         :ok <- validate_released(advert),
         :ok <- validate_funded(advert) do
      :ok
    else
      error -> error
    end
  end

  defp validate_member(%{assignment: assignment}, user) do
    if Assignment.Public.member?(assignment, user) do
      {:error, :already_member}
    else
      :ok
    end
  end

  defp validate_exclusion(%{assignment: assignment}, user) do
    if Assignment.Public.excluded?(assignment, user) do
      {:error, :excluded}
    else
      :ok
    end
  end

  defp validate_eligitable(%{submission: %{criteria: criteria}}, user) do
    user_features = Account.Public.get_features(user)

    if Pool.CriteriaModel.eligitable?(criteria, user_features) do
      :ok
    else
      {:error, :not_eligitable}
    end
  end

  defp validate_open_spots(%{assignment: assignment}) do
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

  # FIXME: take care of funding
  defp validate_funded(%{assignment: %{budget: nil}}) do
    Logger.error("FIXME: take care of funding")
    :ok
  end

  defp validate_funded(%{
         assignment: %{budget: %{currency: %{type: :legal}} = budget},
         submission: %{reward_value: reward_value}
       }) do
    if Budget.Model.amount_available(budget) > reward_value do
      :ok
    else
      {:error, :not_funded}
    end
  end

  defp validate_funded(%{assignment: %{budget: %{currency: %{type: _}}}}), do: :ok

  @doc """
    Marks expired tasks in online adverts based on updated_at and estimated duration.
    If force is true (for debug purposes only), all pending tasks will be marked as expired.
  """
  def mark_expired_debug(force \\ false) do
    submission_ids =
      from(s in Pool.SubmissionModel, where: s.status == :accepted)
      |> Repo.all()
      |> Enum.map(& &1.id)

    preload = Advert.Model.preload_graph(:down)

    from(c in Advert.Model,
      where: c.submission_id in ^submission_ids,
      preload: ^preload
    )
    |> Repo.all()
    |> Enum.each(&mark_expired_debug(&1, force))
  end

  @doc """
    Marks expired tasks in given advert
  """
  def mark_expired_debug(%{assignment: assignment}, force) do
    Assignment.Public.mark_expired_debug(assignment, force)
  end

  def payout_participant(%Assignment.Model{} = assignment, %User{} = user) do
    Assignment.Public.payout_participant(assignment, user)
  end

  def rewarded_amount(%Assignment.Model{} = assignment, %User{} = user) do
    Assignment.Public.rewarded_amount(assignment, user)
  end

  def reward_amount(%Assignment.Model{id: assignment_id}) do
    from(c in Advert.Model,
      inner_join: s in Pool.SubmissionModel,
      on: s.id == c.submission_id,
      inner_join: ec in Pool.CriteriaModel,
      on: ec.submission_id == s.id,
      where: c.assignment_id == ^assignment_id,
      select: s.reward_value
    )
    |> Repo.one!()
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

  def import_participant_reward(participant_id, amount, session_key, currency)
      when is_binary(currency) do
    idempotence_key = import_idempotence_key(session_key, participant_id)
    participant = Systems.Account.Public.get_user!(participant_id)

    if user_has_currency?(participant, currency) do
      from = ["fund", currency]
      to = ["wallet", currency, participant_id]

      journal_message =
        "Participant #{participant_id} earned #{amount} by import during session '#{session_key}'"

      import_participant_reward(from, to, amount, idempotence_key, journal_message)
    else
      Logger.warning(
        "Import reward failed, user has no access to currency #{currency}: amount=#{amount} idempotence_key=#{idempotence_key}"
      )
    end
  end

  defp import_participant_reward(from, to, amount, idempotence_key, journal_message) do
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
      Logger.warning("Import reward skipped: amount=#{amount} idempotence_key=#{idempotence_key}")
    else
      result = Bookkeeping.Public.enter(payment)

      with {:error, error} <- result do
        Logger.warning("Import reward failed: idempotence_key=#{idempotence_key}, error=#{error}")
      end
    end
  end

  def import_participant_reward_exists?(participant_id, session_key) do
    idempotence_key = import_idempotence_key(session_key, participant_id)
    Bookkeeping.Public.exists?(idempotence_key)
  end

  defp import_idempotence_key(session_key, user_id) do
    "import=#{session_key},user=#{user_id}"
  end
end
