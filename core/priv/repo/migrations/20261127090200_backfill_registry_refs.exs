defmodule Mica.Repo.Migrations.BackfillRegistryRefs do
  @moduledoc """
  code-registry, release 1: fills `tool_type`/`tool_id` and `item_type`/`item_id`
  from the per-type columns, with the same mapping as the sync trigger.

  It refuses to run if a row sets two or more per-type columns: that row's type
  would be a guess. A row that sets none gets the reserved type `none` and no id;
  nothing is deleted. On production (17 Nov 2026) that is 6 tool refs, left from the
  `data_donation_tool_id` column that `20230711100350` removed, and no project item.

  Only rows without a type are touched, so it can run again. Its down is a no-op:
  `AddRegistryRefs.down/0` drops the columns.
  """
  use Ecto.Migration

  def up do
    execute("""
    DO $$
    DECLARE bad bigint;
    BEGIN
      SELECT count(*) INTO bad FROM tool_refs
      WHERE (alliance_tool_id IS NOT NULL)::int + (document_tool_id IS NOT NULL)::int
          + (feldspar_tool_id IS NOT NULL)::int + (graphite_tool_id IS NOT NULL)::int
          + (instruction_tool_id IS NOT NULL)::int + (lab_tool_id IS NOT NULL)::int
          + (manual_tool_id IS NOT NULL)::int + (zircon_screening_tool_id IS NOT NULL)::int > 1;
      IF bad > 0 THEN RAISE EXCEPTION 'tool_refs: % rows set 2+ tool columns', bad; END IF;

      SELECT count(*) INTO bad FROM project_items
      WHERE (assignment_id IS NOT NULL)::int + (advert_id IS NOT NULL)::int
          + (leaderboard_id IS NOT NULL)::int + (storage_endpoint_id IS NOT NULL)::int > 1;
      IF bad > 0 THEN RAISE EXCEPTION 'project_items: % rows set 2+ item columns', bad; END IF;
    END $$
    """)

    execute("""
    UPDATE tool_refs SET
      tool_type = coalesce(CASE
        WHEN alliance_tool_id IS NOT NULL THEN 'alliance'
        WHEN document_tool_id IS NOT NULL THEN 'document'
        WHEN feldspar_tool_id IS NOT NULL THEN 'feldspar'
        WHEN graphite_tool_id IS NOT NULL THEN 'graphite'
        WHEN instruction_tool_id IS NOT NULL THEN 'instruction'
        WHEN lab_tool_id IS NOT NULL THEN 'lab'
        WHEN manual_tool_id IS NOT NULL THEN 'manual'
        WHEN zircon_screening_tool_id IS NOT NULL THEN 'zircon_screening'
      END, 'none'),
      tool_id = coalesce(alliance_tool_id, document_tool_id, feldspar_tool_id, graphite_tool_id,
        instruction_tool_id, lab_tool_id, manual_tool_id, zircon_screening_tool_id)
    WHERE tool_type IS NULL
    """)

    execute("""
    UPDATE project_items SET
      item_type = coalesce(CASE
        WHEN assignment_id IS NOT NULL THEN 'assignment'
        WHEN advert_id IS NOT NULL THEN 'advert'
        WHEN leaderboard_id IS NOT NULL THEN 'leaderboard'
        WHEN storage_endpoint_id IS NOT NULL THEN 'storage_endpoint'
      END, 'none'),
      item_id = coalesce(assignment_id, advert_id, leaderboard_id, storage_endpoint_id)
    WHERE item_type IS NULL
    """)
  end

  def down, do: :ok
end
