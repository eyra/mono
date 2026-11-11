# `Frameworks.Signal.LiveFeature`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/signal/_live_feature.ex#L1)

Swallows the `{:signal_test, _}` message that `Frameworks.Signal.TestRecorder`
sends back to the dispatching process during tests with `isolate_signals/1`.

Without this stub, any LiveView that dispatches a signal from its own process
would crash with `no function clause matching` in the test environment.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
