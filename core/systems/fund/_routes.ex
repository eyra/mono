defmodule Systems.Fund.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Fund do
        pipe_through([:browser, :require_authenticated_user])
        live("/funding", FundingPage)
      end
    end
  end
end
