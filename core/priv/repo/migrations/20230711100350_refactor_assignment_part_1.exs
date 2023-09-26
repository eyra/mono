defmodule Core.Repo.Migrations.RefactorAssignmentPart1 do
  use Ecto.Migration

  def up do
    drop(constraint(:authorization_nodes, "authorization_nodes_parent_id_fkey"))

    alter table(:authorization_nodes) do
      modify(:parent_id, references(:authorization_nodes, on_delete: :nilify_all))
    end

    drop(constraint(:campaigns, "campaigns_promotion_id_fkey"))
    drop(constraint(:campaigns, "campaigns_promotable_assignment_id_fkey"))

    alter table(:campaigns) do
      modify(:promotion_id, references(:promotions, on_delete: :nothing))
      modify(:promotable_assignment_id, references(:assignments, on_delete: :nothing))
    end

    alter table(:crew_tasks) do
      remove(:member_id)
      add(:identifier, {:array, :string}, null: false)
      add(:auth_node_id, references(:authorization_nodes), null: false)
    end

    create(unique_index(:crew_tasks, :identifier))

    alter table(:users) do
      add(:type, :string, null: false, default: "identified")
      add(:external_id, :string, null: true)
    end

    create table(:feldspar_tools) do
      add(:archive_name, :string)
      add(:archive_ref, :string)
      add(:director, :string, null: true)
      add(:auth_node_id, references(:authorization_nodes), null: false)
      timestamps()
    end

    create table(:document_tools) do
      add(:name, :string)
      add(:ref, :string)
      add(:director, :string, null: true)
      add(:auth_node_id, references(:authorization_nodes), null: false)
      timestamps()
    end

    create table(:alliance_tools) do
      add(:url, :string)
      add(:next_participant_id, :bigint, default: 0)
      add(:director, :string, null: true)
      add(:auth_node_id, references(:authorization_nodes), null: false)
      timestamps()
    end

    create table(:alliance_tool_participants) do
      add(:participant_id, :bigint)
      add(:alliance_tool_id, references(:alliance_tools, on_delete: :delete_all))
      add(:user_id, references(:users, on_delete: :delete_all))
      timestamps()
    end

    execute("""
    CREATE OR REPLACE FUNCTION set_alliance_tool_participants_participant_id()
        RETURNS TRIGGER AS $$
    BEGIN
      UPDATE alliance_tools INTO NEW.participant_id
        SET next_participant_id=next_participant_id+1 WHERE alliance_tools.id=NEW.alliance_tool_id RETURNING next_participant_id;

      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER alliance_tool_participants_participant_id
    BEFORE INSERT ON alliance_tool_participants
    FOR EACH ROW EXECUTE FUNCTION set_alliance_tool_participants_participant_id();
    """)

    create(unique_index(:alliance_tool_participants, [:alliance_tool_id, :user_id]))

    create table(:workflows) do
      add(:type, :string)
      timestamps()
    end

    create table(:workflow_items) do
      add(:group, :string)
      add(:position, :integer)
      add(:title, :string)
      add(:description, :string)

      add(:workflow_id, references(:workflows, on_delete: :nothing), null: false)
      add(:tool_ref_id, references(:tool_refs, on_delete: :nothing), null: false)

      timestamps()
    end

    drop(constraint(:tool_refs, :must_have_at_least_one_tool))

    alter table(:tool_refs) do
      remove(:data_donation_tool_id)
      remove(:questionnaire_tool_id)

      add(:special, :string)

      add(:feldspar_tool_id, references(:feldspar_tools, on_delete: :delete_all), null: true)
      add(:document_tool_id, references(:document_tools, on_delete: :delete_all), null: true)
      add(:alliance_tool_id, references(:alliance_tools, on_delete: :delete_all), null: true)
    end

    create(
      constraint(:tool_refs, :must_have_at_least_one_tool,
        check: """
        alliance_tool_id != null or
        feldspar_tool_id != null or
        document_tool_id != null or
        lab_tool_id != null or
        benchmark_tool_id != null
        """
      )
    )

    create table(:assignment_info) do
      add(:subject_count, :integer)
      add(:duration, :string)
      add(:language, :string)
      add(:devices, {:array, :string})
      add(:ethical_approval, :boolean)
      add(:ethical_code, :string)

      timestamps()
    end

    drop(constraint(:assignments, "assignments_crew_id_fkey"))
    drop(constraint(:assignments, "assignments_budget_id_fkey"))

    alter table(:assignments) do
      modify(:budget_id, references(:budgets, on_delete: :nothing))
      modify(:crew_id, references(:crews, on_delete: :nothing))
      add(:info_id, references(:assignment_info, on_delete: :nothing), null: true)
      add(:workflow_id, references(:workflows, on_delete: :nothing), null: true)
      add(:special, :string)
      add(:status, :string)

      remove(:assignable_survey_tool_id)
      remove(:assignable_lab_tool_id)
      remove(:assignable_data_donation_tool_id)
      remove(:assignable_experiment_id)
    end

    drop(constraint(:project_items, :project_items_tool_ref_id_fkey))

    alter table(:project_items) do
      add(:assignment_id, references(:assignments, on_delete: :delete_all), null: true)
      modify(:tool_ref_id, references(:tool_refs, on_delete: :delete_all), null: true)
    end

    create(
      constraint(:project_items, :must_have_at_least_one_reference,
        check: """
        tool_ref_id != null or
        assignment_id != null
        """
      )
    )

    # drop table(:data_donation_user_data)
    # drop table(:data_donation_participants)
    # drop table(:data_donation_tasks)
    # drop table(:data_donation_questionnaire_tasks)
    # drop table(:data_donation_document_tasks)
    # drop table(:data_donation_donation_tasks)
    # drop table(:experiments)
    # drop table(:survey_tools)
    # drop table(:survey_tool_tasks)
    # drop table(:survey_tool_participants)

    # execute(
    #   """
    #     DROP FUNCTION public.set_survey_tool_participants_participant_id();
    #     DROP FUNCTION public.set_survey_tool_current_subject_count();
    #   """
    # )
  end

  def down do
    drop(constraint(:project_items, :must_have_at_least_one_reference))
    drop(constraint(:project_items, :project_items_tool_ref_id_fkey))

    alter table(:project_items) do
      remove(:assignment_id)
      modify(:tool_ref_id, references(:tool_refs, on_delete: :delete_all), null: true)
    end

    drop(constraint(:assignments, "assignments_crew_id_fkey"))
    drop(constraint(:assignments, "assignments_budget_id_fkey"))

    alter table(:assignments) do
      modify(:budget_id, references(:budgets, on_delete: :delete_all))
      modify(:crew_id, references(:crews, on_delete: :delete_all))

      remove(:status)
      remove(:info_id)
      remove(:workflow_id)
      remove(:special)

      add(:assignable_survey_tool_id, references(:questionnaire_tools, on_delete: :delete_all),
        null: true
      )

      add(:assignable_lab_tool_id, references(:lab_tools, on_delete: :delete_all), null: true)

      add(
        :assignable_data_donation_tool_id,
        references(:data_donation_tools, on_delete: :delete_all),
        null: true
      )

      add(:assignable_experiment_id, references(:experiments, on_delete: :delete_all), null: true)
    end

    drop(table(:assignment_info))

    drop(constraint(:tool_refs, :must_have_at_least_one_tool))

    alter table(:tool_refs) do
      remove(:special)

      add(:data_donation_tool_id, references(:data_donation_tools, on_delete: :delete_all),
        null: true
      )

      add(:questionnaire_tool_id, references(:questionnaire_tools, on_delete: :delete_all),
        null: true
      )

      remove(:feldspar_tool_id)
      remove(:document_tool_id)
      remove(:alliance_tool_id)
    end

    create(
      constraint(:tool_refs, :must_have_at_least_one_tool,
        check: """
        questionnaire_tool_id != null or
        lab_tool_id != null or
        data_donation_tool_id != null or
        benchmark_tool_id != null
        """
      )
    )

    drop(table(:alliance_tool_participants))

    drop(table(:workflow_items))
    drop(table(:workflows))

    execute("""
      DROP FUNCTION public.set_alliance_tool_participants_participant_id();
    """)

    drop(table(:alliance_tools))
    drop(table(:document_tools))
    drop(table(:feldspar_tools))

    alter table(:users) do
      remove(:type)
      remove(:external_id)
    end

    drop(index(:crew_tasks, :identifier))

    alter table(:crew_tasks) do
      remove(:identifier)
      remove(:auth_node_id)
      add(:member_id, references(:crew_members, on_delete: :delete_all), null: true)
    end

    drop(constraint(:campaigns, "campaigns_promotion_id_fkey"))
    drop(constraint(:campaigns, "campaigns_promotable_assignment_id_fkey"))

    alter table(:campaigns) do
      modify(:promotion_id, references(:promotions, on_delete: :delete_all))
      modify(:promotable_assignment_id, references(:assignments, on_delete: :delete_all))
    end

    drop(constraint(:authorization_nodes, "authorization_nodes_parent_id_fkey"))

    alter table(:authorization_nodes) do
      modify(:parent_id, references(:authorization_nodes, on_delete: :delete_all))
    end
  end
end
