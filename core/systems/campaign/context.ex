defmodule Systems.Campaign.Context do
  @moduledoc """
  The Studies context.
  """

  import Ecto.Query, warn: false
  alias Frameworks.GreenLight.Principal
  alias Core.Repo
  alias Core.Authorization

  alias Systems.{
    Campaign,
    Promotion,
    Assignment,
    Survey,
    Crew
  }

  alias Core.Accounts.User
  alias Core.Pools.Submission
  alias Frameworks.Signal

  def get!(id, preload \\ []) do
    from(c in Campaign.Model,
      where: c.id == ^id,
      preload: ^preload
    )
    |> Repo.one!()
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

    member_ids = from(m in Crew.MemberModel, where: m.user_id == ^user.id and m.expired == false, select: m.id)
    crew_ids = from(t in Crew.TaskModel, where: t.member_id in subquery(member_ids), select: t.crew_id)
    assigment_ids = from(a in Assignment.Model, where: a.crew_id in subquery(crew_ids), select: a.id)

    from(c in Campaign.Model,
      where: c.promotable_assignment_id in subquery(assigment_ids),
      preload: ^preload,
      order_by: [desc: c.updated_at]
    )
    |> Repo.all()
  end

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

  def copy(%Campaign.Model{} = campaign, %Promotion.Model{} = promotion, %Assignment.Model{} = assignment, auth_node) do
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

  def list_authors(%Campaign.Model{} = campaign) do
    from(
      a in Campaign.AuthorModel,
      where: a.campaign_id == ^campaign.id,
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
      |> Enum.map(&(&1.promotion_id))

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

end
