defmodule Frameworks.Concept.Context do
  defmodule Handler do
    @type scope :: :self | :parent
    @type model :: struct()
    @callback name(model, scope) :: {:ok, binary()} | {:error, atom()}
    @callback breadcrumbs(model) :: {:ok, list()} | {:error, atom()}
  end

  def name(model, scope, default) when is_struct(model) and is_binary(default) do
    Enum.reduce(handlers(), default, fn handler, acc ->
      case handler.name(model, scope) do
        {:ok, name} -> name
        {:error, _} -> acc
      end
    end)
  end

  def breadcrumbs(model) when is_struct(model) do
    Enum.reduce(handlers(), [], fn handler, acc ->
      case handler.breadcrumbs(model) do
        {:ok, breadcrumbs} -> breadcrumbs
        {:error, _} -> acc
      end
    end)
  end

  defp handlers() do
    Access.get(settings(), :handlers, [])
  end

  defp settings() do
    Application.fetch_env!(:core, :naming)
  end
end
