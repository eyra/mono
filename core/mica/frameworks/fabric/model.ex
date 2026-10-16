defmodule Fabric.Model do
  alias Fabric.LiveView
  alias Fabric.LiveComponent

  @type ref :: LiveView.RefModel.t() | LiveComponent.RefModel.t()
  @type ref_optional :: ref | nil
  @type model :: LiveComponent.Model.t()
  @type model_id :: atom()
  @type model_id_optional :: model_id() | nil
  @type model_list :: [model()]
  @type model_list_optional :: model_list() | nil

  @type t :: %__MODULE__{
          parent: ref_optional(),
          self: ref(),
          children: model_list_optional()
        }

  defstruct [:parent, :self, :children]
end
