defmodule Systems.Pool.Assembly do
  @moduledoc """
  Assembly module for creating and managing pool-related entities.
  """
  alias Systems.Budget
  alias Systems.Org
  alias Systems.Pool

  @panl_name "Panl"
  @panl_target 1000
  @panl_director :citizen
  @panl_org_identifier ["panl"]

  @doc """
  Gets the PANL pool, creating it with all dependencies if it doesn't exist.
  """
  def get_or_create_panl do
    case Pool.Public.get_panl() do
      %Pool.Model{} = pool ->
        pool

      nil ->
        create_panl_pool()
    end
  end

  defp create_panl_pool do
    currency = Budget.Assembly.get_or_create_euro()
    org = get_or_create_panl_org()

    Pool.Public.create!(@panl_name, @panl_target, currency, org, @panl_director)
  end

  defp get_or_create_panl_org do
    case Org.Public.get_node(@panl_org_identifier) do
      %Org.NodeModel{} = org ->
        org

      nil ->
        Org.Public.create_node!(
          @panl_org_identifier,
          [{:en, "Panl"}, {:nl, "Panl"}],
          [{:en, "Panl"}, {:nl, "Panl"}]
        )
    end
  end
end
