defmodule Systems.Pool.Context do
  import CoreWeb.Gettext
  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Ecto.Changeset
  alias Core.Repo
  alias Core.Accounts

  alias Frameworks.Signal

  alias Systems.{
    Pool,
    NextAction,
    Org
  }

  def list(preload \\ []) do
    Repo.all(Pool.Model) |> Repo.preload(preload)
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

  def list_by_currency(%{id: currency_id}) do
    list_by_currency(currency_id)
  end

  def list_by_currency(currency_id, preload \\ []) do
    from(pool in Pool.Model,
      where: pool.currency_id == ^currency_id,
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

  defp map_string(term) when is_list(term), do: Enum.map(term, &map_string(&1))
  defp map_string(term) when is_atom(term), do: Atom.to_string(term)
  defp map_string(term) when is_binary(term), do: term

  def get_participant!(%Pool.Model{} = pool, %Accounts.User{} = user, preload \\ []) do
    from(participant in Pool.ParticipantModel,
      where: participant.pool_id == ^pool.id,
      where: participant.user_id == ^user.id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def link!(%Pool.Model{} = pool, %Accounts.User{} = user) do
    %Pool.ParticipantModel{}
    |> Pool.ParticipantModel.changeset(pool, user)
    |> Repo.insert!(
      on_conflict: :nothing,
      conflict_target: [:pool_id, :user_id]
    )
  end

  def unlink!(%Pool.Model{} = pool, %Accounts.User{} = user) do
    from(p in Pool.ParticipantModel,
      where: p.pool_id == ^pool.id,
      where: p.user_id == ^user.id
    )
    |> Repo.delete_all()
  end

  def get_submission!(term, preload \\ [:criteria])

  def get_submission!(id, preload) do
    from(submission in Pool.SubmissionModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def create(name) do
    %Pool.Model{name: name}
    |> Repo.insert!()
  end

  def create_submission(%{} = attrs, pool) do
    submission_changeset =
      %Pool.SubmissionModel{}
      |> Pool.SubmissionModel.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:pool, pool)

    criteria_changeset =
      %Pool.CriteriaModel{}
      |> Pool.CriteriaModel.changeset(%{
        study_program_codes: [:vu_sbe_bk_1, :vu_sbe_bk_1_h, :vu_sbe_iba_1, :vu_sbe_iba_1_h]
      })
      |> Ecto.Changeset.put_assoc(:submission, submission_changeset)

    criteria = Repo.insert!(criteria_changeset)

    {:ok, criteria.submission}
  end

  def copy(submissions) when is_list(submissions) do
    Enum.map(submissions, &copy(&1))
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

  def update(%Pool.SubmissionModel{} = _submission, %Changeset{} = changeset) do
    result =
      Multi.new()
      |> Multi.update(:submission, changeset)
      |> Repo.transaction()

    with {:ok, %{submission: submission}} <- result do
      Signal.Context.dispatch!(:submission_updated, submission)
      {:ok, notify_when_submitted(submission, changeset)}
    end

    result
  end

  def update(%Pool.SubmissionModel{} = submission, attrs) do
    changeset = Pool.SubmissionModel.changeset(submission, attrs)
    __MODULE__.update(submission, changeset)
  end

  def update(%Pool.CriteriaModel{} = _criteria, %Changeset{} = changeset) do
    result =
      Multi.new()
      |> Multi.update(:criteria, changeset)
      |> Repo.transaction()

    with {:ok, %{criteria: criteria}} <- result do
      Signal.Context.dispatch!(:criteria_updated, criteria)
    end

    result
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
    user_features = Accounts.get_features(user)
    Pool.CriteriaModel.eligitable?(submission_criteria, user_features)
  end

  def count_eligitable_users(study_program_codes, exclude \\ [])
  def count_eligitable_users(nil, exclude), do: count_eligitable_users([], exclude)

  def count_eligitable_users(study_program_codes, exclude) when is_list(study_program_codes) do
    study_program_codes = study_program_codes |> to_string_list()

    study_program_codes
    |> query_count_eligitable_users(exclude)
    |> Repo.one()
  end

  def count_eligitable_users(
        %Pool.CriteriaModel{
          genders: genders,
          dominant_hands: dominant_hands,
          native_languages: native_languages,
          study_program_codes: study_program_codes
        },
        exclude
      ) do
    genders = genders |> to_string_list()
    dominant_hands = dominant_hands |> to_string_list()
    native_languages = native_languages |> to_string_list()
    study_program_codes = study_program_codes |> to_string_list()

    study_program_codes
    |> query_count_eligitable_users(exclude)
    |> optional_where(:gender, genders)
    |> optional_where(:dominant_hand, dominant_hands)
    |> optional_where(:native_language, native_languages)
    |> Repo.one()
  end

  def count_students(study_program_codes) do
    study_program_codes = study_program_codes |> to_string_list()

    study_program_codes
    |> query_count_eligitable_users([])
    |> where([user, features], user.student == true)
    |> Repo.one()
  end

  defp query_count_eligitable_users(study_program_codes, exclude) do
    from(user in Accounts.User,
      join: features in assoc(user, :features),
      select: count(user.id),
      where: user.id not in ^exclude,
      where: fragment("? && ?", features.study_program_codes, ^study_program_codes)
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

  def target("vu_sbe_rpr_year1_2021"), do: target(:first)
  def target("vu_sbe_rpr_year2_2021"), do: target(:second)
  def target(:first), do: 60
  def target(:second), do: 3
  def target(_), do: -1

  def is_target_achieved?(
        %{identifier: ["wallet" | [currency, _user_id]], balance_credit: balance_credit} =
          _account
      ) do
    balance_credit >= target(currency)
  end

  def is_target_achieved?(_), do: false

  defp notify_when_submitted(
         %Pool.SubmissionModel{pool_id: pool_id} = submission,
         %Ecto.Changeset{} = changeset
       ) do
    if Ecto.Changeset.get_change(changeset, :status) === :submitted do
      for user <- Accounts.list_pool_admins() do
        NextAction.Context.create_next_action(user, Pool.ReviewSubmission,
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
    if Pool.SubmissionModel.schedule_ended?(submission) do
      :closed
    else
      if Systems.Director.context(submission).open?(submission) do
        if Pool.SubmissionModel.scheduled?(submission) do
          :scheduled
        else
          :released
        end
      else
        :closed
      end
    end
  end
end
