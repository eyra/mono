defmodule Systems.Pool.Presenter do
  use Systems.Presenter

  alias Frameworks.Signal

  alias Systems.{
    Pool
  }

  def update(%Pool.Model{} = pool, id, page) do
    Signal.Context.dispatch!(%{page: page}, %{id: id, model: pool})
    pool
  end

  def update(%Pool.SubmissionModel{} = submission, id, page) do
    Signal.Context.dispatch!(%{page: page}, %{id: id, model: submission})
    submission
  end

  # View Model By ID

  @impl true
  def view_model(id, Pool.SubmissionPage = page, assigns, url_resolver) when is_integer(id) do
    Pool.Context.get_submission!(id, pool: Pool.Model.preload_graph([:org]))
    |> view_model(page, assigns, url_resolver)
  end

  @impl true
  def view_model(%Pool.SubmissionModel{} = submission, Pool.SubmissionPage, assigns, url_resolver) do
    Pool.Builders.SubmissionPage.view_model(submission, assigns, url_resolver)
  end

  @impl true
  def view_model(id, Pool.DetailPage, assigns, url_resolver) do
    pool = Pool.Context.get!(id, Pool.Model.preload_graph([:org, :currency, :participants]))
    Pool.Builders.DetailPage.view_model(pool, assigns, url_resolver)
  end
end
