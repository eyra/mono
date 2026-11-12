defmodule Mica.Repo.Migrations.AddRequiredToWorkflowItems do
  @moduledoc """
  Adds `workflow_items.required`: only required items count when deciding whether a
  participant finished their tasks. The data donation template adds its manuals as not
  required; this turns them off in existing data donation workflows too.
  """
  use Ecto.Migration

  def up do
    alter table(:workflow_items) do
      add(:required, :boolean, null: false, default: true)
    end

    flush()

    execute("""
    UPDATE workflow_items AS item
    SET required = false
    FROM tool_refs AS tool_ref, assignments AS assignment
    WHERE tool_ref.id = item.tool_ref_id
      AND assignment.workflow_id = item.workflow_id
      AND assignment.special = 'data_donation'
      AND tool_ref.special IN ('manual', 'request_manual', 'download_manual')
    """)
  end

  def down do
    alter table(:workflow_items) do
      remove(:required)
    end
  end
end
