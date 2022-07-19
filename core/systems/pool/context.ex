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
    Promotion,
    NextAction
  }

  def list() do
    ensure_sbe_2021_pool()
    Repo.all(Pool.Model)
  end

  def list_submissions do
    Repo.all(Pool.SubmissionModel)
  end

  def list_submissions(status, preload \\ [:criteria, :promotion]) do
    from(submission in Pool.SubmissionModel,
      where: submission.status == ^status,
      preload: ^preload
    )
    |> Repo.all()
  end

  def get!(id), do: Repo.get!(Pool.Model, id)
  def get(id), do: Repo.get(Pool.Model, id)

  def get_by_name(name) when is_atom(name), do: get_by_name(Atom.to_string(name))

  def get_by_name(name) do
    ensure_sbe_2021_pool()
    Repo.get_by(Pool.Model, name: name)
  end

  def get_submission!(term, preload \\ [:criteria, :promotion])

  def get_submission!(%Promotion.Model{} = promotion, preload) do
    from(submission in Pool.SubmissionModel,
      where: submission.promotion_id == ^promotion.id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def get_submission!(id, preload) do
    from(submission in Pool.SubmissionModel, preload: ^preload)
    |> Repo.get!(id)
  end

  defp ensure_sbe_2021_pool() do
    name = "sbe_2021"

    case Repo.get_by(Pool.Model, name: name) do
      nil -> create(name)
      pool -> {:ok, pool}
    end
  end

  def create(name) do
    %Pool.Model{name: name}
    |> Repo.insert!()
  end

  def create_submission(%{} = attrs, promotion, pool) do
    submission_changeset =
      %Pool.SubmissionModel{}
      |> Pool.SubmissionModel.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:promotion, promotion)
      |> Ecto.Changeset.put_assoc(:pool, pool)

    criteria_changeset =
      %Pool.CriteriaModel{}
      |> Pool.CriteriaModel.changeset(%{study_program_codes: [:bk_1, :bk_1_h, :iba_1, :iba_1_h]})
      |> Ecto.Changeset.put_assoc(:submission, submission_changeset)

    criteria = Repo.insert!(criteria_changeset)

    {:ok, criteria.submission}
  end

  def copy(%Pool.SubmissionModel{} = submission, %Promotion.Model{} = promotion, pool) do
    attrs =
      submission
      |> Map.from_struct()
      |> Map.put(:status, :idle)
      |> Map.put(:reward_value, nil)

    %Pool.SubmissionModel{}
    |> Pool.SubmissionModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:promotion, promotion)
    |> Ecto.Changeset.put_assoc(:pool, pool)
    |> Repo.insert!()
  end

  def copy(%Pool.CriteriaModel{} = criteria, %Pool.SubmissionModel{} = submission) do
    %Pool.CriteriaModel{}
    |> Pool.CriteriaModel.changeset(Map.from_struct(criteria))
    |> Ecto.Changeset.put_assoc(:submission, submission)
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

  def target("sbe_year1_2021"), do: target(:first)
  def target("sbe_year2_2021"), do: target(:second)
  def target(:first), do: 60
  def target(:second), do: 3
  def target(_), do: -1

  def is_target_achieved?(
        %{identifier: ["wallet" | [pool_id, _user_id]], balance_credit: balance_credit} = _account
      ) do
    balance_credit >= target(pool_id)
  end

  def is_target_achieved?(_), do: false

  defp notify_when_submitted(%Pool.SubmissionModel{} = submission, %Ecto.Changeset{} = changeset) do
    if Ecto.Changeset.get_change(changeset, :status) === :submitted do
      for user <- Accounts.list_pool_admins() do
        NextAction.Context.create_next_action(user, Pool.ReviewSubmission)
      end
    end

    submission
  end

  def get_tag(%Pool.SubmissionModel{status: status, submitted_at: submitted_at} = submission) do
    case {status, submitted_at} do
      {:idle, nil} ->
        %{text: dgettext("eyra-submission", "status.idle.label"), type: :tertiary}

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
