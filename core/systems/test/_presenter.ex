defmodule Systems.Test.Presenter do
  use Frameworks.Concept.Presenter

  alias Systems.Observatory

  @impl true
  def view_model(page, %Systems.Test.Model{} = model, assigns) do
    Builder.view_model(model, page, assigns)
  end

  def view_model(page, id, assigns) when is_binary(id) do
    Builder.view_model(Systems.Test.Public.get(id), page, assigns)
  end

  def update(Systems.Test.Page = page, model) do
    Observatory.Public.local_dispatch(page, [model.id], %{model: model})
  end
end
