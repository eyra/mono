defmodule Systems.Advert.Status do
  use Core.Enums.Base,
      {:advert_status, [:concept, :online, :offline, :idle]}
end
