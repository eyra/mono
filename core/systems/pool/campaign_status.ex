defmodule Systems.Pool.CampaignStatus do
  use Core.Enums.Base,
      {:pool_campaign_status,
       [:submitted, :scheduled, :released, :closed, :retracted, :completed]}
end
