defmodule Systems.Sequence.External do
  @type id :: atom
  @type task :: map

  @callback create_element(id) :: task
end
