defmodule Frameworks.Concept.Branch do
  defmodule Factory do
    @type scope :: :self | :parent
    @type leaf :: struct()
    @callback name(leaf, scope) :: {:ok, binary()} | {:error, atom()}
    @callback hierarchy(leaf) :: {:ok, list()} | {:error, atom()}
  end

  require Logger

  def name(leaf, scope, default) when is_struct(leaf) and is_binary(default) do
    case factory().name(leaf, scope) do
      {:ok, name} ->
        name

      {:error, error} ->
        Logger.warn(
          "[Branch] Error while fetching name: #{inspect(error)} for leaf #{inspect(leaf)}"
        )

        default
    end
  end

  def hierarchy(leaf) when is_struct(leaf) do
    factory().hierarchy(leaf)
  end

  defp factory, do: Access.get(settings(), :factory, nil)
  defp settings, do: Application.fetch_env!(:core, :branch)
end
