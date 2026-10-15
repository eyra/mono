# Annotation

## Dependencies

```mermaid
    flowchart BT
    Annotation --> Ontology
    Annotation --> Account
```

## Data model

  ```mermaid
    classDiagram

    Ontology.TermModel <-- Model
    Account.User <-- Model
  ```