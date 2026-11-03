defmodule Systems.Assignment.ExternalPanelIds do
  @moduledoc """
  Defines list of supported panel agencies
  """
  use Mica.Enums.Base,
      {:external_panel_ids, [:liss, :ioresearch, :generic]}
end
