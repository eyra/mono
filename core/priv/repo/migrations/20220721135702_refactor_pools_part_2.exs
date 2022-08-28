defmodule Core.Repo.Migrations.RefactorPoolsPart2 do
  use Ecto.Migration

  import Ecto.Adapters.SQL

  @old_sbe_pool "sbe_2021"

  @fake_currency %{
    name: "eyra_fake",
    decimal_scale: 2,
    target: 100,
    label: [
      %{
        locale: :en,
        text: "ƒ%{amount}",
        text_plural: "ƒ%{amount}"
      }
    ]
  }

  @rpr_year1_2021 %{
    name: "vu_sbe_rpr_year1_2021",
    target: 60,
    decimal_scale: 0,
    label: [
      %{
        locale: :nl,
        text: "%{amount} credit",
        text_plural: "%{amount} credits"
      },
      %{
        locale: :en,
        text: "%{amount} credit",
        text_plural: "%{amount} credits"
      }
    ]
  }

  @rpr_year2_2021 %{
    name: "vu_sbe_rpr_year2_2021",
    decimal_scale: 0,
    target: 30,
    label: [
      %{
        locale: :nl,
        text: "%{amount} credit",
        text_plural: "%{amount} credits"
      },
      %{
        locale: :en,
        text: "%{amount} credit",
        text_plural: "%{amount} credits"
      }
    ]
  }


  ########## UP ##########

  def up do
    rename_accounts()

    add_organisations()
    add_currency(@fake_currency)
    add_pool(@fake_currency, query_org("eyra"))

    add_currencies([@rpr_year1_2021, @rpr_year2_2021])
    add_pool(@rpr_year1_2021, query_org(["vu", "sbe", "rpr", ":year1", ":2021"]))
    add_pool(@rpr_year2_2021, query_org(["vu", "sbe", "rpr", ":year2", ":2021"]))

    migrate_submissions()
    migrate_students()
  end

  defp rename_accounts() do
    query_all(:book_accounts, "id, identifier")
    |> Enum.each(&rename_account(&1))
  end

  defp rename_account([account_id, identifier]) when is_list(identifier) do
    new_identifier = replace_currency(identifier) |> array_to_db_string()
    update(:book_accounts, account_id, :identifier, new_identifier)
  end

  defp replace_currency("sbe_year1_2021"), do: "vu_sbe_rpr_year1_2021"
  defp replace_currency("sbe_year2_2021"), do: "vu_sbe_rpr_year2_2021"
  defp replace_currency(term) when is_binary(term), do: term

  defp replace_currency([h | t]) do
    [replace_currency(h)] ++ replace_currency(t)
  end
  defp replace_currency(_), do: []


  defp query_org(identifier) when is_binary(identifier), do: query_org([identifier])
  defp query_org(identifier) when is_list(identifier) do
    org_identifier = identifier |> array_to_db_string()
    query_id(:org_nodes, "identifier = '#{org_identifier}'")
  end

  defp add_organisations() do
    _eyra = add_node(:company, "eyra", [{:en, "Eyra"}], [{:en, "Eyra"}])
    _eyra_leap = add_node(:department, "eyra/leap", [{:en, "Eyra Leap"}], [{:en, "Eyra Leap"}])
    _vu = add_node(:university, "vu", [{:en, "VU"}], [{:en, "VU Amsterdam"}])
    _vu_sbe = add_node(:faculty, "vu/sbe", [{:en, "SBE"}], [{:en, "School of Business and Economics"}])
    _vu_bk = add_node(:scholar_program, "vu/sbe/bk", [{:en, "BK"}], [{:nl, "Bedrijfskunde"}])
    _vu_iba = add_node(:scholar_program, "vu/sbe/iba", [{:en, "IBA"}], [{:en, "International Business Administration"}])

    rpr_1_2021 = add_node(:scholar_course, "vu/sbe/rpr/:year1/:2021", [{:en, "RPR 1st year"}, {:nl, "RPR 1e jaar"}], [{:en, "RPR 1st year (2021)"}, {:nl, "RPR 1e jaar (2021)"}])
    rpr_2_2021 = add_node(:scholar_course, "vu/sbe/rpr/:year2/:2021", [{:en, "RPR 2nd year"}, {:nl, "RPR 2e jaar"}], [{:en, "RPR 2nd year (2021)"}, {:nl, "RPR 2e jaar (2021)"}])

    bk_1_2021 = add_node(:scholar_class, "vu/sbe/bk/:year1/:2021", [{:en, "BK 1st year"}, {:nl, "BK 1e jaar"}], [{:en, "BK 1st year (2021)"}, {:nl, "BK 1e jaar (2021)"}])
    bk_1_h_2021 = add_node(:scholar_class, "vu/sbe/bk/:year1/:resit/:2021", [{:en, "BK 1st year (re-sit)"}, {:nl, "BK 1e jaar (herkansing)"}], [{:en, "BK 1st year (resit, 2021)"}, {:nl, "BK 1e jaar (herkansing, 2021)"}])
    bk_2_2021 = add_node(:scholar_class, "vu/sbe/bk/:year2/:2021", [{:en, "BK 2nd year"}, {:nl, "BK 2e jaar"}], [{:en, "BK 2nd year (2021)"}, {:nl, "BK 2e jaar (2021)"}])
    bk_2_h_2021 = add_node(:scholar_class, "vu/sbe/bk/:year2/:resit/:2021", [{:en, "BK 2nd year (re-sit)"}, {:nl, "BK 2e jaar (herkansing)"}], [{:en, "BK 2nd year (re-sit, 2021)"}, {:nl, "BK 2e jaar (herkansing, 2021)"}])

    iba_1_2021 = add_node(:scholar_class, "vu/sbe/iba/:year1/:2021", [{:en, "IBA 1st year"}, {:nl, "IBA 1e jaar"}], [{:en, "IBA 1st year (2021)"}, {:nl, "IBA 1e jaar (2021)"}])
    iba_1_h_2021 = add_node(:scholar_class, "vu/sbe/iba/:year1/:resit/:2021", [{:en, "IBA 1st year (re-sit)"}, {:nl, "IBA 1e jaar (herkansing)"}], [{:en, "IBA 1st year (resit, 2021)"}, {:nl, "BK 1e jaar (herkansing, 2021)"}])
    iba_2_2021 = add_node(:scholar_class, "vu/sbe/iba/:year2/:2021", [{:en, "IBA 2nd year"}, {:nl, "IBA 2e jaar"}], [{:en, "IBA 2nd year (2021)"}, {:nl, "IBA 2e jaar (2021)"}])
    iba_2_h_2021 = add_node(:scholar_class, "vu/sbe/iba/:year2/:resit/:2021", [{:en, "IBA 2nd year (re-sit)"}, {:nl, "BK 2e jaar (herkansing)"}], [{:en, "IBA 2nd year (re-sit, 2021)"}, {:nl, "IBA 2e jaar (herkansing, 2021)"}])

    [bk_1_2021, bk_1_h_2021, iba_1_2021, iba_1_h_2021]
    |> Enum.each(&add_link(&1, rpr_1_2021))

    [bk_2_2021, bk_2_h_2021, iba_2_2021, iba_2_h_2021]
    |> Enum.each(&add_link(&1, rpr_2_2021))
  end

  defp add_node(type, identifier, short_name, full_name) when is_list(short_name) and is_list(full_name) do
    short_name_bundle_id = add_text_bundle()
    full_name_bundle_id = add_text_bundle()

    add_text_items(translate(short_name), short_name_bundle_id)
    add_text_items(translate(full_name), full_name_bundle_id)

    add_node(type, identifier, short_name_bundle_id, full_name_bundle_id)
  end

  defp add_node(type, identifier, short_name, full_name) when is_binary(identifier) do
    identifier =
      identifier
      |> String.split("/")

    add_node(type, identifier, short_name, full_name)
  end

  defp add_node(type, identifier, short_name_bundle_id, full_name_bundle_id) when is_list(identifier) do
    identifier = array_to_db_string(identifier)

    if not exist?(:org_nodes, "identifier = '#{identifier}'") do
      execute(
        """
        INSERT INTO org_nodes (type, identifier, short_name_bundle_id, full_name_bundle_id, inserted_at, updated_at)
        VALUES ('#{type}', '#{identifier}', #{short_name_bundle_id}, #{full_name_bundle_id}, '#{now()}', '#{now()}')
        """
      )
        flush()
    end
    query_id(:org_nodes, "identifier = '#{identifier}'")
  end

  defp add_link(from_id, to) when is_list(to) do
    to |> Enum.each(&add_link(from_id, &1))
  end

  defp add_link(from_id, to_id) do
    if not exist?(:org_links, "from_id = #{from_id} and to_id = #{to_id}") do
      execute(
        """
        INSERT INTO org_links (from_id, to_id, inserted_at, updated_at)
        VALUES (#{from_id}, #{to_id}, '#{now()}', '#{now()}')
        """
      )
      flush()
      query_id(:org_nodes, "id = CURRVAL('org_nodes_id_seq')")
    end
  end

  defp translate(items) when is_list(items), do: Enum.map(items, &translate(&1))
  defp translate({:en, text}), do: %{locale: :en, text: text}
  defp translate({:nl, text}), do: %{locale: :nl, text: text}

  defp migrate_students() do
    query_all(:users, "id", "student = true")
    |> Enum.each(&migrate_student(&1))
  end

  defp migrate_student([user_id]) do
    study_program_codes =
      query_field(:user_features, :study_program_codes, "user_id = #{user_id}")

    study_program_codes
    |> get_years()
    |> get_pool_names()
    |> Enum.each(&link_student_pool(user_id, &1))

    study_program_codes
    |> Enum.each(&link_student_class(user_id, &1))

    flush()
  end

  defp migrate_submissions() do
    if exist?(:pools, "name = '#{@old_sbe_pool}'") do
      pool_id = query_id(:pools, "name = '#{@old_sbe_pool}'")
      query_all(:pool_submissions, "id, promotion_id", "pool_id = #{pool_id}")
      |> Enum.each(&migrate_submission(&1))
    end
  end

  defp migrate_submission([_submission_id, nil]), do: nil

  defp migrate_submission([submission_id, promotion_id]) do
    campaign_id = query_id(:campaigns, "promotion_id = #{promotion_id}")
    link_campaign_submission(campaign_id, submission_id)
    link_pool_submission(submission_id)

    flush()
  end

  defp link_student_pool(user_id, pool_name) do
    pool_id = query_id(:pools, "name = '#{pool_name}'")

    execute(
      """
      INSERT INTO pool_participants (pool_id, user_id, inserted_at, updated_at)
      VALUES ('#{pool_id}', '#{user_id}', '#{now()}', '#{now()}')
      ON CONFLICT ON CONSTRAINT pool_participants_pkey DO NOTHING;
      """
    )
  end

  defp link_student_class(user_id, "bk_1"), do: link_student_org(user_id, "vu/sbe/bk/:year1/:2021")
  defp link_student_class(user_id, "bk_1_h"), do: link_student_org(user_id, "vu/sbe/bk/:year1/:resit/:2021")
  defp link_student_class(user_id, "bk_2"), do: link_student_org(user_id, "vu/sbe/bk/:year2/:2021")
  defp link_student_class(user_id, "bk_2_h"), do: link_student_org(user_id, "vu/sbe/bk/:year2/:resit/:2021")
  defp link_student_class(user_id, "iba_1"), do: link_student_org(user_id, "vu/sbe/iba/:year1/:2021")
  defp link_student_class(user_id, "iba_1_h"), do: link_student_org(user_id, "vu/sbe/iba/:year1/:resit/:2021")
  defp link_student_class(user_id, "iba_2"), do: link_student_org(user_id, "vu/sbe/iba/:year2/:2021")
  defp link_student_class(user_id, "iba_2_h"), do: link_student_org(user_id, "vu/sbe/iba/:year2/:resit/:2021")

  defp link_student_org(user_id, identifier) do
    identifier =
      identifier
      |> String.split("/")
      |> array_to_db_string()

    class_id = query_id(:org_nodes, "identifier = '#{identifier}'")

    if not exist?(:org_users, "org_id = #{class_id} AND user_id = #{user_id}") do
      execute(
        """
        INSERT INTO org_users (org_id, user_id, inserted_at, updated_at)
        VALUES ('#{class_id}', '#{user_id}', '#{now()}', '#{now()}')
        """
      )
      flush()
    end
  end

  defp link_campaign_submission(campaign_id, submission_id) do
    execute(
      """
      INSERT INTO campaign_submissions (campaign_id, submission_id, inserted_at, updated_at)
      VALUES ('#{campaign_id}', '#{submission_id}', '#{now()}', '#{now()}')
      """
    )
  end

  defp link_pool_submission(submission_id) do
    pool_name =
      get_study_program_codes(submission_id)
      |> get_year()
      |> get_pool_name()

    pool_id = query_id(:pools, "name = '#{pool_name}'")
    update(:pool_submissions, submission_id, :pool_id, pool_id)
    IO.puts("Update submission #{submission_id} -> pool #{pool_name} ##{pool_id}")
  end

  defp get_study_program_codes(submission_id) do
    query_field(:eligibility_criteria, :study_program_codes, "submission_id = #{submission_id}")
  end

  defp array_to_db_string(array) do
    result =
      array
      |> Enum.join(",")

    "{#{result}}"
  end

  defp get_years([_ | _] = study_program_codes) do
    study_program_codes
    |> Enum.map(&get_year([&1]))
  end
  defp get_years(_), do: []

  defp get_year([code| _]) do
    if code |> String.contains?("1") do
      :first
    else
      :second
    end
  end
  defp get_year(_), do: nil

  defp get_pool_names([_ | _] = years) do
    years
    |> Enum.map(&get_pool_name(&1))
  end

  defp get_pool_names(_), do: []

  defp get_pool_name(:first), do: "vu_sbe_rpr_year1_2021"
  defp get_pool_name(:second), do: "vu_sbe_rpr_year2_2021"

  defp add_pools(currencies, org_id) do
    currencies
    |> Enum.each(&add_pool(&1, org_id))
  end

  defp add_pool(%{name: currency_name, target: target} = _currency, org_id) do
    add_pool(currency_name, currency_name, org_id, target)
  end

  defp add_pool(pool_name, currency_name, org_id, target) when is_binary(currency_name) do
    currency_id = query_id(:currencies, "name = '#{currency_name}'")
    if exist?(:pools, :name, pool_name) do
      pool_id = query_id(:pools, "name = '#{pool_name}'")
      update(:pools, pool_id, :currency_id, currency_id)
      update(:pools, pool_id, :org_id, org_id)
      update(:pools, pool_id, :target, target)
    else
      add_pool(pool_name, currency_id, org_id, target)
    end
  end

  defp add_pool(name, currency_id, org_id, target) when is_integer(currency_id) do
    if not exist?(:pools, :name, name) do
      execute(
        """
        INSERT INTO pools (name, target, currency_id, org_id, inserted_at, updated_at)
        VALUES ('#{name}', #{target}, '#{currency_id}', '#{org_id}', '#{now()}', '#{now()}')
        """
      )
      flush()
    end
  end

  defp add_currencies(currencies) when is_list(currencies) do
    currencies
    |> Enum.each(&add_currency(&1))
  end

  defp add_currency(%{name: name, decimal_scale: decimal_scale, label: label} = _currency) do
    if not exist?(:currencies, :name, name) do
      label_bundle_id = add_text_bundle()
      add_text_items(label, label_bundle_id)
      add_currency(name, decimal_scale, label_bundle_id)
    end
  end

  defp add_currency(name, decimal_scale, label_bundle_id) do
    if not exist?(:currencies, :name, name) do
      execute(
        """
        INSERT INTO currencies (name, decimal_scale, label_bundle_id, inserted_at, updated_at)
        VALUES ('#{name}', #{decimal_scale}, '#{label_bundle_id}', '#{now()}', '#{now()}')
        """
      )
      flush()
      query_id(:currencies, "id = CURRVAL('currencies_id_seq')")
    end
  end

  defp add_text_bundle() do
    execute(
      """
      INSERT INTO text_bundles (inserted_at, updated_at)
      VALUES ('#{now()}', '#{now()}');
      """
    )
    flush()
    query_id(:text_bundles, "id = CURRVAL('text_bundles_id_seq')")
  end

  defp add_text_items(items, bundle_id) do
    Enum.each(items, &add_text_item(&1, bundle_id))
  end

  defp add_text_item(%{locale: locale, text: text, text_plural: text_plural}, bundle_id) do
    execute(
      """
      INSERT INTO text_items (locale, text, text_plural, bundle_id, inserted_at, updated_at)
      VALUES ('#{locale}', '#{text}', '#{text_plural}', '#{bundle_id}', '#{now()}', '#{now()}');
      """
    )
    flush()
  end

  defp add_text_item(%{locale: locale, text: text}, bundle_id) do
    execute(
      """
      INSERT INTO text_items (locale, text, bundle_id, inserted_at, updated_at)
      VALUES ('#{locale}', '#{text}', '#{bundle_id}', '#{now()}', '#{now()}');
      """
    )
    flush()
  end

  ########## DOWN ##########

  def down do
    rollback_submissions()
    rollback_pools()
  end

  defp rollback_pools() do
    execute(
      """
      DELETE FROM pools WHERE name != '#{@old_sbe_pool}';
      """
    )
    flush()
  end

  defp rollback_submissions() do
    query_all(:pool_submissions, "id")
    |> Enum.each(&rollback_submission(&1))
  end

  defp rollback_submission([submission_id]) do
    unlink_pool_submission(submission_id)
  end

  defp unlink_pool_submission(submission_id) do
    pool_id = query_id(:pools, "name = '#{@old_sbe_pool}'")
    update(:pool_submissions, submission_id, :pool_id, pool_id)
  end

  ########## HELPERS ##########

  def exist?(table, field, value) when is_atom(value) do
    exist?(table, "#{field} = '#{value}'")
  end

  def exist?(table, field, value) when is_binary(value) do
    exist?(table, "#{field} = '#{value}'")
  end

  def exist?(table, field, value) do
    exist?(table, "#{field} = #{value}")
  end

  def exist?(table, where) do
    {:ok, %{ rows: [[count]] }} =
      query(Core.Repo, "SELECT count(*) FROM #{table} WHERE #{where};")

    count > 0
  end

  defp update(table, id, field, value) when is_number(value)do
    execute(
    """
    UPDATE #{table} SET #{field} = #{value} WHERE id = #{id};
    """
    )
  end

  defp update(table, id, field, value) when is_binary(value)do
    execute(
    """
    UPDATE #{table} SET #{field} = '#{value}' WHERE id = #{id};
    """
    )
  end

  defp query_id(table, where) do
    query_field(table, :id, where)
  end

  defp query_field(table, field, where) do
    {:ok, %{rows: [[id]|_]}} =
      query(Core.Repo, "SELECT #{field} FROM #{table} WHERE #{where}")

    id
  end

  defp query_all(table, fields, where) do
    {:ok, %{rows: rows}} =
      query(Core.Repo, "SELECT #{fields} FROM #{table} WHERE #{where}")

    rows
  end

  defp query_all(table, fields) do
    {:ok, %{rows: rows}} =
      query(Core.Repo, "SELECT #{fields} FROM #{table}")

    rows
  end

  defp now() do
    DateTime.now!("Etc/UTC")
    |> DateTime.to_naive()
  end


end
