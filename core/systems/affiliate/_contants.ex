defmodule Systems.Affiliate.Constants do
  @moduledoc false
  defmacro annotation_resource_id, do: 0

  defmacro __using__(_) do
    quote do
      alias Systems.Affiliate.Constants

      require Constants

      @annotation_resource_id Constants.annotation_resource_id()
    end
  end
end
