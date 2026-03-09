defmodule Systems.Payment.Routes do
  defmacro routes() do
    quote do
      scope "/api/payment", Systems.Payment do
        pipe_through([:api])
        post("/opp/webhook", Controller, :opp_webhook)
      end
    end
  end
end
