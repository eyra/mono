# Onyx System

## Overview

Onyx is a knowledge browser system built on top of the Annotation and Ontology systems. It provides an intuitive, interactive interface for exploring, filtering, and navigating semantic knowledge structures within the EYRA platform. As a pure browsing interface, Onyx contains no data models of its own but instead provides sophisticated visualization and navigation capabilities over existing knowledge systems.

## Purpose

- **Human-AI Collaboration Interface**: Visual platform for human-AI knowledge interaction
- **Validation Dashboard**: Interface for humans to validate AI-synthesized knowledge
- **Knowledge Evolution Viewer**: Real-time visualization of knowledge formalization process
- **Truth Verification Platform**: Tools for collaborative validation of AI discoveries

## Architecture

### System Design

#### Pure Interface Pattern
- **No Data Models**: Onyx contains no database tables or models
- **View Layer Only**: Focuses purely on presentation and interaction
- **System Composition**: Builds on existing Annotation and Ontology data
- **Real-time Integration**: Live updates from underlying knowledge systems

#### Component Architecture
```
Landing Page (Entry Point)
    ├── Tabbed Interface (3 tabs)
    ├── Browser View (Filterable content)
    ├── Card Display (Knowledge items)
    └── Detail Views (Modal presentations)
```

## Core Components

### Landing Page (`landing_page.ex`)
- **Main Entry Point**: Accessible at `/onyx` route
- **Tabbed Navigation**: Three main content categories
- **Observatory Integration**: Uses singleton pattern for system-wide access
- **Event Handling**: Manages model selection and view updates

### Browser View (`browser_view.ex` & `browser_view_builder.ex`)
- **Dynamic Content**: Displays filtered cards based on active filters
- **Filter Management**: Handles annotation, concept, and predicate filters
- **Search Integration**: Text-based search with real-time filtering
- **Responsive Layout**: Grid-based card presentation

### Tab Components
- **Annotation Tab** (`annotation_tab.ex`): User annotations with metadata
- **Concept Tab** (`concept_tab.ex`): Ontological concepts
- **Predicate Tab** (`predicate_tab.ex`): Semantic relationships

### View Components
- **Card View** (`card_view.ex`): Consistent card-based presentation
- **Annotation View** (`annotation_view.ex`): Detailed annotation display
- **Concept View** (`concept_view.ex` & `concept_view_builder.ex`): Concept exploration
- **Predicate View** (`predicate_view.ex`): Relationship visualization

## Knowledge Browsing Capabilities

### Filter System
```elixir
@filter_keys %{
  :root => [:annotation, :concept, :predicate],
  Systems.Ontology.ConceptModel => [:annotation, :predicate],
  Systems.Ontology.PredicateModel => [:annotation, :concept],
  Systems.Annotation.Model => [:annotation, :concept, :predicate]
}
```

#### Dynamic Filtering
- **Content Type Filters**: Toggle visibility of annotations, concepts, predicates
- **Search Functionality**: Text-based search across all knowledge types
- **Interactive Updates**: Real-time content filtering without page refresh
- **Context-Aware Filters**: Different filter options based on selected content

### Navigation Features
- **Hierarchical Browsing**: Drill-down from overview to detailed views
- **Cross-References**: Navigate between related knowledge items
- **Card Interactions**: Click cards to open detailed modal views
- **Breadcrumb Navigation**: Track navigation path through knowledge structures

### Data Integration
- **Multi-System Queries**: Aggregates data from Annotation and Ontology systems
- **Entity Scoping**: Respects user permissions and entity ownership
- **Real-time Updates**: Live content updates as underlying data changes
- **Performance Optimization**: Efficient querying with preload strategies

## User Interface

### Visual Design
- **Card-Based Layout**: Consistent presentation across all content types
- **Color Coding**: Visual distinction between different knowledge types
- **Tag System**: Content categorization with visual indicators
- **Responsive Grid**: Adaptive layout for different screen sizes

### Interactive Elements
- **Tabbed Interface**: Easy switching between content categories
- **Filter Toggles**: Quick enable/disable of content type filters
- **Search Bar**: Real-time text-based filtering
- **Modal Views**: Detailed presentations without leaving main interface

### User Experience
- **Intuitive Navigation**: Clear visual hierarchy and navigation patterns
- **Progressive Disclosure**: Overview to detail browsing pattern
- **Live Updates**: Real-time content updates without manual refresh
- **Accessibility**: Semantic HTML and keyboard navigation support

## System Integration

### Human-AI Knowledge Collaboration

#### Annotation System Integration (Human Input Layer)
- **Natural Language Display**: Shows human annotations in intuitive format
- **AI-Generated Annotations**: Displays AI-created annotations for human validation
- **Validation Interface**: Tools for humans to approve/reject AI-synthesized knowledge
- **Feedback Collection**: Captures human validation decisions for AI learning

#### Ontology System Integration (Formal Knowledge Layer)
- **AI Discoveries**: Visualizes concepts and predicates discovered by AI agents
- **Formalization Progress**: Shows real-time conversion of annotations to formal knowledge
- **Truth Validation**: Presents AI-synthesized formal structures for human review
- **Knowledge Evolution**: Tracks growth and refinement of formal knowledge base

### Bidirectional Knowledge Flow Visualization

```
Human Annotations → [Onyx Display] → AI Processing → Formal Ontology
                                   ↓
Human Validation ← [Onyx Interface] ← AI-Generated Annotations ← AI Synthesis
```

#### Visual Validation Workflows
- **Discovery Presentation**: Shows new AI-discovered concepts and relationships
- **Validation Queue**: Organized interface for reviewing AI-synthesized knowledge
- **Consensus Building**: Aggregates multiple human validations for truth determination
- **Truth Tracking**: Visual indicators of validation status and confidence levels

