defmodule Core.Pools do
  import Ecto.Query

  alias Core.Pools.{Pool, Criteria}
  alias Core.Repo
  alias Core.Accounts.User

  def list() do
    ensure_student_pool()
    Repo.all(Pool)
  end

  def get!(id), do: Repo.get!(Pool, id)
  def get(id), do: Repo.get(Pool, id)

  def get_by_name(name) when is_atom(name), do: get_by_name(Atom.to_string(name))

  def get_by_name(name) do
    ensure_student_pool()
    Repo.get_by(Pool, name: name)
  end

  defp ensure_student_pool() do
    case Repo.get_by(Pool, name: "vu_students") do
      nil -> create_student_pool()
      pool -> {:ok, pool}
    end
  end

  defp create_student_pool() do
    %Pool{name: "vu_students"}
    |> Repo.insert!()
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
        %Criteria{
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
    |> optional_where(:genders, genders)
    |> optional_where(:dominant_hands, dominant_hands)
    |> optional_where(:native_languages, native_languages)
    |> Repo.one()
  end

  defp query_count_eligitable_users(study_program_codes, exclude) do
    from(user in User,
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

  defp optional_where(query, :genders, values) do
    query
    |> where([user, features], is_nil(features.gender) or features.gender in ^values)
  end

  defp optional_where(query, :dominant_hands, values) do
    query
    |> where(
      [user, features],
      is_nil(features.dominant_hand) or features.dominant_hand in ^values
    )
  end

  defp optional_where(query, :native_languages, values) do
    query
    |> where(
      [user, features],
      is_nil(features.native_language) or features.native_language in ^values
    )
  end
end
