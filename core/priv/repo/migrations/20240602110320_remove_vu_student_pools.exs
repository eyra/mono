defmodule Core.Repo.Migrations.RemoveVuStudentPools do
  use Ecto.Migration

  def change do
    delete_vu_pools(["eyra_fake", "vu_sbe_rpr_year1_2021", "vu_sbe_rpr_year2_2021"])
  end

  defp delete_vu_pools(pool_names) do
    pool_names |> Enum.each(&delete_vu_pool/1)
    flush()
  end

  defp delete_vu_pool(pool_name) do
    execute("""
    DELETE FROM pools WHERE name = '#{pool_name}';
    """)
  end
end
