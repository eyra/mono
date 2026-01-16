defmodule Core.Repo.Migrations.RefactorPoolsPart4 do
  use Ecto.Migration

  import Ecto.Adapters.SQL

  def up do
    migrate_study_program_codes()
  end

  defp migrate_study_program_codes() do
    query_all(:user_features, "id, study_program_codes")
    |> Enum.map(&migrate_study_program_codes(&1, :user_features))

    query_all(:eligibility_criteria, "id, study_program_codes")
    |> Enum.map(&migrate_study_program_codes(&1, :eligibility_criteria))
  end

  defp migrate_study_program_codes([_id, study_program_codes] = object, table) do
    new_study_program_codes =
      translate(study_program_codes)

    migrate_study_program_codes(object, table, new_study_program_codes)
  end

  defp migrate_study_program_codes(_, _, nil), do: nil

  defp migrate_study_program_codes([id, study_program_codes], table, new_study_program_codes) do
    if study_program_codes != new_study_program_codes do
      new_study_program_codes = new_study_program_codes |> array_to_db_string()
      IO.puts("UPDATE #{table}: #{new_study_program_codes}")
      update(table, id, :study_program_codes, new_study_program_codes)
    end
  end

  defp translate(study_program_codes) when is_list(study_program_codes) do
    study_program_codes
    |> Enum.map(&translate(&1))
  end

  defp translate("bk_1"), do: "vu_sbe_bk_year1_2021"
  defp translate("bk_1_h"), do: "vu_sbe_bk_year1_resit_2021"
  defp translate("bk_2"), do: "vu_sbe_bk_year1_2021"
  defp translate("bk_2_h"), do: "vu_sbe_bk_year1_resit_2021"
  defp translate("iba_1"), do: "vu_sbe_iba_year1_2021"
  defp translate("iba_1_h"), do: "vu_sbe_iba_year1_resit_2021"
  defp translate("iba_2"), do: "vu_sbe_iba_year1_2021"
  defp translate("iba_2_h"), do: "vu_sbe_iba_year1_resit_2021"

  defp translate("vu_sbe_bk_1"), do: "vu_sbe_bk_year1_2021"
  defp translate("vu_sbe_bk_1_h"), do: "vu_sbe_bk_year1_resit_2021"
  defp translate("vu_sbe_bk_2"), do: "vu_sbe_bk_year2_2021"
  defp translate("vu_sbe_bk_2_h"), do: "vu_sbe_bk_year2_resit_2021"
  defp translate("vu_sbe_iba_1"), do: "vu_sbe_iba_year1_2021"
  defp translate("vu_sbe_iba_1_h"), do: "vu_sbe_iba_year1_resit_2021"
  defp translate("vu_sbe_iba_2"), do: "vu_sbe_iba_year2_2021"
  defp translate("vu_sbe_iba_2_h"), do: "vu_sbe_iba_year2_resit_2021"

  defp translate(code), do: code

  def down do
  end

  defp query_all(table, fields) do
    {:ok, %{rows: rows}} =
      query(Core.Repo, "SELECT #{fields} FROM #{table}")

    rows
  end

  defp update(table, id, field, value) when is_binary(value) do
    execute("""
    UPDATE #{table} SET #{field} = '#{value}' WHERE id = #{id};
    """)
  end

  defp array_to_db_string(nil), do: nil

  defp array_to_db_string(array) when is_list(array) do
    result =
      array
      |> Enum.join(",")

    "{#{result}}"
  end
end
