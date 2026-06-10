defmodule CoreWeb.FeaturesController do
  @moduledoc """
  Returns the set of enabled feature flags for this deployment.

  Used by smoke tests and E2E runners to discover the feature set and
  decide which tests to skip. Intentionally ungated — available on all
  environments including production.
  """
  use CoreWeb, {:controller, [formats: [:json]]}

  def get(conn, _params) do
    enabled =
      :core
      |> Application.get_env(:features, [])
      |> Enum.filter(fn {_, on?} -> on? end)
      |> Enum.map(fn {key, _} -> Atom.to_string(key) end)
      |> Enum.sort()

    json(conn, %{features: enabled})
  end
end
