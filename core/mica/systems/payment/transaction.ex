defmodule Systems.Payment.Transaction do
  @moduledoc false

  defmodule Request do
    @moduledoc false

    alias Systems.Payment.Transaction

    @type t :: %__MODULE__{
            merchant_uid: String.t(),
            total_amount: pos_integer(),
            currency: atom(),
            invoice_id: String.t(),
            idempotence_key: String.t(),
            description: Transaction.Description.t(),
            metadata: Transaction.Metadata.t(),
            opts: keyword()
          }

    @enforce_keys [
      :merchant_uid,
      :total_amount,
      :currency,
      :invoice_id,
      :idempotence_key,
      :description,
      :metadata
    ]
    defstruct [
      :merchant_uid,
      :total_amount,
      :currency,
      :invoice_id,
      :idempotence_key,
      :description,
      :metadata,
      opts: []
    ]
  end

  defmodule Description do
    @moduledoc false

    @type t :: %__MODULE__{
            platform: String.t(),
            assignment: String.t(),
            participant_count: pos_integer(),
            amount_per_participant: pos_integer()
          }

    @enforce_keys [:platform, :assignment, :participant_count, :amount_per_participant]
    defstruct [:platform, :assignment, :participant_count, :amount_per_participant]

    @spec format(t(), String.t()) :: String.t()
    def format(%__MODULE__{} = desc, invoice_id) when is_binary(invoice_id) do
      amount_str = format_euro_amount(desc.amount_per_participant)

      "#{desc.platform}, #{desc.assignment}, Invoice #{invoice_id}, #{desc.participant_count} participants x #{amount_str}"
    end

    defp format_euro_amount(cents) when is_integer(cents) do
      euros = div(cents, 100)
      remaining = rem(cents, 100)
      "€#{euros}.#{String.pad_leading(Integer.to_string(remaining), 2, "0")}"
    end
  end

  defmodule Metadata do
    @moduledoc false

    @type t :: %__MODULE__{
            contact_person: String.t(),
            study_title: String.t(),
            study_goal: String.t(),
            aim_of_study: String.t() | nil,
            participant_count: pos_integer(),
            amount_per_participant: pos_integer()
          }

    @enforce_keys [
      :contact_person,
      :study_title,
      :study_goal,
      :participant_count,
      :amount_per_participant
    ]
    defstruct [
      :contact_person,
      :study_title,
      :study_goal,
      :aim_of_study,
      :participant_count,
      :amount_per_participant
    ]

    @spec to_map(t(), String.t()) :: map()
    def to_map(%__MODULE__{} = metadata, invoice_id) when is_binary(invoice_id) do
      metadata
      |> Map.from_struct()
      |> Map.put(:invoice_id, invoice_id)
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
      |> Map.new(fn {k, v} -> {k, to_string(v)} end)
    end
  end
end
