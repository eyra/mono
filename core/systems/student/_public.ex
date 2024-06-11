defmodule Systems.Student.Public do
  require Logger

  alias Ecto.Multi
  alias Core.Repo
  alias Systems.Account.User

  alias Frameworks.Utility.Identifier

  alias Systems.{
    Org,
    Budget,
    Bookkeeping,
    Pool,
    Student
  }

  @pool_director_key "student"

  def academic_year(), do: 2022
  def default_pool(), do: :vu_sbe_rpr_year1_2022

  def course_patterns(_user) do
    # FIXME: determine which pools are for the current user
    ["vu", ":#{academic_year()}"]
  end

  def successor?(
        %Org.NodeModel{identifier: finished_currency} = _finished_course,
        %Org.NodeModel{identifier: currency} = _course,
        current_year
      ) do
    successor?(finished_currency, currency, current_year)
  end

  def successor?([_ | _] = currency1, [_ | _] = currency2, current_year) do
    identifier1 =
      currency1
      |> remove_academic_year(current_year - 1)

    identifier2 =
      currency2
      |> remove_academic_year(current_year)

    identifier1 == identifier2
  end

  defp remove_academic_year([_ | _] = identifier, year) do
    List.delete(identifier, ":#{year}")
  end

  def list_pools(preload \\ []), do: Pool.Public.list_by_director(@pool_director_key, preload)

  def list_universities(template \\ [], preload \\ []) do
    Org.Public.list_nodes(:university, template, preload)
  end

  def list_faculties(template \\ [], preload \\ []) do
    Org.Public.list_nodes(:faculty, template, preload)
  end

  def list_programs(template \\ [], preload \\ []) do
    Org.Public.list_nodes(:student_program, template, preload)
  end

  def list_classes(_, preload \\ [])

  def list_classes(%User{} = user, preload) do
    Org.Public.list_nodes(user, :student_class, preload)
  end

  def list_classes(template, preload) do
    Org.Public.list_nodes(:student_class, template, preload)
  end

  def list_courses(_, preload \\ [])

  def list_courses(%User{} = user, preload) do
    Org.Public.list_nodes(user, :student_course, preload)
  end

  def list_courses(template, preload) do
    Org.Public.list_nodes(:student_course, template, preload)
  end

  def get_target(%{identifier: ["wallet", currency_name, _]}) do
    %{target: target} = Pool.Public.get_by_name(currency_name)
    target
  end

  def handle_features_updated(_user, nil, _new_class_codes), do: nil

  def handle_features_updated(user, old_class_codes, new_class_codes) do
    old_pool_names =
      old_class_codes
      |> Enum.map(&pool_name(&1))
      |> Enum.uniq()

    new_pool_names =
      new_class_codes
      |> Enum.map(&pool_name(&1))
      |> Enum.uniq()

    added_to_pools = new_pool_names -- old_pool_names
    deleted_from_pools = old_pool_names -- new_pool_names

    added_to_classes =
      (new_class_codes -- old_class_codes)
      |> map_to_student_class_nodes()

    deleted_from_classes =
      (old_class_codes -- new_class_codes)
      |> map_to_student_class_nodes()

    Multi.new()
    |> update_class_accociations(user, added_to_classes, deleted_from_classes)
    |> update_pool_participations(user, added_to_pools, deleted_from_pools)
    |> migrate_wallets(user, added_to_pools)
    |> Repo.transaction()
  end

  def migrate_wallets(multi, %User{} = user, added_to_pools) do
    multi
    |> Multi.run(:wallets, fn _, _ ->
      migrate_wallets(user, added_to_pools)
      {:ok, true}
    end)
  end

  def migrate_wallets(%User{} = user, added_to_pools) do
    added_to_pools
    |> Pool.Public.get_by_names()
    |> Enum.map(&migrate_wallet(user, &1))
  end

  def migrate_wallet(%User{id: user_id} = user, %Pool.Model{target: target, name: name}) do
    wallet = ["wallet", name, "#{user_id}"]
    previous_wallet = get_previous_wallet(wallet)
    migrate_wallet(user, previous_wallet, wallet, target)
  end

  defp migrate_wallet(_, nil, _, _), do: nil

  defp migrate_wallet(
         %{id: user_id},
         [_, last_year_currency, _] = last_year_wallet,
         [_, current_year_currency, _] = current_year_wallet,
         target
       ) do
    idempotence_key =
      "type=migrate_wallets,from=#{last_year_currency},to=#{current_year_currency},user=#{user_id}"

    Budget.Public.move_wallet_balance(
      last_year_wallet,
      current_year_wallet,
      idempotence_key,
      target
    )
  end

  defp get_previous_wallet([type, currency_name, user_id]) do
    current_year = get_year(currency_name)
    last_year_currency_name = replace_year(currency_name, current_year - 1)
    wallet = [type, last_year_currency_name, user_id]

    if Bookkeeping.Public.account_exists?(wallet) do
      wallet
    else
      nil
    end
  end

  defp get_year(currency_name) do
    currency_name
    |> String.split("_")
    |> List.last()
    |> String.to_integer()
  end

  defp replace_year(currency_name, year) do
    currency_name
    |> String.split("_")
    |> Enum.reverse()
    |> List.delete_at(0)
    |> List.insert_at(0, ":#{year}")
    |> Enum.reverse()
    |> Identifier.to_string()
  end

  def update_pool_participations(multi, %User{} = user, added_to_pools, deleted_from_pools) do
    multi
    |> Multi.run(:pool, fn _, _ ->
      update_pool_participations(user, added_to_pools, deleted_from_pools)
      {:ok, true}
    end)
  end

  def update_pool_participations(%User{} = user, added_to_pools, deleted_from_pools) do
    Pool.Public.update_pool_participations(user, added_to_pools, deleted_from_pools)
  end

  def update_class_accociations(multi, %User{} = user, added_to_classes, deleted_from_classes) do
    multi
    |> Multi.run(:added_to_classes, fn _, _ ->
      added_to_classes
      |> update_classes(user, :add)

      {:ok, true}
    end)
    |> Multi.run(:deleted_from_classes, fn _, _ ->
      deleted_from_classes
      |> update_classes(user, :delete)

      {:ok, true}
    end)
  end

  defp pool_name(class_code) do
    class_code
    |> Atom.to_string()
    |> Identifier.from_string(true)
    |> Org.Public.get_node([:links])
    |> Student.Class.get_course()
    |> Identifier.to_string()
  end

  def generate_vu(academic_year, study_year, en, nl, target) do
    rpr =
      create_org(
        :student_course,
        ["vu", "sbe", "rpr", ":year#{study_year}", ":#{academic_year}"],
        [{:en, "RPR #{en} year"}, {:nl, "RPR #{nl} jaar"}],
        [{:en, "RPR #{en} year (#{academic_year})"}, {:nl, "RPR #{nl} jaar (#{academic_year})"}]
      )

    bk =
      create_org(
        :student_class,
        ["vu", "sbe", "bk", ":year#{study_year}", ":#{academic_year}"],
        [{:en, "BK #{en} year"}, {:nl, "BK #{nl} jaar"}],
        [{:en, "BK #{en} year (#{academic_year})"}, {:nl, "BK #{nl} jaar (#{academic_year})"}]
      )

    iba =
      create_org(
        :student_class,
        ["vu", "sbe", "iba", ":year#{study_year}", ":#{academic_year}"],
        [{:en, "IBA #{en} year"}, {:nl, "IBA #{nl} jaar"}],
        [{:en, "IBA #{en} year (#{academic_year})"}, {:nl, "IBA #{nl} jaar (#{academic_year})"}]
      )

    create_link(bk, rpr)
    create_link(iba, rpr)

    pool_name = "vu_sbe_rpr_year#{study_year}_#{academic_year}"

    %{currency: currency} =
      create_currency_and_budget!(pool_name, [{:en, "%{amount} credit", "%{amount} credits"}])

    create_pool(target, pool_name, currency, rpr)
  end

  defp create_pool(target, name, currency, org) do
    case Pool.Public.get_by_name(name) do
      nil -> Pool.Public.create!(name, target, currency, org, :student)
      pool -> pool
    end
  end

  defp create_currency_and_budget!(name, label) do
    case Budget.Public.get_by_name(name, [:currency]) do
      nil -> Budget.Public.create_currency_and_budget(name, {:emoji, "🏫"}, :virtual, 0, label)
      budget -> budget
    end
  end

  defp create_org(type, identifier, short_name, full_name) do
    case Org.Public.get_node(identifier) do
      nil -> Org.Public.create_node!(type, identifier, short_name, full_name)
      node -> node
    end
  end

  defp create_link(org1, org2) do
    case Org.Public.get_link(org1, org2) do
      nil -> Org.Public.create_link!(org1, org2)
      link -> link
    end
  end

  defp update_classes([_ | _] = class_nodes, user, command) do
    class_nodes
    |> Enum.map(&update_class(&1, user, command))
  end

  defp update_classes(_, _, _), do: nil

  defp update_class(class, user, :add), do: Org.Public.add_user(class, user)
  defp update_class(class, user, :delete), do: Org.Public.delete_user(class, user)

  defp map_to_student_class_nodes(codes) do
    codes
    |> Enum.map(&student_class_node(&1))
    |> Enum.uniq()
  end

  defp student_class_node(code) when is_atom(code), do: student_class_node(Atom.to_string(code))
  defp student_class_node(code), do: Identifier.from_string(code, true)
end
