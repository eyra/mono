defmodule Systems.Rate.Private do
  def datetime_now(), do: DateTime.now!("Etc/UTC")
end
