defmodule Systems.Account.Auth.Methods do
  alias Frameworks.Utility

  def methods do
    Application.fetch_env!(:core, :account)
    |> Keyword.fetch!(:auth_methods)
  end

  def satellites do
    methods()
    |> Enum.filter(fn {_method, config} -> config.satellite end)
    |> Map.new(fn {method, _config} -> {method, satellite_module(method)} end)
  end

  def providers do
    methods()
    |> Enum.filter(fn {_method, config} -> config.provider end)
    |> Enum.map(fn {method, _config} -> method end)
  end

  def satellite_providers do
    methods()
    |> Enum.filter(fn {_method, config} -> config.provider && config.satellite end)
    |> Enum.map(fn {method, _config} -> method end)
  end

  def provider?(method), do: methods() |> Map.get(method, %{}) |> Map.get(:provider, false)

  def satellite(method), do: satellites() |> Map.fetch!(method)

  defp satellite_module(method) do
    method = method |> Atom.to_string() |> Macro.camelize()
    Utility.Module.get("Account.Auth.#{method}", "UserModel")
  end

  def provider_for_mx_provider(nil), do: nil

  def provider_for_mx_provider(slug) do
    methods()
    |> Enum.find_value(fn {method, config} ->
      config.provider && config.satellite && config[:mx_provider] == slug && method
    end)
  end
end
