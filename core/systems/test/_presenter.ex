defmodule Systems.Test.Presenter do
  use Frameworks.Concept.Presenter

  alias Systems.Observatory
  alias Systems.Test

  @impl true
  def view_model(Test.Page = page, %Test.Model{} = model, assigns) do
    Builder.view_model(model, page, assigns)
  end

  def view_model(Test.Page = page, id, assigns) when is_binary(id) do
    Builder.view_model(Test.Public.get(id), page, assigns)
  end

  def view_model(Test.RoutedLiveView, model, assigns) do
    Test.RoutedLiveViewBuilder.view_model(model, assigns)
  end

  def view_model(Test.EmbeddedLiveView, model, assigns) do
    Test.EmbeddedLiveViewBuilder.view_model(model, assigns)
  end

  def view_model(Test.ModalLiveView, model, assigns) do
    Test.ModalLiveViewBuilder.view_model(model, assigns)
  end

  def update(Test.Page = page, model) do
    Observatory.Public.local_dispatch(page, [model.id], %{model: model})
  end
end
