defmodule Systems.Rate.Algorithm do
  # ARGS
  @type state :: map
  @type service :: :atom
  @type client_id :: String.t()
  @type packet_size :: integer

  # RESULT
  @type permission_result :: permission_granted | permission_denied
  @type permission_granted :: {:granted, map}
  @type permission_denied :: {{:denied, :atom}, map}

  @callback request_permission(state, service, client_id, packet_size) :: permission_result
end
