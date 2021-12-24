defmodule Core.Repo.Migrations.RemoveContentNodeNullConstraint do
  use Ecto.Migration

  @tables [:lab_tools, :survey_tools, :data_donation_tools, :promotions, :pool_submissions]

  def up do
    @tables
    |> Enum.each(&make_content_node_null(&1, :true))
  end

  def down do
    @tables
    |> Enum.each(&make_content_node_null(&1, :false))
  end

  defp make_content_node_null(table, value) do
    drop constraint(table, String.to_atom("#{table}_content_node_id_fkey"))

    alter table(table) do
      modify(:content_node_id, references(:content_nodes), null: value)
    end
  end

end
