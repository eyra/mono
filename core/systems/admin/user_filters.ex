defmodule Systems.Admin.UserFilters do
  use Core.Enums.Base, {:admin_user_filters, [:creator, :verified]}
end
