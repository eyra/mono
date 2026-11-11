# `Next.Systems.Paper.RISProcessor`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/paper/ris_processor.ex#L1)

Business logic for processing parsed RIS references.

Handles:
- Checking if papers already exist in the database
- Building changesets for new papers
- Categorizing references as new/existing/error

# `build_paper_changeset`

Create a changeset for a new paper (only call during actual import).
Accepts either a map with atom keys or a RISEntry struct.

# `build_summary`

Build summary statistics from processed references.

# `format_references`

Format processed references for API response.

# `process_references`

Process parsed RIS references and categorize them.

Takes parsed reference data from RISParser and:
1. Validates the reference data
2. Detects intrinsic duplicates within the file
3. Checks if papers already exist in the database
4. Builds changesets for new papers

Returns categorized references ready for import.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
