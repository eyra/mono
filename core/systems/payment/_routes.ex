defmodule Systems.Payment.Routes do
  defmacro routes() do
    quote do
      scope "/api/payment", Systems.Payment do
        pipe_through([:api])
        post("/webhook/:provider", Controller, :webhook)
      end
    end
  end
end
