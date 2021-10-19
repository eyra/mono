defmodule Systems.Campaign.Context do
  @moduledoc """
  The Studies context.
  """

  import Ecto.Query, warn: false
  alias GreenLight.Principal
  alias Core.Repo
  alias Core.Authorization

  alias Systems.{
    Campaign,
    Crew
  }
  alias Core.Accounts.User
  alias Core.Survey.Tool
  alias Core.DataDonation
  alias Core.Promotions.Promotion
  alias Core.Pools.Submission
  alias Frameworks.Signal

  # read list(current_user, ...) do
  # end

  @doc """
  Returns the list of studies.

  ## Examples

      iex> list()
      [%Campaign.Model{}, ...]

  """
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

    promotions =
      from(promotion in Promotion,
        where: promotion.id in subquery(accepted_submissions),
        select: promotion.id
      )

    studie_ids =
      tool_entities
      |> Enum.map(
        &from(tool in &1,
          where: tool.promotion_id in subquery(promotions),
          select: tool.study_id
        )
      )
      |> Enum.reduce(fn tool_query, query ->
        union_all(
          query,
          ^tool_query
        )
      end)

    from(campaign in Campaign.Model,
      where: campaign.id in subquery(studie_ids) and campaign.id not in ^exclude,
      preload: ^preload
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

    member_ids = from(m in Crew.MemberModel, where: m.user_id == ^user.id, select: m.id)
    crew_ids = from(t in Crew.TaskModel, where: t.member_id in subquery(member_ids), select: t.crew_id)
    campaign_ids = from(c in Crew.Model, where: c.reference_type == :campaign and c.id in subquery(crew_ids), select: c.reference_id)

    from(s in Campaign.Model,
      where: s.id in subquery(campaign_ids),
      preload: ^preload
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of studies where the user is a data donation subject.
  """
  def list_data_donation_subject_campaigns(user, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    tool_ids =
      from(task in DataDonation.Task,
        where: task.user_id == ^user.id,
        select: task.tool_id
      )

    campaign_ids =
      from(st in DataDonation.Tool, where: st.id in subquery(tool_ids), select: st.study_id)

    from(s in Campaign.Model,
      where: s.id in subquery(campaign_ids),
      preload: ^preload
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

  @doc """
  Gets a single campaign.

  Raises `Ecto.NoResultsError` if the Study does not exist.

  ## Examples

      iex> get!(123)
      %Campaign.Model{}

      iex> get!(456)
      ** (Ecto.NoResultsError)

  """
  def get!(id, preload \\ []) do
    from(c in Campaign.Model,
      where: c.id == ^id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def get_changeset(attrs \\ %{}) do
    %Campaign.Model{}
    |> Campaign.Model.changeset(attrs)
  end

  @doc """
  Creates a campaign.
  """
  def create(%Ecto.Changeset{} = changeset, researcher) do
    with {:ok, campaign} <-
           changeset
           |> Ecto.Changeset.put_assoc(:auth_node, Core.Authorization.make_node())
           |> Repo.insert() do
      :ok = Authorization.assign_role(researcher, campaign, :owner)
      Signal.Context.dispatch!(:campaign_created, %{campaign: campaign})
      {:ok, campaign}
    end
  end

  def create(attrs, researcher) do
    attrs
    |> get_changeset()
    |> create(researcher)
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

  @doc """
  Deletes a get_campaign.

  ## Examples

      iex> delete(campaign)
      {:ok, %Campaign.Model{}}

      iex> delete(campaign)
      {:error, %Ecto.Changeset{}}

  """
  def delete(%Campaign.Model{} = campaign) do
    Repo.delete(campaign)
    # AUTH; how to check this.
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking campaign changes.

  ## Examples

      iex> change(campaign)
      %Ecto.Changeset{data: %Campaign.Model{}}

  """
  def change(%Campaign.Model{} = campaign, attrs \\ %{}) do
    Campaign.Model.changeset(campaign, attrs)
  end

  def add_author(%Campaign.Model{} = campaign, %User{} = researcher) do
    researcher
    |> Campaign.AuthorModel.from_user()
    |> Campaign.AuthorModel.changeset()
    |> Ecto.Changeset.put_assoc(:study, campaign)
    |> Ecto.Changeset.put_assoc(:user, researcher)
    |> Repo.insert()
  end

  def list_authors(%Campaign.Model{} = campaign) do
    from(
      a in Campaign.AuthorModel,
      where: a.study_id == ^campaign.id,
      preload: [user: [:profile]]
    )
    |> Repo.all()
  end

  def list_survey_tools(%Campaign.Model{} = campaign) do
    from(s in Tool, where: s.study_id == ^campaign.id)
    |> Repo.all()
  end

  def list_tools(%Campaign.Model{} = campaign, schema) do
    from(s in schema, where: s.study_id == ^campaign.id)
    |> Repo.all()
  end


  # Crew

  def get_crew(campaign) do
    reference_type = "campaign"
    reference_id = "#{campaign.id}"
    from(
      c in Crew.Model,
      where: c.reference_type == ^reference_type and c.reference_id == ^reference_id
    )
    |> Repo.one()
  end

  def create_crew(campaign) do
    Crew.Context.create(:campaign, campaign.id, Core.Authorization.make_node(campaign))
  end

  def get_or_create_crew(campaign) do
    case get_crew(campaign) do
      nil -> create_crew(campaign)
      crew -> {:ok, crew}
    end
  end

  def get_or_create_crew!(campaign) do
    case get_or_create_crew(campaign) do
      {:ok, crew} -> crew
      _ -> nil
    end
  end

end
