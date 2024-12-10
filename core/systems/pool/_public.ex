defmodule Systems.Pool.Public do
  use Core.FeatureFlags

  use Gettext, backend: CoreWeb.Gettext
  import Ecto.Query, warn: false
  import Systems.Pool.Queries

  alias Ecto.Multi
  alias Ecto.Changeset
  alias Frameworks.Signal
  alias Frameworks.Concept.Directable

  alias Core.Repo
  alias Core.Authorization

  alias Systems.Account
  alias Systems.Pool
  alias Systems.Bookkeeping
  alias Systems.NextAction
  alias Systems.Org

  def list(preload \\ []) do
    Repo.all(Pool.Model) |> Repo.preload(preload)
  end

  def list_active(preload \\ []) do
    from(pool in Pool.Model,
      where: pool.archived == false,
      order_by: [asc: :director, asc: :name],
      preload: ^preload
    )
    |> Repo.all()
  end

  def list_owned(user, preload \\ []) do
    node_ids =
      Authorization.query_node_ids(
        role: :owner,
        principal: user
      )

    from(p in Pool.Model,
      where: p.auth_node_id in subquery(node_ids),
      order_by: [desc: p.updated_at],
      preload: ^preload
    )
    |> Repo.all()
  end

  def list_by_participant(%Account.User{} = user, preload \\ []) do
    pool_query(user, :participant)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_by_orgs(orgs, preload \\ [])

  def list_by_orgs([%Org.NodeModel{} | _] = orgs, preload) do
    orgs
    |> Enum.map(& &1.id)
    |> list_by_orgs(preload)
  end

  def list_by_orgs([head | _] = orgs, preload) when is_integer(head) do
    from(p in Pool.Model,
      inner_join: o in Org.NodeModel,
      on: o.id == p.org_id,
      where: o.id in ^orgs,
      order_by: [desc: p.inserted_at],
      preload: ^preload
    )
    |> Repo.all()
  end

  def list_by_org(org_identifier, preload \\ []) when is_list(org_identifier) do
    from(p in Pool.Model,
      inner_join: o in Org.NodeModel,
      on: o.id == p.org_id,
      where: o.identifier == ^org_identifier,
      preload: ^preload
    )
    |> Repo.all()
  end

  def list_by_director(director, preload \\ []) do
    from(pool in Pool.Model,
      where: pool.director == ^director,
      preload: ^preload
    )
    |> Repo.all()
  end

  def list_submissions do
    Repo.all(Pool.SubmissionModel)
  end

  def list_submissions(status, preload \\ [:criteria]) do
    from(submission in Pool.SubmissionModel,
      where: submission.status == ^status,
      preload: ^preload
    )
    |> Repo.all()
  end

  def submit(%Pool.SubmissionModel{id: id, pool: pool}) do
    Directable.director(pool).submit(id)
  end

  def list_directors() do
    from(p in Pool.Model,
      distinct: true,
      select: p.director
    )
    |> Repo.all()
    |> Enum.map(&Directable.director/1)
  end

  def list_participants(%Pool.Model{} = pool) do
    Authorization.users_with_role(pool, :participant)
  end

  def get!(id, preload \\ []), do: Repo.get!(Pool.Model, id) |> Repo.preload(preload)
  def get(id, preload \\ []), do: Repo.get(Pool.Model, id) |> Repo.preload(preload)

  def get_by_name(name, preload \\ [])

  def get_by_name(name, preload) when is_atom(name),
    do: get_by_name(Atom.to_string(name), preload)

  def get_by_name(name, preload) do
    Repo.get_by(Pool.Model, name: name)
    |> Repo.preload(preload)
  end

  def get_by_names(names, preload \\ []) do
    names = map_string(names)

    from(p in Pool.Model,
      where: p.name in ^names,
      preload: ^preload
    )
    |> Repo.all()
  end

  def get_panl(preload \\ []) do
    get_by_name("Panl", preload)
  end

  def get_by_submission!(submission, preload \\ [])

  def get_by_submission!(%{id: submission_id}, preload) do
    get_by_submission!(submission_id, preload)
  end

  def get_by_submission!(submission_id, preload) do
    from(pool in Pool.Model,
      inner_join: submission in Pool.SubmissionModel,
      on: pool.id == submission.pool_id,
      where: submission.id == ^submission_id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  defp map_string(term) when is_list(term), do: Enum.map(term, &map_string(&1))
  defp map_string(term) when is_atom(term), do: Atom.to_string(term)
  defp map_string(term) when is_binary(term), do: term

  def participant?(%Pool.Model{} = pool, %Account.User{} = user) do
    pool_query(pool, user, [:participant, :tester])
    |> Repo.exists?()
  end

  def add_participant!(pool, user) do
    if not Authorization.user_has_role?(user, pool, :participant) do
      :ok = Authorization.assign_role(user, pool, :participant)
    end
  end

  def remove_participant(pool, user) do
    Authorization.remove_role!(user, pool, :participant)
  end

  def get_submission!(term, preload \\ [:criteria])

  def get_submission!(id, preload) do
    from(submission in Pool.SubmissionModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_or_create_budget(%Pool.Model{currency: %{budget: %{id: _id} = budget}}) do
    budget
  end

  def get_or_create_budget(%Pool.Model{} = pool) do
    Directable.director(pool).create_budget(pool)
  end

  def create!(name, target, currency, org, director) do
    %Pool.Model{}
    |> Pool.Model.change(%{name: name, target: target, director: director})
    |> Ecto.Changeset.put_assoc(:currency, currency)
    |> Ecto.Changeset.put_assoc(:org, org)
    |> Repo.insert!()
  end

  def update!(%Pool.Model{} = pool, attrs) do
    pool
    |> Pool.Model.change(attrs)
    |> Repo.update!()
  end

  def prepare_submission(%{} = attrs, pool) do
    criteria =
      %Pool.CriteriaModel{}
      |> Pool.CriteriaModel.changeset(%{})

    %Pool.SubmissionModel{}
    |> Pool.SubmissionModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:pool, pool)
    |> Ecto.Changeset.put_assoc(:criteria, criteria)
  end

  def copy(%Pool.SubmissionModel{pool: pool, criteria: criteria} = submission) do
    attrs =
      submission
      |> Map.from_struct()
      |> Map.put(:status, :idle)
      |> Map.put(:reward_value, nil)

    criteria_copy =
      %Pool.CriteriaModel{}
      |> Pool.CriteriaModel.changeset(Map.from_struct(criteria))

    %Pool.SubmissionModel{}
    |> Pool.SubmissionModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:criteria, criteria_copy)
    |> Ecto.Changeset.put_assoc(:pool, pool)
    |> Repo.insert!()
  end

  def update(%Pool.SubmissionModel{}, %Changeset{} = changeset) do
    Multi.new()
    |> Multi.update(:submission, changeset)
    |> Multi.run(:dispatch, fn _, %{submission: submission} ->
      Signal.Public.dispatch!({:submission, :updated}, %{submission: submission})
      {:ok, true}
    end)
    |> Multi.run(:notify, fn _, %{submission: submission} ->
      notify_when_submitted(submission, changeset)
      {:ok, true}
    end)
    |> Repo.transaction()
  end

  def update(%Pool.SubmissionModel{} = submission, attrs) do
    changeset = Pool.SubmissionModel.changeset(submission, attrs)
    __MODULE__.update(submission, changeset)
  end

  def update(%Pool.CriteriaModel{} = _criteria, %Changeset{} = changeset) do
    Multi.new()
    |> Multi.update(:criteria, changeset)
    |> Multi.run(:dispatch, fn _, %{criteria: criteria} ->
      Signal.Public.dispatch!({:criteria, :updated}, %{criteria: criteria})
    end)
    |> Repo.transaction()
  end

  def select(nil, _user), do: nil
  def select([], _user), do: nil

  def select(submissions, user) when is_list(submissions) do
    case Enum.find(submissions, &__MODULE__.select(&1, user)) do
      nil -> List.first(submissions)
      submission -> submission
    end
  end

  def select(%Pool.SubmissionModel{criteria: submission_criteria}, user) do
    user_features = Account.Public.get_features(user)
    Pool.CriteriaModel.eligitable?(submission_criteria, user_features)
  end

  def count_eligitable_users(
        %Pool.CriteriaModel{
          genders: genders,
          dominant_hands: dominant_hands,
          native_languages: native_languages
        },
        include,
        exclude
      ) do
    genders = genders |> to_string_list()
    dominant_hands = dominant_hands |> to_string_list()
    native_languages = native_languages |> to_string_list()

    query_count_users(include, exclude)
    |> optional_where(:gender, genders)
    |> optional_where(:dominant_hand, dominant_hands)
    |> optional_where(:native_language, native_languages)
    |> Repo.one()
  end

  defp query_count_users(include, exclude) do
    from(user in Account.User,
      join: features in assoc(user, :features),
      select: count(user.id),
      where: user.id in ^include,
      where: user.id not in ^exclude
    )
  end

  defp to_string_list(nil), do: []

  defp to_string_list(list) when is_list(list) do
    Enum.map(list, &Atom.to_string(&1))
  end

  defp optional_where(query, type, values)
  defp optional_where(query, _, []), do: query

  defp optional_where(query, field_name, values) do
    where(query, [user, features], field(features, ^field_name) in ^values)
  end

  def target_achieved?(
        %Pool.Model{target: target},
        %{balance_credit: balance_credit}
      ) do
    balance_credit >= target
  end

  def target_achieved?(_, _), do: false

  def wallet_related?(
        %Pool.Model{currency: %{name: currency_name}},
        %Bookkeeping.AccountModel{identifier: ["wallet", wallet_name, _]}
      ) do
    wallet_name == currency_name
  end

  def wallet_related?(_, _), do: false

  defp notify_when_submitted(
         %Pool.SubmissionModel{pool_id: pool_id} = submission,
         %Ecto.Changeset{} = changeset
       ) do
    if Ecto.Changeset.get_change(changeset, :status) === :submitted do
      for user <- Account.Public.list_pool_admins() do
        NextAction.Public.create_next_action(user, Pool.ReviewSubmission,
          key: "#{pool_id}",
          params: %{id: pool_id}
        )
      end
    end

    submission
  end

  def get_tag(nil) do
    %{text: dgettext("eyra-submission", "status.idle.label"), type: :tertiary}
  end

  def get_tag(%Pool.SubmissionModel{status: status, submitted_at: submitted_at} = submission) do
    case {status, submitted_at} do
      {:idle, nil} ->
        get_tag(nil)

      {:idle, _} ->
        %{text: dgettext("eyra-submission", "status.retracted.label"), type: :delete}

      {:submitted, _} ->
        %{text: dgettext("eyra-submission", "status.submitted.label"), type: :tertiary}

      {:accepted, _} ->
        case published_status(submission) do
          :scheduled ->
            %{
              text: dgettext("eyra-submission", "status.accepted.scheduled.label"),
              type: :tertiary
            }

          :released ->
            %{text: dgettext("eyra-submission", "status.accepted.online.label"), type: :success}

          :closed ->
            %{text: dgettext("eyra-submission", "status.accepted.closed.label"), type: :disabled}
        end

      {:completed, _} ->
        %{text: dgettext("eyra-submission", "status.completed.label"), type: :disabled}
    end
  end

  def published_status(submission) do
    cond do
      Pool.SubmissionModel.schedule_ended?(submission) -> :closed
      Pool.SubmissionModel.completed?(submission) -> :closed
      Pool.SubmissionModel.scheduled?(submission) -> :scheduled
      true -> :released
    end
  end

  def update_pool_participations(user, added_to_pools, deleted_from_pools) do
    Multi.new()
    |> Multi.run(:add, fn _, _ ->
      added_to_pools
      |> update_pools(user, :add)

      {:ok, true}
    end)
    |> Multi.run(:delete, fn _, _ ->
      deleted_from_pools
      |> update_pools(user, :delete)

      {:ok, true}
    end)
    |> Repo.transaction()
  end

  defp update_pools([_ | _] = pool_names, user, command) do
    pool_names
    |> get_by_names()
    |> Enum.map(&update_pool(&1, user, command))
  end

  defp update_pools(_, _, _), do: nil

  defp update_pool(pool, user, :add), do: add_participant!(pool, user)
  defp update_pool(pool, user, :delete), do: remove_participant(pool, user)
end
