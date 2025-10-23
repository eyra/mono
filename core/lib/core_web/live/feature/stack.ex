defmodule CoreWeb.Live.Feature.Stack do
  @moduledoc """
  LiveView helper functions for working with block-based stack architecture.

  Provides utilities for inspecting and working with view model stacks
  in the composable block rendering pattern.
  """

  defmacro __using__(_opts) do
    quote do
      import CoreWeb.Live.Feature.Stack
    end
  end

  @doc """
  Checks if a specific block type exists in the view model stack.

  ## Examples

      iex> stack = [{:header, %{}}, {:content, %{}}]
      iex> has_block_in_stack?(stack, :header)
      true

      iex> stack = [{:header, %{}}, {:content, %{}}]
      iex> has_block_in_stack?(stack, :footer)
      false
  """
  def has_block_in_stack?(stack, block_type) when is_list(stack) and is_atom(block_type) do
    stack
    |> Enum.any?(fn {type, _} -> type == block_type end)
  end

  @doc """
  Finds a specific block in the stack and returns its assigns.

  ## Examples

      iex> stack = [{:header, %{title: "Test"}}, {:content, %{}}]
      iex> get_block_from_stack(stack, :header)
      %{title: "Test"}

      iex> stack = [{:header, %{title: "Test"}}, {:content, %{}}]
      iex> get_block_from_stack(stack, :footer)
      nil
  """
  def get_block_from_stack(stack, block_type) when is_list(stack) and is_atom(block_type) do
    stack
    |> Enum.find(fn {type, _} -> type == block_type end)
    |> case do
      {_, block_assigns} -> block_assigns
      nil -> nil
    end
  end

  @doc """
  Gets all blocks of a specific type from the stack.

  Useful when a stack might contain multiple blocks of the same type.

  ## Examples

      iex> stack = [{:button, %{id: 1}}, {:content, %{}}, {:button, %{id: 2}}]
      iex> get_blocks_from_stack(stack, :button)
      [%{id: 1}, %{id: 2}]
  """
  def get_blocks_from_stack(stack, block_type) when is_list(stack) and is_atom(block_type) do
    stack
    |> Enum.filter(fn {type, _} -> type == block_type end)
    |> Enum.map(fn {_, block_assigns} -> block_assigns end)
  end

  @doc """
  Counts the number of blocks of a specific type in the stack.

  ## Examples

      iex> stack = [{:button, %{}}, {:content, %{}}, {:button, %{}}]
      iex> count_blocks_in_stack(stack, :button)
      2
  """
  def count_blocks_in_stack(stack, block_type) when is_list(stack) and is_atom(block_type) do
    stack
    |> Enum.count(fn {type, _} -> type == block_type end)
  end
end
