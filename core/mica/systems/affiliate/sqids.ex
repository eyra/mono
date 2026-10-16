defmodule Systems.Affiliate.Sqids do
  import Sqids.Hacks, only: [dialyzed_ctx: 1]

  @context Sqids.new!(
             min_length: 6,
             alphabet: "ib09gZ5ICaXJKHtLAvu6Rj4yGwsofN1p8nxWeFQYVcBz7lkqP23dTSErMODmhU"
           )

  def encode!(numbers), do: Sqids.encode!(dialyzed_ctx(@context), numbers)
  def decode!(id), do: Sqids.decode!(dialyzed_ctx(@context), id)
end
