defmodule Fabric.Model do
  alias Fabric.LiveView
  alias Fabric.LiveComponent

  @type ref :: LiveView.RefModel.t() | LiveComponent.RefModel.t()
  @type ref_optional :: ref | nil
  @type model :: LiveComponent.Model.t()

  @type t :: %__MODULE__{
          parent: ref_optional(),
          self: ref,
          children: [model()]
        }

  defstruct [:parent, :self, :children]
end
