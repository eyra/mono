defmodule Systems.Campaign.Context do
  @moduledoc """
  The Studies context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Frameworks.GreenLight.Principal
  alias Core.Repo
  alias Core.Accounts.User
  alias Core.Authorization
  alias Core.Enums.StudyProgramCodes

  alias Systems.{
    Campaign,
    Promotion,
    Assignment,
    Survey,
    Crew,
    Bookkeeping
  }

  alias Core.Accounts.User
  alias Core.Pools.{Submission, Criteria}
  alias Frameworks.Signal

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

  def get_by_promotables(promotable_ids, preload) when is_list(promotable_ids) do
    from(c in Campaign.Model,
      where: c.promotable_assignment_id in ^promotable_ids,
      preload: ^preload
    )
    |> Repo.all()
  end

  def list(opts \\ []) do
    exclude = Keyword.get(opts, :exclude, []) |> Enum.to_list()

    from(s in Campaign.Model,
      where: s.id not in ^exclude
    )
    |> Repo.all()

    # AUTH: Can be piped through auth filter.
  end

  def list_submitted_campaigns(tool_entities, opts \\ []) do
    list_by_submission_status(tool_entities, :submitted, opts)
  end

  def list_accepted_campaigns(tool_entities, opts \\ []) do
    list_by_submission_status(tool_entities, :accepted, opts)
  end

  def list_by_submission_status(tool_entities, submission_status, opts \\ [])
      when is_list(tool_entities) do
    preload = Keyword.get(opts, :preload, [])
    exclude = Keyword.get(opts, :exclude, []) |> Enum.to_list()

    accepted_submissions =
      from(submission in Submission,
        where: submission.status == ^submission_status,
        select: submission.id
      )

    promotion_ids =
      from(promotion in Promotion.Model,
        where: promotion.id in subquery(accepted_submissions),
        select: promotion.id
      )

    from(campaign in Campaign.Model,
      where: campaign.promotion_id in subquery(promotion_ids) and campaign.id not in ^exclude,
      preload: ^preload,
      order_by: {:desc, :inserted_at}
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

    from(s in Campaign.Model,
      where: s.auth_node_id in subquery(node_ids),
      order_by: [desc: s.updated_at],
      preload: ^preload
    )
    |> Repo.all()

    # AUTH: Can be piped through auth filter (current code does the same thing).
  end

  @doc """
  Returns the list of studies where the user is a subject.
  """
  def list_subject_campaigns(user, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    member_ids =
      from(m in Crew.MemberModel,
        where: m.user_id == ^user.id and m.expired == false,
        select: m.id
      )

    crew_ids =
      from(t in Crew.TaskModel, where: t.member_id in subquery(member_ids), select: t.crew_id)

    assigment_ids =
      from(a in Assignment.Model, where: a.crew_id in subquery(crew_ids), select: a.id)

    from(c in Campaign.Model,
      where: c.promotable_assignment_id in subquery(assigment_ids),
      preload: ^preload,
      order_by: [desc: c.updated_at]
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

  def list_excluded_campaigns(campaigns) when is_list(campaigns) do
    campaigns
    |> Enum.reduce([], fn campaign, acc ->
      acc ++ list_excluded_assignment_ids(campaign)
    end)
    |> get_by_promotables([])
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
    Assignment.Context.open_spot_count(assignment)
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
  def create(promotion, assignment, researcher, auth_node) do
    with {:ok, campaign} <-
           %Campaign.Model{}
           |> Campaign.Model.changeset(%{})
           |> Ecto.Changeset.put_assoc(:promotion, promotion)
           |> Ecto.Changeset.put_assoc(:promotable_assignment, assignment)
           |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
           |> Repo.insert() do
      :ok = Authorization.assign_role(researcher, campaign, :owner)
      Signal.Context.dispatch!(:campaign_created, %{campaign: campaign})
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

  def delete(id) when is_number(id) do
    get!(id, Campaign.Model.preload_graph(:full))
    |> Campaign.Assembly.delete()
  end

  def change(%Campaign.Model{} = campaign, attrs \\ %{}) do
    Campaign.Model.changeset(campaign, attrs)
  end

  def copy(
        %Campaign.Model{} = campaign,
        %Promotion.Model{} = promotion,
        %Assignment.Model{} = assignment,
        auth_node
      ) do
    %Campaign.Model{}
    |> Campaign.Model.changeset(
      campaign
      |> Map.delete(:updated_at)
      |> Map.from_struct()
    )
    |> Ecto.Changeset.put_assoc(:promotion, promotion)
    |> Ecto.Changeset.put_assoc(:promotable_assignment, assignment)
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

  def list_authors(%Campaign.Model{} = campaign) do
    from(
      a in Campaign.AuthorModel,
      where: a.campaign_id == ^campaign.id,
      order_by: {:asc, :inserted_at},
      preload: [user: [:profile]]
    )
    |> Repo.all()
  end

  def list_survey_tools(%Campaign.Model{} = campaign) do
    from(s in Survey.ToolModel, where: s.campaign_id == ^campaign.id)
    |> Repo.all()
  end

  def list_tools(%Campaign.Model{} = campaign, schema) do
    from(s in schema, where: s.campaign_id == ^campaign.id)
    |> Repo.all()
  end

  def search_subject(tool, public_id) do
    Assignment.Context.search_subject(tool, public_id)
  end

  def activate_task(tool, user_id) do
    Assignment.Context.activate_task(tool, user_id)
  end

  def assign_tester_role(tool, user) do
    Assignment.Context.assign_tester_role(tool, user)
  end

  def ready?(id) do
    # temp solution for checking if campaign is ready to submit,
    # TBD: replace with signal driven db field

    preload = Campaign.Model.preload_graph(:full)

    %{
      promotion: promotion,
      promotable_assignment: assignment
    } = Campaign.Context.get!(id, preload)

    Promotion.Context.ready?(promotion) &&
      Assignment.Context.ready?(assignment)
  end

  @doc """
    Marks expired tasks in online campaigns based on updated_at and estimated duration.
    If force is true (for debug purposes only), all pending tasks will be marked as expired.
  """
  def mark_expired_debug(force \\ false) do
    online_submissions =
      from(s in Submission, where: s.status == :accepted)
      |> Repo.all()
      |> Enum.filter(&(Submission.published_status(&1) == :online))

    promotion_ids =
      online_submissions
      |> Enum.map(& &1.promotion_id)

    preload = Campaign.Model.preload_graph(:full)

    from(c in Campaign.Model, preload: ^preload, where: c.promotion_id in ^promotion_ids)
    |> Repo.all()
    |> Enum.each(&mark_expired_debug(&1, force))
  end

  @doc """
    Marks expired tasks in given campaign
  """
  def mark_expired_debug(%{promotable_assignment: assignment}, force) do
    Assignment.Context.mark_expired_debug(assignment, force)
  end

  def reward_student(%{id: assignment_id} = _assignment, %{id: student_id} = _student) do
    {credits, study_program_codes} =
      from(c in Campaign.Model,
        inner_join: s in Submission,
        on: s.promotion_id == c.promotion_id,
        inner_join: ec in Criteria,
        on: ec.submission_id == s.id,
        where: c.promotable_assignment_id == ^assignment_id,
        select: {s.reward_value, ec.study_program_codes}
      )
      |> Repo.one!()

    reward_student({student_id, assignment_id, credits, study_program_codes})
  end

  def rewarded_value(assignment_id, user_id) do
    idempotence_key = idempotence_key(assignment_id, user_id)

    case Bookkeeping.Context.get_entry(idempotence_key) do
      %{lines: lines} -> rewarded_value(lines)
      _ -> 0
    end
  end

  defp rewarded_value([first_line | _]), do: rewarded_value(first_line)
  defp rewarded_value(%{debit: debit, credit: nil}), do: debit
  defp rewarded_value(%{debit: nil, credit: credit}), do: credit
  defp rewarded_value(_), do: 0

  defp guard_number_nil(nil), do: 0
  defp guard_number_nil(number), do: number

  def pending_rewards(%{id: student_id} = _student, year) when is_atom(year) do
    from([_, _, _, _, m] in pending_rewards_query(year),
      where: m.user_id == ^student_id
    )
    |> Repo.one!()
    |> guard_number_nil()
  end

  def pending_rewards(year) when is_atom(year) do
    from(c in pending_rewards_query(year))
    |> Repo.one!()
    |> guard_number_nil()
  end

  def pending_rewards_query(year) when is_atom(year) do
    study_program_codes =
      StudyProgramCodes.values_by_year(year)
      |> Enum.map(&Atom.to_string(&1))

    from(c in Campaign.Model,
      inner_join: s in Submission,
      on: s.promotion_id == c.promotion_id,
      inner_join: ec in Criteria,
      on: ec.submission_id == s.id,
      inner_join: a in Assignment.Model,
      on: a.id == c.promotable_assignment_id,
      inner_join: m in Crew.MemberModel,
      on: m.crew_id == a.crew_id,
      inner_join: t in Crew.TaskModel,
      on: t.member_id == m.id,
      where: t.status == :completed,
      where: fragment("? && ?", ec.study_program_codes, ^study_program_codes),
      select: sum(s.reward_value)
    )
  end

  @doc """
    Synchronizes accepted student tasks with with bookkeeping.
  """
  def sync_student_credits() do
    from(u in User,
      inner_join: m in Crew.MemberModel,
      on: m.user_id == u.id,
      inner_join: t in Crew.TaskModel,
      on: t.member_id == m.id,
      inner_join: a in Assignment.Model,
      on: a.crew_id == t.crew_id,
      inner_join: c in Campaign.Model,
      on: c.promotable_assignment_id == a.id,
      inner_join: s in Submission,
      on: s.promotion_id == c.promotion_id,
      inner_join: ec in Criteria,
      on: ec.submission_id == s.id,
      where: t.status == :accepted and u.student == true,
      select: {u.id, a.id, s.reward_value, ec.study_program_codes}
    )
    |> Repo.all()
    |> Enum.each(&reward_student(&1))
  end

  defp reward_student({student_id, assignment_id, credits, study_program_codes}) do
    year =
      if is_year?("1", study_program_codes) do
        "1"
      else
        "2"
      end

    create_student_credit_transaction(student_id, assignment_id, credits, year)
  end

  defp create_student_credit_transaction(student_id, assignment_id, credits, year) do
    idempotence_key = idempotence_key(assignment_id, student_id)

    pool = "sbe_year#{year}_2021"
    fund = {:fund, pool}
    wallet = {:wallet, pool, student_id}

    lines = [
      %{account: fund, debit: credits},
      %{account: wallet, credit: credits}
    ]

    if Bookkeeping.Context.exists?(idempotence_key) do
      Logger.warn(
        "Credit transaction skipped: credits=#{credits} idempotence_key=#{idempotence_key} from={fund, #{pool}} to={wallet, #{pool}, #{student_id}}"
      )
    else
      result =
        Bookkeeping.Context.enter(%{
          idempotence_key: idempotence_key,
          journal_message:
            "Student #{student_id} earned #{credits} credits by completing assignment #{assignment_id}",
          lines: lines
        })

      with {:error, error} <- result do
        Logger.warn(
          "Credit transaction failed: idempotence_key=#{idempotence_key}, error=#{error}"
        )
      end
    end
  end

  defp idempotence_key(assignment_id, user_id) do
    "assignment=#{assignment_id},user=#{user_id}"
  end

  defp is_year?(year, study_program_codes) when is_list(study_program_codes) do
    study_program_codes |> Enum.find(&is_year?(year, &1)) != nil
  end

  defp is_year?(year, study_program_code) when is_atom(study_program_code) do
    Atom.to_string(study_program_code) |> String.contains?(year)
  end
end
