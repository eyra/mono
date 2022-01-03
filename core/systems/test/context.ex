defmodule Systems.Test.Context do
  alias Systems.{
    Test
  }

  def get(id) do
    %Test.Model{
      director: :test,
      id: id,
      name: "John Doe",
      department: "The Basement",
      age: 56
    }
  end

  def update(%Test.Model{} = model, attrs) do
    model = struct!(model, attrs)
    Test.Presenter.update(Systems.Test.Page, model)
    model
  end
end
