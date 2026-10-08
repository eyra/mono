defmodule Systems.Admin.ClientActivityFilters do
  use Core.Enums.Base,
      {:admin_client_activity_filters, [:this_year, :published]}
end
