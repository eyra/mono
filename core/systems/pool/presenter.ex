defmodule Systems.Pool.Presenter do
  use Systems.Presenter

  alias Frameworks.Signal

  alias Systems.{
    Pool
  }

  def update(page) do
    pool = Pool.Context.get_by_name(:sbe_2021)
    Signal.Context.dispatch!(%{page: page}, %{id: :sbe_2021, model: pool})

    pool
  end

  def update(%Pool.SubmissionModel{} = submission, id, page) do
    Signal.Context.dispatch!(%{page: page}, %{id: id, model: submission})
    submission
  end

  # View Model By ID

  @impl true
  def view_model(id, page, assigns, url_resolver) when is_integer(id) do
    Pool.Context.get_submission!(id)
    |> view_model(page, assigns, url_resolver)
  end

  @impl true
  def view_model(%Pool.SubmissionModel{} = submission, page, assigns, url_resolver) do
    builder(page).view_model(submission, assigns, url_resolver)
  end

  @impl true
  def view_model(id, page, assigns, url_resolver) when is_atom(id) do
    pool = Pool.Context.get_by_name(id)
    builder(page).view_model(pool, assigns, url_resolver)
  end

  defp builder(Pool.OverviewPage), do: Pool.Builders.OverviewPage
  defp builder(Pool.SubmissionPage), do: Pool.Builders.SubmissionPage
end
