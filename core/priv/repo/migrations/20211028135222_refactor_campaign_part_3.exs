defmodule Core.Repo.Migrations.RefactorCampaignPart3 do
  use Ecto.Migration

  def up do
    drop index(:crews, [:reference_type, :reference_id])
    alter table(:crews) do
      modify(:reference_type, :string, null: true)
      modify(:reference_id, :bigint, null: true)
    end

    alter table(:crew_tasks) do
      modify(:plugin, :string, null: true)
    end

    drop constraint(:assignments, :assignments_crew_id_fkey)
    alter table(:assignments) do
      modify(:crew_id, references(:crews, on_delete: :delete_all), null: false)
    end

    drop constraint(:survey_tools, :survey_tools_campaign_id_fkey)
    drop constraint(:survey_tools, :survey_tools_promotion_id_fkey)
    alter table(:survey_tools) do
      modify(:campaign_id, references(:campaigns, on_delete: :delete_all), null: true)
      modify(:promotion_id, references(:promotions, on_delete: :delete_all), null: true)
    end

    drop constraint(:lab_tools, :lab_tools_campaign_id_fkey)
    drop constraint(:lab_tools, :lab_tools_promotion_id_fkey)
    alter table(:lab_tools) do
      modify(:campaign_id, references(:campaigns, on_delete: :delete_all), null: true)
      modify(:promotion_id, references(:promotions, on_delete: :delete_all), null: true)
    end

    drop constraint(:data_donation_tools, :data_donation_tools_campaign_id_fkey)
    drop constraint(:data_donation_tools, :data_donation_tools_promotion_id_fkey)
    alter table(:data_donation_tools) do
      modify(:campaign_id, references(:campaigns, on_delete: :delete_all), null: true)
      modify(:promotion_id, references(:promotions, on_delete: :delete_all), null: true)
    end


    drop constraint(:campaigns, :campaigns_promotion_id_fkey)
    drop constraint(:campaigns, :campaigns_promotable_assignment_id_fkey)
    alter table(:campaigns) do
      modify(:promotion_id, references(:promotions, on_delete: :delete_all), null: false)
      modify(:promotable_assignment_id, references(:assignments, on_delete: :delete_all), null: false)
    end
  end

  def down do
    drop constraint(:data_donation_tools, :data_donation_tools_campaign_id_fkey)
    drop constraint(:data_donation_tools, :data_donation_tools_promotion_id_fkey)
    alter table(:data_donation_tools) do
      modify(:campaign_id, references(:campaigns, on_delete: :delete_all), null: false)
      modify(:promotion_id, references(:promotions, on_delete: :delete_all), null: false)
    end

    drop constraint(:lab_tools, :lab_tools_campaign_id_fkey)
    drop constraint(:lab_tools, :lab_tools_promotion_id_fkey)
    alter table(:lab_tools) do
      modify(:campaign_id, references(:campaigns, on_delete: :delete_all), null: false)
      modify(:promotion_id, references(:promotions, on_delete: :delete_all), null: false)
    end

    drop constraint(:survey_tools, :survey_tools_campaign_id_fkey)
    drop constraint(:survey_tools, :survey_tools_promotion_id_fkey)
    alter table(:survey_tools) do
      modify(:campaign_id, references(:campaigns, on_delete: :delete_all), null: false)
      modify(:promotion_id, references(:promotions, on_delete: :delete_all), null: false)
    end

    drop constraint(:assignments, :assignments_crew_id_fkey)
    alter table(:assignments) do
      modify(:crew_id, references(:crews, on_delete: :delete_all), null: true)
    end

    alter table(:crew_tasks) do
      modify(:plugin, :string, null: false)
    end

    alter table(:crews) do
      modify(:reference_type, :string, null: false)
      modify(:reference_id, :bigint, null: false)
    end
    create(unique_index(:crews, [:reference_type, :reference_id]))
  end
end
