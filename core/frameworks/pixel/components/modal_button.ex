defmodule Frameworks.Pixel.ModalButton do
  @moduledoc """
  Button configuration for modal toolbars.

  ## Fields

  - `label` - Required. The button label text.
  - `icon` - Optional. Icon atom (e.g., `:done`, `:back`, `:forward`).
  - `icon_align` - Optional. `:left` or `:right` (default).
  - `event` - Required. Atom event name sent to embedded view.
  - `item` - Optional. Item data sent with the event.
  - `target` - Required. PID of the LiveView to receive the event.

  ## Example

      %ModalButton{
        label: "Done",
        icon: :done,
        event: :done,
        item: 123,
        target: self()
      }
  """

  @enforce_keys [:label, :event, :target]
  defstruct [
    :label,
    :icon,
    :event,
    :item,
    :target,
    icon_align: :right
  ]

  @type t :: %__MODULE__{
          label: String.t(),
          icon: atom() | nil,
          icon_align: :left | :right,
          event: atom(),
          item: any() | nil,
          target: pid()
        }
end
