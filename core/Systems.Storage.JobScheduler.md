# `Systems.Storage.JobScheduler`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/storage/job_scheduler.ex#L1)

Behaviour for scheduling storage delivery jobs.
Wraps Oban to allow mocking in tests.

# `insert`

```elixir
@callback insert(Oban.Job.changeset()) ::
  {:ok, Oban.Job.t()} | {:error, Ecto.Changeset.t()}
```

# `insert`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
