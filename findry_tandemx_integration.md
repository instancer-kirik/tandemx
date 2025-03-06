# Findry - TandemX Integration Design

## Overview
Findry will be integrated into TandemX as a specialized module focusing on creative space matching and resource optimization. This integration leverages TandemX's existing node-based architecture while extending it with Findry-specific features.

## Data Model Extensions

### New Node Types
Extending the existing `node_type` enum:
```sql
ALTER TYPE node_type ADD VALUE 'space' AFTER 'resource';
ALTER TYPE node_type ADD VALUE 'artist' AFTER 'space';
ALTER TYPE node_type ADD VALUE 'project' AFTER 'artist';
```

### Space Node Properties
```sql
CREATE TABLE space_properties (
    node_id TEXT PRIMARY KEY REFERENCES nodes(id) ON DELETE CASCADE,
    space_type TEXT NOT NULL,
    square_footage INTEGER,
    equipment_list JSONB,
    availability_schedule JSONB,
    pricing_terms JSONB,
    acoustics_rating INTEGER,
    lighting_details JSONB,
    access_hours JSONB,
    location_data JSONB,
    photos TEXT[],
    virtual_tour_url TEXT
);
```

### Artist/Project Node Properties
```sql
CREATE TABLE artist_properties (
    node_id TEXT PRIMARY KEY REFERENCES nodes(id) ON DELETE CASCADE,
    creative_discipline TEXT[],
    space_requirements JSONB,
    project_timeline TSRANGE,
    budget_range INT4RANGE,
    equipment_needs JSONB,
    preferred_hours JSONB,
    portfolio_urls TEXT[],
    group_size INTEGER,
    noise_level INTEGER
);
```

## Integration Points

### Core TandemX Features
1. Node Graph Visualization
   - Spaces and artists as interactive nodes
   - Resource connections showing availability
   - Visual space relationships

2. Real-time Collaboration
   - Space viewing coordination
   - Resource booking synchronization
   - Multi-user virtual tours

3. Resource Management
   - Equipment tracking
   - Space availability
   - Booking management

### New Findry-Specific Features
1. Space Discovery Interface
   - Map-based exploration
   - Visual space browsing
   - Advanced filtering

2. Matching System
   - Smart compatibility scoring
   - Availability checking
   - Budget alignment

3. Booking Management
   - Calendar integration
   - Access control
   - Usage tracking

## Technical Implementation

### Backend Services
1. Space Service (Gleam)
   ```gleam
   // Space management and matching logic
   pub type Space {
     id: String
     properties: SpaceProperties
     availability: AvailabilityManager
     booking_state: BookingState
   }
   
   pub fn match_spaces(requirements: Requirements) -> List(Space) {
     // Implement matching algorithm
   }
   ```

2. Booking Service (Gleam)
   ```gleam
   pub type Booking {
     space_id: String
     user_id: String
     time_range: TimeRange
     status: BookingStatus
   }
   
   pub fn create_booking(space: Space, user: User) -> Result(Booking, Error) {
     // Implement booking logic
   }
   ```

3. Resource Optimization Service (Zig)
   ```zig
   pub fn optimizeResourceAllocation(
       spaces: []Space,
       requirements: []Requirement
   ) OptimizationResult {
       // Implement resource optimization
   }
   ```

### Frontend Components
1. Space Explorer
   ```typescript
   interface SpaceExplorer {
     map: MapComponent;
     filters: FilterPanel;
     results: SpaceList;
     calendar: AvailabilityCalendar;
   }
   ```

2. Booking Interface
   ```typescript
   interface BookingManager {
     calendar: BookingCalendar;
     resourceList: ResourcePanel;
     accessControl: AccessManager;
   }
   ```

## Development Phases

### Phase 1: Core Integration
1. Database schema extensions
2. Basic space/artist node types
3. Simple matching system

### Phase 2: Enhanced Features
1. Advanced matching algorithm
2. Resource optimization
3. Virtual tours

### Phase 3: Community Features
1. Resource sharing network
2. Collaborative spaces
3. Event integration

## Success Metrics
1. Space utilization rate
2. Matching accuracy
3. Booking completion rate
4. User satisfaction
5. Resource efficiency

## Security Considerations
1. Access control
2. Payment processing
3. User verification
4. Data privacy
5. Insurance verification

## Next Steps
1. Implement database schema extensions
2. Create basic space/artist node types
3. Develop simple matching system
4. Set up booking management
5. Integrate with existing TandemX visualization 