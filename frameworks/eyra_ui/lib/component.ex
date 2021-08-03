defmodule EyraUI.Component do
  defmacro __using__(_props \\ []) do
    quote do
      use Surface.Component

      require EyraUI.ViewModel
      import EyraUI.ViewModel
    end
  end
end
