defmodule Systems.Admin.UserFilters do
  use Mica.Enums.Base,
      {:admin_user_filters, [:creator, :publish, :pay_in, :affiliate, :in_pool]}
end
