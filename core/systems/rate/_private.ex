defmodule Systems.Rate.Private do
  defmodule RateLimitError do
    defexception [:message]
  end

end
