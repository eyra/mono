defmodule Systems.Campaign.MonitorModel do

  use Ecto.Schema

  embedded_schema do
    field(:is_active, :boolean)
    field(:pending_count, :integer)
    field(:completed_count, :integer)
    field(:vacant_count, :integer)
  end
end
