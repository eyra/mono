defmodule Systems.Affiliate.Constants do
  defmacro annotation_resource_id, do: 0

  defmacro __using__(_) do
    quote do
      require Systems.Affiliate.Constants
      @annotation_resource_id Systems.Affiliate.Constants.annotation_resource_id()
    end
  end
end
