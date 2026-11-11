# `Frameworks.Pixel.ModalButton`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/components/modal_button.ex#L1)

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

# `t`

```elixir
@type t() :: %Frameworks.Pixel.ModalButton{
  event: atom(),
  icon: atom() | nil,
  icon_align: :left | :right,
  item: any() | nil,
  label: String.t(),
  target: pid()
}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
