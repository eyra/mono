# `Frameworks.GreenLight.Loaders`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/green_light/loaders.ex#L1)

This is module that automates the loading of entities based on path parameters.

It is used by the authorization system to enforce access permissions against
the loaded entities.

# `call`

# `defloader`
*macro* 

Create a loader function using common Phoenix patterns. It assumes that the
parameter is named `id` and when used as part of a nested resource setup it
will be `key`_id.

It can thus be used like this:

  defloader(:assignment, &Systems.Assignment.Public.get!/1)

# `entities`

# `entity_loader`
*macro* 

# `init`

# `load_entities`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
