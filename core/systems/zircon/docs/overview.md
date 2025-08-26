# Zircon

A comprehensive Literature Review application designed to streamline the review process. It comprises two distinct tools, each representing a key phase of a Literature Review:

* Screening Phase: Title and Abstract Review
* Selection Phase: Full-Text Review

# Dependencies

```mermaid
flowchart BT

Zircon --> Paper
Zircon --> Annotation
Annotation --> Ontology
Paper --> Content
```

# Tools

## Screening

### Data Model

  ```mermaid
  classDiagram
    Ontology.TermModel <-- Annotation.Model
    Paper.ReferenceFileModel "many" <-- Screening.ToolModel
    Annotation.Model "many" <-- Screening.ToolModel
    Paper.Model "many" <-- Paper.ReferenceFileModel
  ```

### Page composition

#### Content Page

```mermaid
flowchart
    subgraph assignment_page[Assignment.ContentPage]
        subgraph monitor_tab[MonitorView]
        end
        monitor_tab:::tab
        subgraph criteria_tab[Screening.CriteriaView]
        end
        criteria_tab:::tab
        subgraph import_tab[Screening.ImportView]
            subgraph import_form[Screening.ImportForm]

            end
            import_form:::form
        end
        import_tab:::tab

    end
    assignment_page:::page

    classDef page fill:#4272EF, stroke:none, color:#ffffff
    classDef tab fill:#FFCF60, stroke:none, color:#000000
    classDef form fill:#FF5E5E, stroke:none, color:#ffffff
```

### Import reference file

#### Upload and start processing file

```mermaid
sequenceDiagram
    CoreWeb.FileUploader-->>Screening.ImportForm: file_upload_start
    Screening.ImportForm->>Public: insert_reference_file!
    Public->>Paper.Public: prepare_reference_file
    create participant Screening.ToolReferenceFileAssoc
    Public->>Screening.ToolReferenceFileAssoc: create
    CoreWeb.FileUploader-->>Screening.ImportForm: process_file
    Screening.ImportForm->>Paper.Public: update_reference_file!
    Screening.ImportForm->>Paper.Public: start_processing_reference_file
```

#### Reference file updated event

When processing the reference file has finished, the Paper system will dispatch a {:paper_reference_file, :updated} signal. This will eventually lead to an update of the Assignment.ContentPage containing the Screening.ImportForm.

```mermaid
sequenceDiagram
    Signal.Public->>Zircon.Switch: signal_a={:paper_reference_file, :updated}
    Zircon.Switch-->>Signal.Public: signal_b={:zircon_screening_tool, signal_a}
    Signal.Public->>Assignment.Switch: signal_b {:zircon_screening_tool, signal_a}
    Assignment.Switch-->>Signal.Public: signal_c {:assignment, signal_b}
    Signal.Public->>Assignment.Switch: signal_c {:assignment, signal_b}
    Assignment.Switch-->>Signal.Public: signal_e {:page, Assignment.ContentPage}
    Signal.Public->>Observatory.Switch: signal_e {:page, Assignment.ContentPage} => Realtime Update Page

```

## Selection

Our current focus is on the development and refinement of the Screening tool.


