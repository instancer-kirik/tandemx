# Brand & Venue Interface Technical Implementation Plan

## Overview

This document outlines the technical implementation plan for the Brand & Venue Interface, focusing on how it will integrate with the existing Findry system and calendar components. The implementation will follow a phased approach, with Phase 1 focusing on core marketplace functionality and Phase 2 expanding to advanced event planning features.

## System Architecture

### High-Level Architecture

```
+-----------------------------------------------------+
|                  TandemX Platform                   |
+-----------------------------------------------------+
|                                                     |
|  +-------------------+      +-------------------+   |
|  |                   |      |                   |   |
|  |  Findry System    |<---->|  Brand & Venue    |   |
|  |  (Artist-Space    |      |  Interface        |   |
|  |   Matching)       |      |  (Artist-Brand    |   |
|  |                   |      |   Matching)       |   |
|  +-------------------+      +-------------------+   |
|           ^                          ^              |
|           |                          |              |
|           v                          v              |
|  +-------------------+      +-------------------+   |
|  |                   |      |                   |   |
|  |  Shared Calendar  |<---->|  Shared User      |   |
|  |  System           |      |  Authentication    |   |
|  |                   |      |                   |   |
|  +-------------------+      +-------------------+   |
|                                                     |
+-----------------------------------------------------+
```

### Component Breakdown

1. **Frontend Components**
   - Artist Interface (Opportunity discovery, application management)
   - Brand/Venue Interface (Artist discovery, opportunity management)
   - Shared Calendar UI (Booking visualization, availability management)
   - Notification Center (Alerts for invitations, application updates)

2. **Backend Services**
   - Opportunity Management Service
   - Application/Invitation Processing Service
   - Matching Algorithm Service
   - Booking Management Service
   - Notification Service

3. **Data Stores**
   - Brand/Venue Profiles
   - Opportunities
   - Applications/Invitations
   - Bookings
   - Calendar Events

## Integration Points with Existing Systems

### Findry Integration

The Brand & Venue Interface will integrate with the existing Findry system in the following ways:

1. **User Authentication**
   - Extend the current authentication system to include brand/venue user types
   - Share login sessions across both systems
   - Maintain consistent permission models

2. **Artist Profiles**
   - Reuse existing artist profile data from Findry
   - Extend profiles with additional fields relevant to brand/venue matching
   - Ensure profile updates propagate across both systems

3. **Matching Algorithm**
   - Extend Findry's existing matching algorithm to include brand/venue preferences
   - Share common matching criteria (genre, location, etc.)
   - Implement specialized matching for event-specific requirements

4. **Notification System**
   - Integrate with existing notification infrastructure
   - Ensure consistent notification styling and behavior
   - Implement new notification types for opportunities and invitations

### Calendar Integration

The Brand & Venue Interface will leverage the existing calendar system:

1. **Event Representation**
   - Extend the current `Meeting` type to include `Booking` events
   - Add new event types for opportunities and applications
   - Ensure consistent visual representation across systems

2. **Availability Management**
   - Reuse the existing time slot selection UI
   - Implement conflict detection between Findry bookings and Brand/Venue bookings
   - Provide unified availability view for artists

3. **Scheduling Logic**
   - Extend the scheduling algorithm to handle the complexity of event bookings
   - Implement buffer times between events
   - Support recurring events for regular gigs

## Technical Implementation Details

### Frontend Implementation

The frontend will be built using the same Gleam/Lustre stack as the existing system:

```gleam
// Example of an Opportunity type in Gleam
pub type Opportunity {
  Opportunity(
    id: String,
    brand_id: String,
    title: String,
    description: String,
    event_type: String,
    compensation: Compensation,
    requirements: Requirements,
    location: Location,
    date_range: DateRange,
    time_slots: List(TimeSlot),
    application_deadline: String,
    status: OpportunityStatus,
    visibility: Visibility,
    created_at: Int,
    updated_at: Int
  )
}

pub type OpportunityStatus {
  Draft
  Published
  Closed
  Filled
}

pub type Visibility {
  Public
  Private
  InviteOnly
}

// Example of a Brand/Venue profile type
pub type BrandVenueProfile {
  BrandVenueProfile(
    id: String,
    name: String,
    profile_type: ProfileType,
    description: String,
    location: Location,
    contact: Contact,
    social_media: SocialMedia,
    logo: String,
    photos: List(String),
    verified: Bool,
    created_at: Int,
    updated_at: Int
  )
}

pub type ProfileType {
  Brand
  Venue
  Organizer
}
```

### Backend Implementation

The backend will extend the existing API with new endpoints:

