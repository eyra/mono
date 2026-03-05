defmodule Bundle do
  @moduledoc false

  def name do
    default_bundle =
      case File.read(".bundle") do
        {:ok, bundle} -> String.trim(bundle)
        {:error, _} -> "next"
      end

    "BUNDLE" |> System.get_env(default_bundle) |> String.to_atom()
  end
end
