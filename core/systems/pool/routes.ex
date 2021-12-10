defmodule Systems.Pool.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Pool do
        pipe_through([:browser, :require_authenticated_user])
        live("/studentpool", OverviewPage)
        live("/campaign/:id/submission", SubmissionPage)
      end
    end
  end
end
