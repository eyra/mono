## Nova migration

`core/` is being split into **Mica** (generic, owned by Nova Software Foundation) and **Next** (Eyra's SaaS on Mica). The [plan](docs/nova-migration/plan.md) and [design](docs/nova-migration/design.md) are the source of truth. Every change follows these rules now:

- No new PaNL, VU or other Eyra specifics in generic systems.
- Systems contribute through `Mica.System`: one `_system.ex` (`Systems.X.System`) per system; the SaaS composes them through `Mica.SaaS` (`Next.SaaS`, `MicaSaas.SaaS`). New pages, routes and grants go in the system's `_system.ex` (`routes/0`, `grants/0`), not in `core/mica/lib/mica/authorization.ex` or `core/mica/lib/mica_web/routes.ex`.
- Mica only contains code under Nova governance; custom and experimental systems start in Next.
- One database. Every table is owned by Mica or by the SaaS; foreign keys only point from the SaaS to Mica.
- New code goes in the folder of its future owner: `core/mica/`, `core/next/`, or `core/mica_saas/` for the Self reference SaaS. Code under `core/mica/` must not name SaaS modules (Next or Self) or hard-code PaNL, VU or Eyra specifics, and `core/next/` and `core/mica_saas/` must not name each other's modules. CI enforces this with `core/scripts/boundary_check.exs` and `core/boundary_allowlist.exs`; the allowlist may only shrink.

## Translation guidance

Use the [translating](.agents/skills/translating/SKILL.md) skill while developing code that adds or changes participant-facing copy, including Gettext translations.

## Learnings

### Bcrypt hash escaping over SSH

When setting bcrypt hashes via SSH + psql, the `$` characters get interpreted by bash at multiple levels.

**NEVER try to pass bcrypt hashes directly through nested SSH commands.**

Instead, use one of these approaches:

1. **Use IEx remote console with `rpc` command** (preferred):
   ```bash
   ssh bastion "ssh server 'sudo -u next /home/next/current/bin/core rpc \"
     Mica.Repo.get_by(Systems.Account.User, email: \\\"user@example.com\\\")
     |> Systems.Account.User.changeset(%{})
     |> Ecto.Changeset.put_change(:hashed_password, \\\"HASH_HERE\\\")
     |> Mica.Repo.update()
   \"'"
   ```

2. **Write hash to a file on the server first**, then use it in SQL

3. **Connect interactively** and paste the hash directly

The bcrypt hash format `$2b$04$...` contains `$` which bash interprets as variable expansion, turning it into garbage like `bbash4`.

### Bash `!` character in passwords

When using passwords with `!` in bash/curl commands, always use `$'...'` syntax:
```bash
# WRONG - ! causes history expansion issues
curl -d '{"password":"LoadTest123!"}'

# CORRECT - use $'...' syntax
curl -d $'{"password":"LoadTest123!"}'
```

### AWS Dev Environment (next.dev.eyra.co)

- **Assignment ID for load testing:** 458
- **Service user:** loadtest@eyra.service
- **SERVICE_LOGIN_KEY:** not stored in the repo; read it from the `SERVICE_LOGIN_KEY` env var on the target server