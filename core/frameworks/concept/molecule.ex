defmodule Frameworks.Concept.Molecule do
  defmodule Factory do
    @type scope :: :self | :parent
    @type model :: struct()
    @callback name(model, scope) :: {:ok, binary()} | {:error, atom()}
    @callback hierarchy(model) :: {:ok, list()} | {:error, atom()}
  end

  require Logger

  def name(model, scope, default) when is_struct(model) and is_binary(default) do
    case factory().name(model, scope) do
      {:ok, name} ->
        name

      {:error, error} ->
        Logger.warn(
          "[Molecule] Error while fetching name: #{inspect(error)} for model #{inspect(model)}"
        )

        default
    end
  end

  def hierarchy(model) when is_struct(model) do
    factory().hierarchy(model)
  end

  defp factory, do: Access.get(settings(), :factory, nil)
  defp settings, do: Application.fetch_env!(:core, :molecule)
end
