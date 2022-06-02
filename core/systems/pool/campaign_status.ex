defmodule Systems.Pool.CampaignStatus do
  use Core.Enums.Base,
      {:pool_campaign_status, [:drafted, :submitted, :scheduled, :released, :closed, :completed]}
end