1. **Opportunity Management**
   - `POST /api/opportunities` - Create a new opportunity
   - `GET /api/opportunities` - List opportunities with filtering
   - `GET /api/opportunities/:id` - Get opportunity details
   - `PUT /api/opportunities/:id` - Update an opportunity
   - `DELETE /api/opportunities/:id` - Delete an opportunity

2. **Application Management**
   - `POST /api/opportunities/:id/applications` - Apply to an opportunity
   - `GET /api/applications` - List user's applications
   - `GET /api/opportunities/:id/applications` - List applications for an opportunity
   - `PUT /api/applications/:id` - Update application status

3. **Invitation Management**
   - `POST /api/artists/:id/invitations` - Invite an artist
   - `GET /api/invitations` - List invitations
   - `PUT /api/invitations/:id` - Update invitation status

4. **Booking Management**
   - `POST /api/bookings` - Create a booking
   - `GET /api/bookings` - List bookings
   - `PUT /api/bookings/:id` - Update booking details
   - `DELETE /api/bookings/:id` - Cancel a booking

### Database Schema Extensions

The following tables will be added to the existing database schema:

```sql
CREATE TABLE brand_venue_profiles (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  profile_type TEXT NOT NULL,
  description TEXT,
  location_json TEXT NOT NULL,
  contact_json TEXT NOT NULL,
  social_media_json TEXT,
  logo_url TEXT,
  photos_json TEXT,
  verified BOOLEAN DEFAULT FALSE,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE opportunities (
  id TEXT PRIMARY KEY,
  brand_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  event_type TEXT NOT NULL,
  compensation_json TEXT NOT NULL,
  requirements_json TEXT,
  location_json TEXT NOT NULL,
  date_range_json TEXT NOT NULL,
  time_slots_json TEXT,
  application_deadline TEXT,
  status TEXT NOT NULL,
  visibility TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (brand_id) REFERENCES brand_venue_profiles(id)
);

CREATE TABLE applications (
  id TEXT PRIMARY KEY,
  opportunity_id TEXT NOT NULL,
  artist_id TEXT NOT NULL,
  message TEXT,
  portfolio_items_json TEXT,
  availability_json TEXT,
  status TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (opportunity_id) REFERENCES opportunities(id),
  FOREIGN KEY (artist_id) REFERENCES users(id)
);

CREATE TABLE invitations (
  id TEXT PRIMARY KEY,
  brand_id TEXT NOT NULL,
  artist_id TEXT NOT NULL,
  opportunity_id TEXT,
  message TEXT,
  proposed_dates_json TEXT,
  status TEXT NOT NULL,
  expiration_date TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (brand_id) REFERENCES brand_venue_profiles(id),
  FOREIGN KEY (artist_id) REFERENCES users(id),
  FOREIGN KEY (opportunity_id) REFERENCES opportunities(id)
);

CREATE TABLE bookings (
  id TEXT PRIMARY KEY,
  opportunity_id TEXT,
  artist_id TEXT NOT NULL,
  brand_id TEXT NOT NULL,
  date TEXT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT NOT NULL,
  status TEXT NOT NULL,
  payment_status TEXT NOT NULL,
  contract_id TEXT,
  notes TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (opportunity_id) REFERENCES opportunities(id),
  FOREIGN KEY (artist_id) REFERENCES users(id),
  FOREIGN KEY (brand_id) REFERENCES brand_venue_profiles(id)
);
```

## Calendar Integration Implementation

### Extending the Calendar Model

We'll extend the existing calendar model to support the new booking types:

```gleam
// Current Meeting type in calendar.gleam
pub type Meeting {
  Meeting(
    id: String,
    title: String,
    description: String,
    date: String,
    start_time: String,
    duration_minutes: Int,
    attendees: List(String),
    timezone: String,
  )
}

// New Booking type to be added
pub type Booking {
  Booking(
    id: String,
    title: String,
    description: String,
    date: String,
    start_time: String,
    end_time: String,
    artist_id: String,
    brand_id: String,
    opportunity_id: Option(String),
    status: BookingStatus,
    payment_status: PaymentStatus,
    location: Location,
    notes: String,
  )
}

pub type BookingStatus {
  Confirmed
  Canceled
  Completed
}

pub type PaymentStatus {
  Pending
  Paid
  Disputed
}
```

### Calendar View Integration

We'll modify the calendar view to display bookings alongside meetings:

