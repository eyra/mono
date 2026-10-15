defmodule Systems.Affiliate.Routes do
  defmacro routes() do
    quote do
      scope "/a", Systems.Affiliate do
        pipe_through([:browser])
        get("/:sqid", Controller, :create)
      end

      scope "/r", Systems.Affiliate do
        pipe_through([:browser])
        get("/:sqid", Controller, :recruit)
      end
    end
  end
end
