# Paper

System for managing Paper resources. Supports importing RIS format reference files.

## Dependencies

```mermaid
    flowchart BT
    Paper --> Content
```

## Data model

  ```mermaid
    classDiagram

    Content.FileModel <-- ReferenceFileModel
    ReferenceFileModel --> "many" Model
    ReferenceFileModel --> "many" ReferenceFileErrorModel
    Model <-- RISModel
  ```

## Public Use Cases

### Prepare Reference File

The reference file is created but not inserted in the database yet

```mermaid
sequenceDiagram
    Caller-)Public: prepare reference file (original filename)
    create participant File as Content.FileModel
    Public -->> File: create (original filename)
    create participant ReferenceFile as ReferenceFileModel
    Public -->> ReferenceFile: create (content file)
```

### Update Reference File

```mermaid
sequenceDiagram
    Caller-)Public: update reference file (url)
    Public ->> Content.FileModel: change url
    Public ->> CoreWeb.Repo: update (content file)
```

### Processing Reference File

Asynchronous process to persist all valid (RIS) references found in the file. When processing the reference file has finished, the signal `{:paper_reference_file, :updated}` will be dispatched.

```mermaid
sequenceDiagram
    Caller->>+Public: start processing reference file (id)
    create participant Job as RISImportJob
    Public->>Job:<<new>>
    Public-)Oban: insert job
    Public->>-Caller:
    Oban->>+Job: perform
    Job->>+RISFile: process
    RISFile->>RISFile: parse paper references
    RISFile->>Repo: insert paper models
    RISFile->>Signal.Public: dispatch {:paper_reference_file, :updated}
    RISFile-->>-Job:
    Job-->>-Oban:
```

### Archive Reference File

```mermaid
sequenceDiagram
    Caller->>Public: archive reference file (id)
    Public->>ReferenceFileModel: set status :archived
    Public ->> CoreWeb.Repo: update (reference file)

```