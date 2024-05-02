defmodule Systems.Advert.Status do
  use Core.Enums.Base,
      {:advert_status, [:submitted, :scheduled, :released, :closed, :retracted, :completed]}
end
