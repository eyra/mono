defmodule GreenLight.AccessDeniedError do
  defexception [:message, plug_status: 403]
end
