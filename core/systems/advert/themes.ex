defmodule Systems.Advert.Themes do
  @moduledoc """
  Defines themes used to categorize adverts.
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
