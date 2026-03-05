defmodule Systems.Admin.UserFilters do
  @moduledoc false
  use Core.Enums.Base, {:admin_user_filters, [:creator, :verified]}
end
