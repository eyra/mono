defmodule Systems.Pool.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Pool do
        pipe_through([:browser, :require_authenticated_user])
        live("/pool", OverviewPage)
        live("/pool/:id", DetailPage)
        live("/pool/student/:id", StudentPage)
        live("/pool/campaign/:id", SubmissionPage)
      end
    end
  end
end
