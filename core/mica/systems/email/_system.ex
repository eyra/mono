defmodule Systems.Email.System do
  use Mica.System

  def oban_queues, do: [email_dispatchers: 1, email_delivery: 1]
end
