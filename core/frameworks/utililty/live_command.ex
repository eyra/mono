defmodule Frameworks.Utility.LiveCommand do
  defstruct [:function, :args]

  def live_command(function, args) do
    %Frameworks.Utility.LiveCommand{function: function, args: args}
  end

  def execute(%{function: function, args: args}, socket) when is_function(function, 2) do
    function.(args, socket)
  end
end
