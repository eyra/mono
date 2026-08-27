defmodule Systems.Org.MemberFilters do
  @moduledoc false
  use Core.Enums.Base, {:org_member_filters, [:external, :recent]}
end
