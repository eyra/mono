defmodule Systems.Payment.Routes do
  defmacro routes() do
    quote do
      scope "/api/payment", Systems.Payment do
        pipe_through([:api])
        post("/webhook/:provider", Controller, :webhook)
      end

      scope "/payment/local", Systems.Payment.Provider do
        pipe_through([:browser])
        get("/:uid", LocalController, :pay)
        post("/:uid/complete", LocalController, :complete)
        post("/:uid/fail", LocalController, :fail)
      end
    end
  end
end
