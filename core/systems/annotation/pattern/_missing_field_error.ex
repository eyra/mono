defmodule Systems.Annotation.Pattern.MissingFieldError do
  @moduledoc false
  defexception [:message]

  def exception(field) do
    %__MODULE__{message: "Pattern field `#{field}` is required"}
  end
end
