defmodule Systems.Rate.Algorithm do
  @type permission_granted :: {:granted, map}
  @type permission_denied :: {{:denied, :atom}, map}
  @type permission_result :: permission_granted | permission_denied
  @type request :: {:atom, String.t, integer}

  @callback request_permission(map, :atom, String.t, integer) :: permission_result
end
