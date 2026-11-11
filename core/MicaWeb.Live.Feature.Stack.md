# `MicaWeb.Live.Feature.Stack`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/live/feature/stack.ex#L1)

LiveView helper functions for working with block-based stack architecture.

Provides utilities for inspecting and working with view model stacks
in the composable block rendering pattern.

# `count_blocks_in_stack`

Counts the number of blocks of a specific type in the stack.

## Examples

    iex> stack = [{:button, %{}}, {:content, %{}}, {:button, %{}}]
    iex> count_blocks_in_stack(stack, :button)
    2

# `get_block_from_stack`

Finds a specific block in the stack and returns its assigns.

## Examples

    iex> stack = [{:header, %{title: "Test"}}, {:content, %{}}]
    iex> get_block_from_stack(stack, :header)
    %{title: "Test"}

    iex> stack = [{:header, %{title: "Test"}}, {:content, %{}}]
    iex> get_block_from_stack(stack, :footer)
    nil

# `get_blocks_from_stack`

Gets all blocks of a specific type from the stack.

Useful when a stack might contain multiple blocks of the same type.

## Examples

    iex> stack = [{:button, %{id: 1}}, {:content, %{}}, {:button, %{id: 2}}]
    iex> get_blocks_from_stack(stack, :button)
    [%{id: 1}, %{id: 2}]

# `has_block_in_stack?`

Checks if a specific block type exists in the view model stack.

## Examples

    iex> stack = [{:header, %{}}, {:content, %{}}]
    iex> has_block_in_stack?(stack, :header)
    true

    iex> stack = [{:header, %{}}, {:content, %{}}]
    iex> has_block_in_stack?(stack, :footer)
    false

---

*Consult [api-reference.md](api-reference.md) for complete listing*
