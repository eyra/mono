defmodule Systems.Email.LiveFeature do
  @moduledoc """
  Swallows the `{:delivered_email, email}` message that `Bamboo.TestAdapter`
  sends to the delivering process during tests.

  The test adapter delivers immediately, in the caller's process. A LiveView
  whose handler sends email, directly or through a signal (e.g. accepting a
  contribution notifies the participant), then receives that message itself.
  Without this stub it crashes with `no function clause matching` in the test
  environment.
  """

  defmacro __using__(_opts \\ []) do
    quote do
      def handle_info({:delivered_email, _}, socket), do: {:noreply, socket}
    end
  end
end
