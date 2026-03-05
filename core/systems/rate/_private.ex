defmodule Systems.Rate.Private do
  @moduledoc false
  def datetime_now, do: DateTime.now!("Etc/UTC")
end
