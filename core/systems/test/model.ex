defmodule Systems.Test.Model do
  defstruct [:director, :id, :name, :department, :age]
end

defimpl Frameworks.Utility.ViewModelBuilder, for: Systems.Test.Model do
  def view_model(%Systems.Test.Model{} = model, page, _assigns) do
    vm(model, page)
  end

  defp vm(%{id: id, name: name, department: department, age: age}, Systems.Test.Page) do
    %{
      id: id,
      title: name,
      subtitle: "Age: #{age} - Works at: #{department}"
    }
  end
end
