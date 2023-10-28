defmodule Systems.Union.Routes do
  defmacro routes() do
    quote do
      scope "/centerdata", Systems.Union.Centerdata do
        pipe_through([:browser])
        get("/:id", Controller, :create)
        live("/fakeapi/page", FakeApiPage)
      end

      scope "/centerdata", Systems.Union.Centerdata do
        pipe_through([:browser_unprotected])
        post("/:id", Controller, :create)
      end
    end
  end
end
