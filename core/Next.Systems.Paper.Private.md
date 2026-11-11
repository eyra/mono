# `Next.Systems.Paper.Private`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/paper/_private.ex#L1)

# `check_paper_exists`

Centralized function to check if a paper exists in the database.
Returns {:existing, paper} if found, :new if not found.

Logic:
- If paper has a DOI: check only by DOI (different DOIs = different papers)
- If paper has no DOI: check by title

# `get_paper_by_doi`

# `get_paper_by_title`

# `obtain_version!`

# `obtain_version!`

# `papers_match?`

Checks if a paper matches another based on DOI or title.
Used for detecting duplicates within a file.
Returns true if papers match, false otherwise.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
