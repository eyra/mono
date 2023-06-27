defmodule Systems.DataDonation.Platforms do
  @moduledoc """
  Defines DDP platforms that are supported out of the box.
  """
  use Core.Enums.Base,
      {:platforms,
       [
         :facebook,
         :instagram,
         :twitter,
         :google,
         :youtube,
         :whatsapp
       ]}
end