```gleam
fn view_day_bookings(date: String, bookings: List(Booking)) -> Element(Msg) {
  let day_bookings = list.filter(bookings, fn(booking) { booking.date == date })
  html.div(
    [class("day-bookings")],
    list.map(day_bookings, fn(booking) {
      html.div([
        class("booking " <> string.lowercase(booking.status)),
        event.on_click(ViewBookingDetails(booking.id)),
      ], [
        html.text(booking.title <> " (" <> booking.start_time <> "-" <> booking.end_time <> ")"),
      ])
    }),
  )
}

// Update the view_day function to include bookings
fn view_day(
  day: DayData,
  system: CalendarSystem,
  meetings: List(Meeting),
  bookings: List(Booking),
  selected_date: Option(String),
) -> Element(Msg) {
  // ... existing code ...
  html.div(
    [
      // ... existing attributes ...
    ],
    [
      // ... existing elements ...
      view_day_meetings(day.date, meetings),
      view_day_bookings(day.date, bookings),
    ],
  )
}
```

### Booking Creation Integration

We'll integrate the booking creation with the existing scheduling modal:

```gleam
fn view_scheduling_modal(model: Model) -> Element(Msg) {
  case model.schedule_state {
    // ... existing cases ...
    
    SchedulingOpportunity(opportunity, date, time) ->
      html.div([class("scheduler-dialog")], [
        html.div([class("scheduler-header")], [
          html.h2([], [html.text("Book Artist for Opportunity")]),
          // ... rest of the modal ...
        ]),
        // ... opportunity-specific booking form ...
      ])
  }
}
```

## Integration with Findry.js

We'll extend the existing Findry JavaScript code to support the new brand/venue interface:

```javascript
// New functions to add to findry.js

// Handle brand/venue profile updates
function updateBrandProfile(brandProfile) {
  // Update brand profile in the UI
}

// Handle opportunity updates
function updateOpportunity(opportunity) {
  // Update opportunity in the UI
}

// Handle application status changes
function updateApplicationStatus(application) {
  // Update application status in the UI
}

// Handle invitation status changes
function updateInvitationStatus(invitation) {
  // Update invitation status in the UI
}

// Extend the existing WebSocket message handler
function handleMessage(message) {
  const [type, ...params] = message.split(':');
  
  switch(type) {
    // ... existing cases ...
    
    case 'brand_profile_updated':
      const brandProfile = JSON.parse(params[0]);
      updateBrandProfile(brandProfile);
      break;
      
    case 'opportunity_created':
    case 'opportunity_updated':
      const opportunity = JSON.parse(params[0]);
      updateOpportunity(opportunity);
      break;
      
    case 'application_status_changed':
      const application = JSON.parse(params[0]);
      updateApplicationStatus(application);
      break;
      
    case 'invitation_received':
    case 'invitation_status_changed':
      const invitation = JSON.parse(params[0]);
      updateInvitationStatus(invitation);
      break;
  }
}
```

## Phase 1 Implementation Timeline

### Week 1-2: Database and API Design

- Design and implement database schema extensions
- Create API specifications for new endpoints
- Implement core API endpoints for opportunities and profiles

### Week 3-4: Authentication and Profile Management

- Extend user authentication to include brand/venue types
- Implement brand/venue profile creation and management
- Create admin tools for profile verification

### Week 5-6: Opportunity Management

- Implement opportunity creation and management
- Build opportunity discovery interface for artists
- Create application submission and tracking system

### Week 7-8: Calendar Integration

- Extend calendar system to support bookings
- Implement availability management
- Create booking confirmation workflow

### Week 9-10: Invitation System

- Implement artist discovery for brands/venues
- Build invitation creation and management
- Create invitation response workflow

### Week 11-12: Testing and Launch Preparation

- Comprehensive testing of all components
- Performance optimization
- Documentation and user guides
- Soft launch to select users

## Phase 2 Implementation Considerations

For Phase 2, we'll need to consider the following technical aspects:

1. **Contract Management**
   - Integration with digital signature services
   - Template management system
   - Version control for contracts

2. **Payment Processing**
   - Integration with payment gateways
   - Escrow service implementation
   - Automated invoicing system

3. **Advanced Event Planning**
   - Timeline and checklist management
   - Vendor coordination tools
   - Budget tracking system

4. **Analytics and Reporting**
   - Data warehouse integration
   - Custom report generation
   - Performance dashboards

## Conclusion

This technical implementation plan provides a roadmap for integrating the Brand & Venue Interface with the existing Findry system and calendar components. By leveraging the existing architecture and extending it with new functionality, we can create a seamless experience for both artists and brands/venues while minimizing development overhead.

The phased approach allows for incremental delivery of value, with Phase 1 focusing on the core marketplace functionality and Phase 2 expanding to more advanced features. This approach reduces risk and allows for user feedback to inform later development stages. 