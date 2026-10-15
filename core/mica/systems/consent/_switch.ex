defmodule Systems.Consent.Switch do
  use Frameworks.Signal.Handler

  alias Frameworks.{
    Signal
  }

  alias Systems.{
    Consent
  }

  @impl true
  def intercept(
        {:consent_revision, _} = signal,
        %{consent_revision: %{agreement_id: agreement_id}} = message
      ) do
    consent_agreement =
      Consent.Public.get_agreement!(agreement_id, Consent.AgreementModel.preload_graph(:down))

    dispatch!(
      {:consent_agreement, signal},
      Map.merge(message, %{consent_agreement: consent_agreement})
    )

    :ok
  end

  @impl true
  def intercept(
        {:consent_signature, _} = signal,
        %{consent_signature: %{revision: %{agreement_id: agreement_id}}} = message
      ) do
    consent_agreement =
      Consent.Public.get_agreement!(agreement_id, Consent.AgreementModel.preload_graph(:down))

    dispatch!(
      {:consent_agreement, signal},
      Map.merge(message, %{consent_agreement: consent_agreement})
    )

    :ok
  end
end
