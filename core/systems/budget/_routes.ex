defmodule Systems.Budget.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Budget do
        pipe_through([:browser, :require_authenticated_user])
        live("/funding", FundingPage)
      end
    end
  end
end
