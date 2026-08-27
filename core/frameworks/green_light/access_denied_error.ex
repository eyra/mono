defmodule Frameworks.GreenLight.AccessDeniedError do
  @moduledoc false
  defexception [:message, plug_status: 403]
end
