defmodule Link.Studies do
  @moduledoc """
  The Studies context.
  """

  import Ecto.Query, warn: false
  alias Link.Repo
  alias Link.Authorization

  alias Link.Studies.{Study, Participant}
  alias Link.Users.User
  alias Link.SurveyTools.SurveyTool

  alias GreenLight.Principal

  # read list_studies(current_user, ...) do
  # end

  @doc """
  Returns the list of studies.

  ## Examples

      iex> list_studies()
      [%Study{}, ...]

  """
  def list_studies(opts \\ []) do
    exclude = Keyword.get(opts, :exclude, []) |> Enum.to_list()

    from(s in Study,
      where: s.id not in ^exclude
    )
    |> Repo.all()

    # AUTH: Can be piped through auth filter.
  end

  @doc """
  Returns the list of studies that are owned by the user.
  """
  def list_owned_studies(user) do
    entity_ids =
      Authorization.query_entity_ids(
        entity_type: Study,
        role: :owner,
        principal: Authorization.principal(user)
      )

    from(s in Study, where: s.id in subquery(entity_ids)) |> Repo.all()
    # AUTH: Can be piped through auth filter (current code does the same thing).
  end

  def list_owners(%Study{} = study) do
    owner_ids =
      study
      |> Authorization.list_principals()
      |> Enum.filter(fn %{roles: roles} -> MapSet.member?(roles, :owner) end)
      |> Enum.map(fn %{id: id} -> id end)

    from(u in User, where: u.id in ^owner_ids, order_by: u.id) |> Repo.all()
    # AUTH: needs to be marked save. Current user is normally not allowed to
    # access other users.
  end

  def assign_owners(study, users) do
    existing_owner_ids =
      Authorization.list_principals(study)
      |> Enum.filter(fn %{roles: roles} -> MapSet.member?(roles, :owner) end)
      |> Enum.map(fn %{id: id} -> id end)
      |> Enum.into(MapSet.new())

    new_owners = users |> Enum.map(&Authorization.principal/1)

    new_owners
    |> Enum.filter(fn principal -> not MapSet.member?(existing_owner_ids, principal.id) end)
    |> Enum.each(&Authorization.assign_role!(&1, study, :owner))

    new_owner_ids =
      new_owners
      |> Enum.map(fn %{id: id} -> id end)
      |> Enum.into(MapSet.new())

    existing_owner_ids
    |> Enum.filter(fn id -> not MapSet.member?(new_owner_ids, id) end)
    |> Enum.each(&Authorization.remove_role!(%Principal{id: &1}, study, :owner))

    # AUTH: Does not modify entities, only auth. This needs checks to see if
    # the user is allowed to manage permissions? Could be implemented as part
    # of the authorization functions?
  end

  def add_owner!(study, user) do
    user
    |> Authorization.assign_role!(study, :owner)

    # AUTH: Does not modify entities, only auth. This needs checks to see if
    # the user is allowed to manage permissions?
  end

  @doc """
  Gets a single study.

  Raises `Ecto.NoResultsError` if the Study does not exist.

  ## Examples

      iex> get_study!(123)
      %Study{}

      iex> get_study!(456)
      ** (Ecto.NoResultsError)

  """
  def get_study!(id), do: Repo.get!(Study, id)

  def get_study_changeset(attrs \\ %{}) do
    %Study{}
    |> Study.changeset(attrs)
  end

  @doc """
  Creates a study.
  """
  def create_study(%Ecto.Changeset{} = changeset, researcher) do
    changeset
    |> Repo.insert()
    # AUTH; how to check this.
    |> Authorization.assign_role(researcher, :owner)

    # AUTH: Does not modify entities, only auth. This needs checks to see if
    # the user is allowed to manage permissions?
  end

  def create_study(attrs, researcher) do
    attrs
    |> get_study_changeset()
    |> create_study(researcher)
  end

  @doc """
  Updates a study.

  ## Examples

      iex> update_study(study, %{field: new_value})
      {:ok, %Study{}}

      iex> update_study(study, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_study(%Ecto.Changeset{} = changeset) do
    changeset
    |> Repo.update()
  end

  def update_study(%Study{} = study, attrs) do
    study
    |> Study.changeset(attrs)
    |> update_study
  end

  @doc """
  Deletes a study.

  ## Examples

      iex> delete_study(study)
      {:ok, %Study{}}

      iex> delete_study(study)
      {:error, %Ecto.Changeset{}}

  """
  def delete_study(%Study{} = study) do
    Repo.delete(study)
    # AUTH; how to check this.
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking study changes.

  ## Examples

      iex> change_study(study)
      %Ecto.Changeset{data: %Study{}}

  """
  def change_study(%Study{} = study, attrs \\ %{}) do
    Study.changeset(study, attrs)
  end

  def apply_participant(%Study{} = study, %User{} = user) do
    %Participant{status: :applied}
    |> Participant.changeset()
    |> Ecto.Changeset.put_assoc(:study, study)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  defp update_participant_roles(%Study{} = study, %User{} = user, status) do
    if status == :entered do
      Authorization.assign_role!(user, study, :participant)
    else
      Authorization.remove_role!(user, study, :participant)
    end
  end

  @spec update_participant_status(Link.Studies.Study.t(), Link.Users.User.t(), atom()) ::
          :error | :ok
  def update_participant_status(%Study{} = study, %User{} = user, status) do
    {update_count, _} =
      from(p in Participant,
        where: p.study_id == ^study.id and p.user_id == ^user.id,
        update: [set: [status: ^status]]
      )
      |> Repo.update_all([])

    if update_count == 1 do
      update_participant_roles(study, user, status)
      :ok
    else
      :error
    end
  end

  def application_status(%Study{} = study, %User{} = user) do
    from(p in Participant,
      select: p.status,
      where:
        p.user_id == ^user.id and
          p.study_id ==
            ^study.id
    )
    |> Repo.one()
  end

  defp filter_participations_by_status(query, nil), do: query

  defp filter_participations_by_status(query, status) do
    query |> where([p], p.status == ^status)
  end

  def list_participants(%Study{} = study, status \\ nil) do
    from(p in Participant,
      where: p.study_id == ^study.id,
      order_by: :status,
      preload: [:user]
    )
    |> filter_participations_by_status(status)
    |> Repo.all()

    # |> Enum.map(fn [user, status] -> %{user: user, status: status} end)
  end

  def list_survey_tools(%Study{} = study) do
    from(s in SurveyTool, where: s.study_id == ^study.id)
    |> Repo.all()
  end

  def list_participations(%User{} = user) do
    from(s in Study, join: p in Participant, on: s.id == p.study_id, where: p.user_id == ^user.id)
    |> Repo.all()
  end
end
