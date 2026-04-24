defmodule Core.AppSignal.TelemetryHandler do
  @moduledoc """
  General telemetry handler that forwards events to AppSignal as custom metrics.

  Any system can emit telemetry events following the convention:

      :telemetry.execute([:system, :action, :stop], %{duration: d}, metadata)
      :telemetry.execute([:system, :action, :exception], %{duration: d}, metadata)
      :telemetry.execute([:system, :action, :rate_limited], %{count: 1}, metadata)

  This handler converts them to AppSignal metrics:

  Counters:
  - `system_action_count` — incremented on :stop
  - `system_action_error_count` — incremented on :exception
  - `system_action_rate_limited_count` — incremented on :rate_limited

  Distributions:
  - `system_action_duration` — duration in ms on :stop
  - Any extra numeric measurement is forwarded as `system_action_<key>`

  Tags are derived from metadata (non-nil string values).

  ## Usage

  Call `Core.AppSignal.TelemetryHandler.attach()` at application startup.
  Add new event prefixes to `@event_prefixes`.
  """

  @event_prefixes [
    [:feldspar, :donate],
    [:feldspar, :log]
  ]

  def attach do
    attach(@event_prefixes)
  end

  def attach(event_prefixes) when is_list(event_prefixes) do
    events =
      Enum.flat_map(event_prefixes, fn prefix ->
        [prefix ++ [:stop], prefix ++ [:exception], prefix ++ [:rate_limited]]
      end)

    :telemetry.attach_many(
      "appsignal-telemetry-handler",
      events,
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event(event, measurements, metadata, _config) do
    {prefix, suffix} = split_event(event)
    metric_prefix = Enum.join(prefix, "_")
    tags = to_tags(metadata)

    case suffix do
      :stop ->
        Appsignal.increment_counter("#{metric_prefix}_count", 1, tags)
        forward_measurements(metric_prefix, measurements, tags)

      :exception ->
        Appsignal.increment_counter("#{metric_prefix}_error_count", 1, tags)

      :rate_limited ->
        Appsignal.increment_counter("#{metric_prefix}_rate_limited_count", 1, tags)
    end
  end

  defp split_event(event) do
    suffix = List.last(event)
    prefix = Enum.drop(event, -1)
    {prefix, suffix}
  end

  defp forward_measurements(metric_prefix, measurements, tags) do
    Enum.each(measurements, fn
      {:duration, value} ->
        ms = System.convert_time_unit(value, :native, :millisecond)
        Appsignal.add_distribution_value("#{metric_prefix}_duration", ms, tags)

      {key, value} when is_number(value) ->
        Appsignal.add_distribution_value("#{metric_prefix}_#{key}", value, tags)

      _ ->
        :skip
    end)
  end

  defp to_tags(metadata) do
    metadata
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new(fn {k, v} -> {k, to_string(v)} end)
  end
end
