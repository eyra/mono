defmodule Systems.Payment.Routes do
  defmacro routes() do
    quote do
      scope "/api/payment", Systems.Payment do
        pipe_through([:api])
        post("/webhook/:provider", Controller, :webhook)
      end

      # The local provider is a dev/test stub that auto-completes pay-ins.
      # It is compiled out unless :enable_e2e_support is set at build time,
      # so it can't be reached even if PAYMENT_PROVIDER is misconfigured at
      # runtime. Enabled for :dev/:test and for non-production release builds
      # via the ENABLE_E2E_SUPPORT build arg (see config/config.exs).
      if Application.compile_env(:core, :enable_e2e_support, false) do
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
