# `Mica.AppSignal.TelemetryHandler`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/appsignal/telemetry_handler.ex#L1)

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

Call `Mica.AppSignal.TelemetryHandler.attach()` at application startup.
Add new event prefixes to `@event_prefixes`.

# `attach`

# `attach`

# `handle_event`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
