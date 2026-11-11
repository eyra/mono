# `Next.Systems.Onyx.SeedBase`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/onyx/seed_base.ex#L1)

Base macros and functions for seeding ontology concepts and annotations.

Provides common macros for creating concepts, annotations, and relationships
used across different seed modules with a clean DSL.

# `annotate_definition`
*macro* 

Macro for annotating a concept with a definition.

# `defcategory`
*macro* 

Macro for categorizing subjects under an object using the subsumes predicate.

# `defconcept`
*macro* 

Macro for defining a concept with a phrase and text description.

# `defconcepts`
*macro* 

Macro for defining multiple concepts from a keyword list.

# `deftype`
*macro* 

Macro for defining a type concept (alias for defconcept).

# `format_concept_name`

Formats concept names by capitalizing words if no capital letters are present.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
