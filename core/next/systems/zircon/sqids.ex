defmodule Systems.Zircon.Sqids do
  import Sqids.Hacks, only: [dialyzed_ctx: 1]

  @context Sqids.new!(
             min_length: 6,
             alphabet: "ybvsMpairBfEI4G5qTkxtRlmUhc7W1ZNXHzuQwDJYFA90OgPjdonVSKL3Ce826"
           )

  def encode!(numbers), do: Sqids.encode!(dialyzed_ctx(@context), numbers)
  def decode!(id), do: Sqids.decode!(dialyzed_ctx(@context), id)
end
