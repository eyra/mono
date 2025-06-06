defmodule Systems.Annotation.Recipe.MissingFieldError do
  @moduledoc false
  defexception [:message]

  def exception(field) do
    %__MODULE__{message: "Recipe field `#{field}` is required"}
  end
end
