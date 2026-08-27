defmodule Core.PaymentCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  Mox.defmock(Systems.Payment.ProviderMock, for: Systems.Payment.Provider)

  using do
    quote do
      import Mox

      alias Systems.Payment.Error
      alias Systems.Payment.Provider
      alias Systems.Payment.ProviderMock
    end
  end

  setup do
    Mox.verify_on_exit!()
    :ok
  end
end
