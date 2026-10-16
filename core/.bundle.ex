defmodule Bundle do
  @moduledoc false

  def name() do
    default_bundle =
      case File.read(".bundle") do
        {:ok, bundle} -> String.trim(bundle)
        {:error, _} -> "next"
      end

    System.get_env("BUNDLE", default_bundle) |> String.to_atom()
  end

  @doc "Directory of a bundle, relative to core/."
  def dir(:next), do: "next/bundle"
  def dir(:self), do: "mica_saas/bundle"
end
