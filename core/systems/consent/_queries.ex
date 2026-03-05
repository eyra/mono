defmodule Systems.Consent.Queries do
  @moduledoc false
  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Consent

  require Ecto.Query
  require Frameworks.Utility.Query

  def signature_query do
    from(Consent.SignatureModel, as: :signature)
  end

  def signature_query(%Consent.AgreementModel{id: consent_agreement_id}) do
    build(signature_query(), :signature,
      revision: [
        agreement: [
          id == ^consent_agreement_id
        ]
      ]
    )
  end
end
