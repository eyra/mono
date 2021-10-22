defmodule Link.Enums.Themes do
  @moduledoc """
  Defines themes used to categorize campaigns.
  """
  use Core.Enums.Base,
      {:themes,
       [
         :marketing,
         :accounting,
         :management,
         :organisation,
         :economics,
         :business,
         :econometrics,
         :data_science,
         :finance,
         :operations_analytics,
         :digital_innovation
       ]}
end
