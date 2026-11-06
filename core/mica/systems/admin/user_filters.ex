defmodule Systems.Admin.UserFilters do
  use Mica.Enums.Base,
      {:admin_user_filters, [:creator, :verified, :unverified, :affiliate, :in_pool]}
end