### Authentication Integration
- **Entity-Based Access**: Shows content based on user's entity associations
- **Permission Respect**: Honors authorization system constraints
- **User Context**: Filters content based on user's access rights
- **Collaborative View**: Supports multi-entity collaborative knowledge exploration

## Public API

### Route Configuration
```elixir
# Single route for main interface
live("/onyx", Systems.Onyx.LandingPage)
```

### Component Interface
```elixir
# Reusable browser components
%{module: Systems.Onyx.BrowserView, params: %{...}}
%{module: Systems.Onyx.ConceptView, params: %{...}}
%{module: Systems.Onyx.AnnotationView, params: %{...}}
```

### Event System
- **Model Selection Events**: Handle knowledge item selection
- **Filter Change Events**: Respond to filter modifications
- **Search Events**: Process search input with debouncing
- **Navigation Events**: Manage hierarchical browsing

## Configuration Requirements

### System Dependencies
- **Annotation System**: Required for annotation data and references
- **Ontology System**: Needed for concept and predicate information
- **Observatory System**: Uses singleton model for system-wide state
- **Authentication**: User entity management and permissions
- **LiveNest**: Embedded live view components

### Route Registration
```elixir
# In systems/routes.ex
use Systems.Subroutes, [:onyx, ...]
```

### Internationalization
- **Gettext Domain**: `eyra-onyx` for translation strings
- **Multi-language**: Prepared for Dutch, English, and other languages
- **UI Labels**: All interface text externalized for translation

## Development Guidelines

### Performance Considerations
- **Efficient Queries**: Minimize database calls through strategic preloading
- **Caching Strategy**: Cache frequently accessed knowledge structures
- **Lazy Loading**: Load detailed views only when requested
- **Query Optimization**: Use query builders for complex multi-table joins

### User Experience
- **Responsive Design**: Ensure usability across device sizes
- **Progressive Enhancement**: Graceful degradation for limited browsers
- **Accessibility**: Proper semantic markup and keyboard navigation
- **Performance**: Fast loading and smooth interactions

### Integration Patterns
- **Loose Coupling**: Minimal dependencies on specific data structures
- **Event-Driven**: Use event system for component communication
- **Modular Design**: Reusable components for different browsing contexts
- **Error Handling**: Graceful handling of missing or invalid data

## Comparison with Other Systems

### vs. Zircon System
- **Onyx**: General-purpose knowledge browser for exploration
- **Zircon**: Specialized systematic literature review platform
- **Scope**: Onyx is broader, Zircon is domain-specific
- **Data**: Onyx browses existing data, Zircon processes new data

### vs. Annotation/Ontology Systems
- **Onyx**: Pure interface layer for browsing
- **Annotation/Ontology**: Data storage and management
- **Relationship**: Onyx visualizes what Annotation/Ontology store
- **Purpose**: Onyx enables exploration, others enable creation

## Future Enhancements

### Advanced Visualization
- **Graph Visualization**: Network views of knowledge relationships
- **Timeline Views**: Temporal browsing of knowledge evolution
- **Hierarchy Trees**: Tree-based concept hierarchy navigation
- **Interactive Maps**: Spatial representation of knowledge domains

### AI-Human Collaboration Features
- **Validation Workflows**: Streamlined interfaces for human validation of AI discoveries
- **Confidence Indicators**: Visual indicators of AI confidence in synthesized knowledge
- **Validation History**: Track human validation decisions and patterns
- **Learning Feedback**: Show how human feedback improves AI formalization accuracy

### AI Agent Integration
- **Real-time Processing**: Live display of AI agents processing annotations
- **Discovery Notifications**: Alerts when AI agents discover new knowledge patterns
- **Validation Prompts**: AI-generated questions targeting specific validation needs
- **Truth Synthesis**: Visual representation of AI knowledge synthesis process

### Collaborative Intelligence
- **Human-AI Teams**: Interface for human-AI collaborative knowledge building
- **Consensus Visualization**: Show agreement/disagreement between humans and AI
- **Knowledge Evolution**: Track how knowledge improves through human-AI interaction
- **Truth Verification**: Collaborative validation of synthesized knowledge claims
- **Global Commitment Readiness**: Visual indicators of when knowledge is ready for global blockchain commitment

### Future Public Knowledge Interface
- **Dissemination Dashboard**: Interface for preparing validated knowledge for public consumption
- **Global Knowledge Surfing**: Tools for citizens to explore state-of-art science
- **Knowledge Translation**: AI-powered translation of formal knowledge for different audiences
- **Attribution Visualization**: Clear display of researcher contributions to knowledge claims
- **Immutable Knowledge Browser**: Interface for exploring committed global knowledge blockchain

## Next Generation Knowledge System

As the **human-AI collaboration interface** for the "next generation knowledge system":

### Current Research Interface
- **Collaborative Intelligence Platform**: Visual interface for human-AI knowledge co-creation
- **Truth Validation Dashboard**: Tools for humans to validate AI-synthesized knowledge
- **Knowledge Evolution Viewer**: Real-time visualization of AI-driven knowledge formalization
- **Bidirectional Translation Interface**: Bridge between human intuition and AI formal reasoning

### Future Public Knowledge Interface
- **Global Knowledge Democracy**: Interface for committed knowledge accessible to all society
- **State-of-Art Science Surfing**: Citizens can explore current validated scientific knowledge
- **Multi-Audience Tools**: Specialized interfaces for journalists, teachers, students, researchers
- **Immutable Knowledge Browser**: Navigate blockchain-committed, attributable scientific knowledge
- **Public Science Translation**: AI-powered knowledge presentation for non-expert audiences
- **Democratic Knowledge Access**: Transform how society understands and accesses scientific truth