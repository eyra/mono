defmodule Systems.Payment.Routes do
  defmacro routes() do
    quote do
      scope "/api/payment", Systems.Payment do
        pipe_through([:api])
        post("/webhook/:provider", Controller, :webhook)
      end

      # The local provider is a dev-only stub that auto-completes pay-ins.
      # Compile it out of prod builds entirely so it can't be reached even
      # if PAYMENT_PROVIDER is misconfigured at runtime.
      if Mix.env() != :prod do
        scope "/payment/local", Systems.Payment.Provider do
          pipe_through([:browser])
          get("/:uid", LocalController, :pay)
          post("/:uid/complete", LocalController, :complete)
          post("/:uid/fail", LocalController, :fail)
        end
      end
    end
  end
end
