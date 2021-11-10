defmodule Systems.Test.Presenter do
  use Systems.Presenter

  alias Systems.Observatory

  @impl true
  def view_model(%Systems.Test.Model{} = model, page, user, url_resolver) do
    model
    |> Builder.view_model(page, user, url_resolver)
  end

  def view_model(id, page, user, url_resolver) when is_binary(id) do
    Systems.Test.Context.get(id)
    |> Builder.view_model(page, user, url_resolver)
  end

  def update(Systems.Test.Page = page, model) do
    Observatory.Context.local_dispatch(page, [model.id], %{model: model})
  end

end
