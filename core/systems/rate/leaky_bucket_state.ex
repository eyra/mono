defmodule Systems.Rate.LeakyBucketState do
  alias Systems.Rate.Quota, as: Quota
  alias Systems.Rate.Bucket, as: Bucket

  @type t :: %__MODULE__{
    quotas: [Quota.t],
    buckets: %{String.t => Bucket.t}
  }

  @enforce_keys [:quotas, :buckets]
  defstruct [:quotas, :buckets]

  @spec new([Quota.t, ...]) :: t
  def new(quotas) do
    %__MODULE__{quotas: quotas, buckets: %{}}
  end

  @spec update(__MODULE__.t, String.t, Bucket.t) :: __MODULE__.t
  def update(%__MODULE__{} = state, key, %Bucket{} = bucket) do
    state |> put_in([:buckets, key], bucket)
  end
end
