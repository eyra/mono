defmodule Systems.Test.Presenter do
  use Systems.Presenter

  alias Systems.Observatory

  @impl true
  def view_model(%Systems.Test.Model{} = model, page, assigns) do
    model
    |> Builder.view_model(page, assigns)
  end

  def view_model(id, page, assigns) when is_binary(id) do
    Systems.Test.Public.get(id)
    |> Builder.view_model(page, assigns)
  end

  def update(Systems.Test.Page = page, model) do
    Observatory.Public.local_dispatch(page, [model.id], %{model: model})
  end
end
