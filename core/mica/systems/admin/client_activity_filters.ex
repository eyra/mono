defmodule Systems.Admin.ClientActivityFilters do
  use Mica.Enums.Base,
      {:admin_client_activity_filters, [:this_year, :published]}
end
