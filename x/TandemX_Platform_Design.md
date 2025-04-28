# TandemX Platform Design Document

## Overview

TandemX is a cooperation platform designed to integrate multiple creative and technical projects under a unified interface. It serves as both a showcase for these projects and a hub for collaboration, with particular emphasis on creative writing tools, including a poetry platform.

## Core Philosophy

The platform embraces these core principles:
- **Modularity**: Each component is self-contained but integrates seamlessly with others
- **Creativity**: Tools that enhance creative expression, particularly for writing
- **Collaboration**: Features that enable multiple users to work together
- **Technical Excellence**: Using modern web technologies and clean architecture

## Platform Architecture

### 1. Core Infrastructure

- **Backend**: Gleam/Erlang for robust, concurrent server operations
- **Frontend Options**:
  - Gleam + Lustre for consistent language across stack
  - TSX/React for rich UI components and wide ecosystem support
  - Custom rendering where appropriate
- **Data Persistence**:
  - PostgreSQL for relational data
  - Optional ElectricSQL for real-time sync (but can be disabled)

### 2. Project Hub

The central dashboard acting as a launchpad for all integrated projects:

- **Project Cards**: Visual representations of each project with quick access
- **Activity Feed**: Recent updates across all projects
- **Collaboration Status**: Who's working on what, in real-time
- **Quick Links**: Frequently accessed tools and documents

### 3. Poetry Platform

A dedicated space for poetry creation, sharing, and collaboration:

#### Features:
- **Composition Tools**:
  - Markdown-based editor with poetry-specific formatting
  - Syllable counter and rhyme suggestions
  - Metrical analysis tools
  - Version history
- **Collaboration Modes**:
  - Solo writing with optional sharing
  - Turn-based collaborative poems
  - Real-time collaborative editing
  - Exquisite corpse style creation
- **Publishing & Sharing**:
  - Public/private visibility controls
  - Social sharing integration
  - Collections and anthologies
  - Export to multiple formats (PDF, ePub)
- **Community Features**:
  - Comments and reactions
  - Poetry challenges and prompts
  - Featured poets and works

### 4. Integration with Existing Projects

#### ChartSpace
- Visual data representation tool
- Integrated with poetry analytics (patterns, themes, word usage)

#### Typer Integration
- Competitive retyping for poetry memorization
- Custom phrases from poetry collections
- Speed and accuracy metrics

#### Blog Integration
- Showcasing selected poems
- Context and analysis for poetry
- Writer profiles and portfolios

#### TypeScript/React Components ("Lovable TSX")
- Shareable UI components across projects
- Consistent styling and interaction patterns
- Custom poetry visualization components

## User Journeys

### Poetry Creator
1. Access poetry platform from main hub
2. Create new poem or continue existing work
3. Use composition tools for refinement
4. Optionally collaborate with others
5. Publish to personal collection
6. Share to blog or export

### Collaborator
1. Enter platform via invitation or open project
2. Join active session in poetry platform or other project
3. Contribute according to project parameters
4. View real-time updates from other contributors
5. Discuss via integrated communication tools
6. Track project evolution through version history

## Technical Implementation

### Backend Services
- **Authentication Service**: User management and permissions
- **Project Service**: Project metadata and access control
- **Poetry Service**: Poem storage, versioning, collaboration logic
- **Integration Service**: APIs for connecting with external tools

### Data Models

#### User
- ID, name, email, profile info
- Authentication details
- Project access permissions

#### Project
- ID, name, description, type
- Owner and collaborators
- Creation and modification dates
- Status and visibility settings

#### Poem
- ID, title, content (versioned)
- Author(s) and contributors
- Metadata (form, style, theme)
- Collaboration settings
- Version history

#### Collaboration Session
- ID, project reference
- Active participants
- Session state
- Communication log

## Development Roadmap

### Phase 1: Foundation
- Set up core infrastructure
- Implement basic project hub
- Create authentication system
- Develop API foundations

### Phase 2: Poetry Platform Core
- Build basic poetry composition tools
- Implement solo creation workflow
- Set up poetry storage and retrieval
- Create simple sharing mechanisms

### Phase 3: Collaboration Features
- Add real-time collaborative editing
- Implement turn-based poetry creation
- Develop commenting and feedback systems
- Create version control for poems

### Phase 4: Integration
- Connect with Typer for poetry memorization
- Integrate blog publishing capabilities
- Add ChartSpace visualizations for poetry metrics
- Implement cross-project notifications

### Phase 5: Community & Growth
- Build community features and discovery
- Add advanced poetry tools (rhyming dictionary, etc.)
- Implement collections and anthologies
- Develop public API for third-party integrations

## Technical Considerations

### Scalability
- Microservice architecture for independent scaling
- Stateless services where possible
- Efficient real-time communication (WebSockets)

### Performance
- Client-side rendering for interactive components
- Efficient data synchronization
- Lazy loading of resources

### Security
- Comprehensive authentication and authorization
- Content validation and sanitization
- Rate limiting and abuse prevention

### Accessibility
- Semantic HTML throughout
- ARIA attributes for complex components
- Keyboard navigation support
- Screen reader compatibility

## Deployment Considerations

### Development Environment
- Docker containers for consistent development
- Local database instances
- Hot reloading for rapid iteration

### Production Deployment
- Container orchestration (Kubernetes)
- CI/CD pipelines for automated testing and deployment
- Monitoring and alerting
- Backup and disaster recovery

## Design Language

A consistent design system across all projects:
- Typography optimized for reading poetry and code
- Color scheme that works for both creative and technical contexts
- Responsive layouts that prioritize content
- Animations and transitions that enhance understanding

## Conclusion

The TandemX platform will serve as both a showcase for your projects and a powerful tool for creative collaboration, particularly in poetry. By integrating existing tools like Typer and blog functionality with new poetry-specific features, you'll create a unique environment for writers and developers to work together seamlessly.

The modular architecture allows you to implement components incrementally and choose the most appropriate technology for each part, whether that's Gleam, TypeScript/React, or custom solutions. 