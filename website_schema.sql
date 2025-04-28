-- Basic contact/interest form submissions
CREATE TABLE interest_submissions (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  project text NOT NULL,
  email text NOT NULL,
  name text NOT NULL,
  company text,
  message text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Meeting scheduling
CREATE TABLE meetings (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id),
  title text NOT NULL,
  description text,
  date date NOT NULL,
  start_time time NOT NULL,
  duration_minutes integer NOT NULL,
  timezone text NOT NULL DEFAULT 'UTC',
  location text,
  meeting_type text NOT NULL DEFAULT 'general', -- 'general', 'interview', 'follow_up', etc.
  status text NOT NULL DEFAULT 'scheduled',
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Meeting attendees junction table
CREATE TABLE meeting_attendees (
  meeting_id uuid REFERENCES meetings(id) ON DELETE CASCADE,
  contact_id uuid REFERENCES contacts(id) ON DELETE CASCADE,
  response_status text NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'tentative'
  added_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  response_updated_at timestamp with time zone,
  notes text,
  PRIMARY KEY (meeting_id, contact_id)
);

-- Meeting reminders
CREATE TABLE meeting_reminders (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  meeting_id uuid REFERENCES meetings(id) ON DELETE CASCADE,
  contact_id uuid REFERENCES contacts(id) ON DELETE CASCADE,
  reminder_time timestamp with time zone NOT NULL,
  reminder_type text NOT NULL, -- 'email', 'sms', 'push'
  status text NOT NULL DEFAULT 'pending', -- 'pending', 'sent', 'failed'
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(meeting_id, contact_id, reminder_time)
);

-- Calendar systems
CREATE TYPE calendar_system AS ENUM (
  'gregorian',
  'mayan_long_count',
  'mayan_tzolkin',
  'mayan_haab',
  'lunar',
  'chinese',
  'hebrew',
  'islamic'
);

-- Calendar epoch references
CREATE TABLE calendar_epochs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  calendar_system calendar_system NOT NULL,
  epoch_name text NOT NULL,
  gregorian_date timestamp with time zone NOT NULL,
  description text,
  UNIQUE(calendar_system, epoch_name)
);

-- Calendar cycles and periods
CREATE TABLE calendar_cycles (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  calendar_system calendar_system NOT NULL,
  cycle_name text NOT NULL,
  days_in_cycle integer,
  months_in_cycle integer,
  years_in_cycle integer,
  description text,
  UNIQUE(calendar_system, cycle_name)
);

-- Intercalary days and special periods
CREATE TABLE calendar_special_days (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  calendar_system calendar_system NOT NULL,
  day_name text NOT NULL,
  type text NOT NULL, -- 'intercalary', 'leap_day', 'special_period'
  calculation_rule text NOT NULL, -- SQL or algorithmic rule for determining occurrence
  duration_days integer NOT NULL DEFAULT 1,
  description text,
  cultural_significance text
);

-- Month definitions for different calendars
CREATE TABLE calendar_months (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  calendar_system calendar_system NOT NULL,
  month_number integer,
  month_name text NOT NULL,
  days_in_month integer,
  variable_length boolean DEFAULT false,
  length_calculation_rule text, -- For variable length months
  UNIQUE(calendar_system, month_number)
);

-- Mayan calendar specific
CREATE TABLE mayan_tzolkin_days (
  number integer NOT NULL CHECK (number >= 1 AND number <= 13),
  name text NOT NULL,
  meaning text,
  PRIMARY KEY (number, name)
);

CREATE TABLE mayan_haab_months (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  month_number integer NOT NULL CHECK (month_number >= 0 AND month_number <= 19),
  month_name text NOT NULL,
  meaning text,
  associated_events text[]
);

-- Chinese calendar specific
CREATE TABLE chinese_stems_branches (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  stem_number integer NOT NULL CHECK (stem_number >= 1 AND stem_number <= 10),
  stem_name text NOT NULL,
  branch_number integer NOT NULL CHECK (branch_number >= 1 AND branch_number <= 12),
  branch_name text NOT NULL,
  zodiac_animal text NOT NULL,
  element text NOT NULL,
  UNIQUE(stem_number, branch_number)
);

-- Calendar events
CREATE TABLE calendar_events (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  title text NOT NULL,
  description text,
  start_timestamp timestamp with time zone NOT NULL,
  end_timestamp timestamp with time zone NOT NULL,
  calendar_system calendar_system NOT NULL DEFAULT 'gregorian',
  original_date_string text, -- Stores date in original calendar system format
  native_date_components jsonb, -- Stores structured representation of date in native calendar
  recurrence_rule text, -- iCal RRULE format for recurring events
  category text,
  color text,
  user_id uuid REFERENCES auth.users(id),
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Calendar system conversions cache
CREATE TABLE calendar_conversions (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  source_system calendar_system NOT NULL,
  target_system calendar_system NOT NULL,
  source_date text NOT NULL,
  source_components jsonb NOT NULL, -- Structured representation of source date
  converted_date text NOT NULL,
  converted_components jsonb NOT NULL, -- Structured representation of converted date
  astronomical_jdn numeric(10,2) NOT NULL, -- Julian Day Number for astronomical reference
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(source_system, target_system, source_date)
);

-- Calendar user preferences
CREATE TABLE calendar_preferences (
  user_id uuid REFERENCES auth.users(id) PRIMARY KEY,
  default_system calendar_system NOT NULL DEFAULT 'gregorian',
  display_systems calendar_system[] NOT NULL DEFAULT ARRAY['gregorian']::calendar_system[],
  week_start integer NOT NULL DEFAULT 0, -- 0 = Sunday, 1 = Monday, etc.
  show_alternative_dates boolean NOT NULL DEFAULT false,
  show_lunar_phases boolean NOT NULL DEFAULT false,
  show_solar_terms boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Contact Management System
CREATE TABLE contacts (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id),
  full_name text NOT NULL,
  email text NOT NULL,
  phone text,
  company text,
  job_title text,
  contact_type text NOT NULL, -- 'personal', 'business', 'vendor', etc.
  tags text[],
  notes text,
  avatar_url text,
  last_contacted_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, email)
);

-- Contact Groups for organizing contacts
CREATE TABLE contact_groups (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id),
  name text NOT NULL,
  description text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, name)
);

-- Junction table for contacts and groups
CREATE TABLE contact_group_members (
  contact_id uuid REFERENCES contacts(id) ON DELETE CASCADE,
  group_id uuid REFERENCES contact_groups(id) ON DELETE CASCADE,
  added_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (contact_id, group_id)
);

-- Contact Interactions tracking
CREATE TABLE contact_interactions (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  contact_id uuid REFERENCES contacts(id) ON DELETE CASCADE,
  interaction_type text NOT NULL, -- 'meeting', 'email', 'call', 'message', etc.
  title text NOT NULL,
  description text,
  date timestamp with time zone NOT NULL,
  duration_minutes integer,
  location text,
  outcome text,
  follow_up_date timestamp with time zone,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Contact Communication Preferences
CREATE TABLE contact_preferences (
  contact_id uuid REFERENCES contacts(id) ON DELETE CASCADE PRIMARY KEY,
  preferred_contact_method text NOT NULL, -- 'email', 'phone', 'message'
  preferred_time_start time,
  preferred_time_end time,
  preferred_days integer[], -- 0-6 for Sunday-Saturday
  timezone text NOT NULL DEFAULT 'UTC',
  opt_out_email boolean DEFAULT false,
  opt_out_sms boolean DEFAULT false,
  opt_out_calls boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Messaging System
CREATE TABLE conversations (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  title text,
  created_by uuid REFERENCES auth.users(id),
  conversation_type text NOT NULL DEFAULT 'direct', -- 'direct', 'group'
  status text NOT NULL DEFAULT 'active', -- 'active', 'archived'
  last_message_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Conversation participants
CREATE TABLE conversation_participants (
  conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE,
  contact_id uuid REFERENCES contacts(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'member', -- 'admin', 'member'
  last_read_at timestamp with time zone,
  joined_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (conversation_id, contact_id)
);

-- Messages
CREATE TABLE messages (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES contacts(id),
  message_type text NOT NULL DEFAULT 'text', -- 'text', 'file', 'image', 'system'
  content text NOT NULL,
  metadata jsonb, -- For additional message-specific data
  sent_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  edited_at timestamp with time zone,
  parent_message_id uuid REFERENCES messages(id), -- For thread replies
  is_pinned boolean DEFAULT false
);

-- Message reactions
CREATE TABLE message_reactions (
  message_id uuid REFERENCES messages(id) ON DELETE CASCADE,
  contact_id uuid REFERENCES contacts(id) ON DELETE CASCADE,
  reaction text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (message_id, contact_id, reaction)
);

-- Message read receipts
CREATE TABLE message_read_receipts (
  message_id uuid REFERENCES messages(id) ON DELETE CASCADE,
  contact_id uuid REFERENCES contacts(id) ON DELETE CASCADE,
  read_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (message_id, contact_id)
);

-- Planet 3D Assets Management
CREATE TABLE planet_models (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  planet_name text NOT NULL UNIQUE,
  description text,
  scale_km float NOT NULL, -- actual diameter in kilometers
  rotation_period_hours float, -- time for one complete rotation
  orbital_period_days float, -- time for one orbit around the sun
  axial_tilt_degrees float, -- planet's axis tilt
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Planet Textures (diffuse, normal, specular, etc.)
CREATE TABLE planet_textures (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  planet_model_id uuid REFERENCES planet_models(id) ON DELETE CASCADE,
  texture_type text NOT NULL, -- 'diffuse', 'normal', 'specular', 'bump', 'emission', 'cloud'
  resolution text NOT NULL, -- '2k', '4k', '8k'
  file_format text NOT NULL, -- 'jpg', 'png', 'webp'
  storage_path text NOT NULL, -- path in storage bucket
  cdn_url text,
  file_size integer NOT NULL, -- in bytes
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(planet_model_id, texture_type, resolution)
);

-- Planet Atmosphere Settings
CREATE TABLE planet_atmospheres (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  planet_model_id uuid REFERENCES planet_models(id) ON DELETE CASCADE,
  has_atmosphere boolean NOT NULL DEFAULT true,
  color text, -- hex color
  opacity float NOT NULL DEFAULT 0.5,
  scale float NOT NULL DEFAULT 1.025, -- atmosphere size relative to planet
  scatter_strength float, -- Rayleigh scattering strength
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(planet_model_id)
);

-- Planet Ring Systems (for Saturn, Uranus, etc.)
CREATE TABLE planet_rings (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  planet_model_id uuid REFERENCES planet_models(id) ON DELETE CASCADE,
  inner_radius_km float NOT NULL,
  outer_radius_km float NOT NULL,
  texture_path text, -- path to ring texture
  opacity float NOT NULL DEFAULT 1.0,
  color text, -- hex color
  rotation_offset_degrees float DEFAULT 0,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Planet Special Effects
CREATE TABLE planet_effects (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  planet_model_id uuid REFERENCES planet_models(id) ON DELETE CASCADE,
  effect_type text NOT NULL, -- 'glow', 'aurora', 'storms', 'lightning'
  parameters jsonb NOT NULL, -- effect-specific settings
  enabled boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE interest_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_conversions ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE meeting_attendees ENABLE ROW LEVEL SECURITY;
ALTER TABLE meeting_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_read_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE planet_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE planet_textures ENABLE ROW LEVEL SECURITY;
ALTER TABLE planet_atmospheres ENABLE ROW LEVEL SECURITY;
ALTER TABLE planet_rings ENABLE ROW LEVEL SECURITY;
ALTER TABLE planet_effects ENABLE ROW LEVEL SECURITY;

-- Policies for interest submissions
CREATE POLICY "Anyone can create interest submissions" ON interest_submissions
  FOR INSERT WITH CHECK (true);
  
CREATE POLICY "Only authenticated users can view submissions" ON interest_submissions
  FOR SELECT USING (auth.role() = 'authenticated');

-- Policies for meetings
CREATE POLICY "Meeting owners can manage their meetings" ON meetings
  FOR ALL USING (auth.uid() = user_id);

-- Policies for meeting attendees
CREATE POLICY "Meeting owners can manage attendees" ON meeting_attendees
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM meetings
      WHERE id = meeting_attendees.meeting_id
      AND user_id = auth.uid()
    )
  );

-- Policies for meeting reminders
CREATE POLICY "Meeting owners can manage reminders" ON meeting_reminders
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM meetings
      WHERE id = meeting_reminders.meeting_id
      AND user_id = auth.uid()
    )
  );

-- Policies for calendar events
CREATE POLICY "Users can view their own events" ON calendar_events
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own events" ON calendar_events
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own events" ON calendar_events
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own events" ON calendar_events
  FOR DELETE USING (auth.uid() = user_id);

-- Policies for calendar preferences
CREATE POLICY "Users can view their own preferences" ON calendar_preferences
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own preferences" ON calendar_preferences
  FOR ALL USING (auth.uid() = user_id);

-- Policies for calendar conversions (cached conversions are public)
CREATE POLICY "Anyone can view calendar conversions" ON calendar_conversions
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create conversions" ON calendar_conversions
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Policies for contacts
CREATE POLICY "Users can view their own contacts" ON contacts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own contacts" ON contacts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own contacts" ON contacts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own contacts" ON contacts
  FOR DELETE USING (auth.uid() = user_id);

-- Policies for contact groups
CREATE POLICY "Users can view their own contact groups" ON contact_groups
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own contact groups" ON contact_groups
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own contact groups" ON contact_groups
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own contact groups" ON contact_groups
  FOR DELETE USING (auth.uid() = user_id);

-- Policies for contact group members
CREATE POLICY "Users can manage their own contact group members" ON contact_group_members
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM contact_groups
      WHERE id = contact_group_members.group_id
      AND user_id = auth.uid()
    )
  );

-- Policies for contact interactions
CREATE POLICY "Users can manage their own contact interactions" ON contact_interactions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM contacts
      WHERE id = contact_interactions.contact_id
      AND user_id = auth.uid()
    )
  );

-- Policies for contact preferences
CREATE POLICY "Users can manage their own contact preferences" ON contact_preferences
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM contacts
      WHERE id = contact_preferences.contact_id
      AND user_id = auth.uid()
    )
  );

-- Policies for conversations
CREATE POLICY "Users can view conversations they're part of" ON conversations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM conversation_participants cp
      JOIN contacts c ON cp.contact_id = c.id
      WHERE cp.conversation_id = conversations.id
      AND c.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create conversations" ON conversations
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Conversation admins can update conversations" ON conversations
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM conversation_participants cp
      JOIN contacts c ON cp.contact_id = c.id
      WHERE cp.conversation_id = conversations.id
      AND cp.role = 'admin'
      AND c.user_id = auth.uid()
    )
  );

-- Policies for conversation participants
CREATE POLICY "Users can view conversation participants" ON conversation_participants
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM conversation_participants cp
      JOIN contacts c ON cp.contact_id = c.id
      WHERE cp.conversation_id = conversation_participants.conversation_id
      AND c.user_id = auth.uid()
    )
  );

CREATE POLICY "Conversation admins can manage participants" ON conversation_participants
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM conversation_participants cp
      JOIN contacts c ON cp.contact_id = c.id
      WHERE cp.conversation_id = conversation_participants.conversation_id
      AND cp.role = 'admin'
      AND c.user_id = auth.uid()
    )
  );

-- Policies for messages
CREATE POLICY "Users can view messages in their conversations" ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM conversation_participants cp
      JOIN contacts c ON cp.contact_id = c.id
      WHERE cp.conversation_id = messages.conversation_id
      AND c.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can send messages in their conversations" ON messages
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM conversation_participants cp
      JOIN contacts c ON cp.contact_id = c.id
      WHERE cp.conversation_id = messages.conversation_id
      AND c.user_id = auth.uid()
    )
  );

CREATE POLICY "Message senders can update their messages" ON messages
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM contacts c
      WHERE c.id = messages.sender_id
      AND c.user_id = auth.uid()
    )
  );

-- Policies for message reactions and read receipts
CREATE POLICY "Users can manage their reactions" ON message_reactions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM contacts c
      WHERE c.id = message_reactions.contact_id
      AND c.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage their read receipts" ON message_read_receipts
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM contacts c
      WHERE c.id = message_read_receipts.contact_id
      AND c.user_id = auth.uid()
    )
  );

-- Public access policies for planet models
CREATE POLICY "Planet models are publicly viewable" ON planet_models
  FOR SELECT USING (true);

CREATE POLICY "Planet textures are publicly viewable" ON planet_textures
  FOR SELECT USING (true);

CREATE POLICY "Planet atmospheres are publicly viewable" ON planet_atmospheres
  FOR SELECT USING (true);

CREATE POLICY "Planet rings are publicly viewable" ON planet_rings
  FOR SELECT USING (true);

CREATE POLICY "Planet effects are publicly viewable" ON planet_effects
  FOR SELECT USING (true);

-- Admin policies
CREATE POLICY "Only authenticated users can manage planet models" ON planet_models
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Only authenticated users can manage planet textures" ON planet_textures
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Only authenticated users can manage planet atmospheres" ON planet_atmospheres
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Only authenticated users can manage planet rings" ON planet_rings
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Only authenticated users can manage planet effects" ON planet_effects
  FOR ALL USING (auth.role() = 'authenticated');

-- Add updated_at trigger to calendar_events
CREATE TRIGGER handle_updated_at_calendar_events
  BEFORE UPDATE ON calendar_events
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

-- Add updated_at trigger to calendar_preferences
CREATE TRIGGER handle_updated_at_calendar_preferences
  BEFORE UPDATE ON calendar_preferences
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

-- Add triggers for updated_at timestamps
CREATE TRIGGER handle_updated_at_contacts
  BEFORE UPDATE ON contacts
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_updated_at_contact_groups
  BEFORE UPDATE ON contact_groups
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_updated_at_contact_interactions
  BEFORE UPDATE ON contact_interactions
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_updated_at_contact_preferences
  BEFORE UPDATE ON contact_preferences
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_updated_at_conversations
  BEFORE UPDATE ON conversations
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

-- Add triggers for updated_at timestamps
CREATE TRIGGER handle_updated_at_planet_models
  BEFORE UPDATE ON planet_models
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_updated_at_planet_textures
  BEFORE UPDATE ON planet_textures
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_updated_at_planet_atmospheres
  BEFORE UPDATE ON planet_atmospheres
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_updated_at_planet_rings
  BEFORE UPDATE ON planet_rings
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_updated_at_planet_effects
  BEFORE UPDATE ON planet_effects
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at();

-- Add indexes for better query performance
CREATE INDEX idx_contacts_user_id ON contacts(user_id);
CREATE INDEX idx_contacts_email ON contacts(email);
CREATE INDEX idx_contacts_company ON contacts(company);
CREATE INDEX idx_contacts_tags ON contacts USING gin(tags);
CREATE INDEX idx_contact_interactions_contact_id ON contact_interactions(contact_id);
CREATE INDEX idx_contact_interactions_date ON contact_interactions(date);
CREATE INDEX idx_contact_group_members_group_id ON contact_group_members(group_id);
CREATE INDEX idx_meetings_user_id ON meetings(user_id);
CREATE INDEX idx_meetings_date ON meetings(date);
CREATE INDEX idx_meeting_attendees_contact_id ON meeting_attendees(contact_id);
CREATE INDEX idx_meeting_reminders_reminder_time ON meeting_reminders(reminder_time);
CREATE INDEX idx_conversations_created_by ON conversations(created_by);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at);
CREATE INDEX idx_conversation_participants_contact ON conversation_participants(contact_id);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_parent ON messages(parent_message_id);
CREATE INDEX idx_messages_sent_at ON messages(sent_at);
CREATE INDEX idx_message_reactions_contact ON message_reactions(contact_id);
CREATE INDEX idx_message_read_receipts_contact ON message_read_receipts(contact_id);
CREATE INDEX idx_planet_models_name ON planet_models(planet_name);
CREATE INDEX idx_planet_textures_model ON planet_textures(planet_model_id);
CREATE INDEX idx_planet_textures_type ON planet_textures(texture_type);
CREATE INDEX idx_planet_atmospheres_model ON planet_atmospheres(planet_model_id);
CREATE INDEX idx_planet_rings_model ON planet_rings(planet_model_id);
CREATE INDEX idx_planet_effects_model ON planet_effects(planet_model_id);
CREATE INDEX idx_planet_effects_type ON planet_effects(effect_type);

-- Insert some initial calendar data
INSERT INTO calendar_epochs (calendar_system, epoch_name, gregorian_date, description) VALUES
  ('mayan_long_count', 'Creation', '3114-08-11 BC'::timestamp with time zone, 'Beginning of the current creation (13.0.0.0.0)'),
  ('gregorian', 'Common Era', '0001-01-01'::timestamp with time zone, 'Start of Common Era'),
  ('islamic', 'Hijra', '0622-07-16'::timestamp with time zone, 'Islamic calendar epoch');

-- Insert Mayan Tzolkin day names
INSERT INTO mayan_tzolkin_days (number, name, meaning) VALUES
  (1, 'Imix', 'Crocodile/Water Lily'),
  (2, 'Ikʼ', 'Wind/Breath'),
  (3, 'Akʼbal', 'Darkness/Night'),
  (4, 'Kan', 'Maize/Lizard'),
  (5, 'Chikchan', 'Snake'),
  (6, 'Kimi', 'Death'),
  (7, 'Manikʼ', 'Deer'),
  (8, 'Lamat', 'Venus/Rabbit'),
  (9, 'Muluk', 'Water/Jade'),
  (10, 'Ok', 'Dog'),
  (11, 'Chuwen', 'Monkey/Craftsman'),
  (12, 'Eb', 'Road/Tooth'),
  (13, 'Ben', 'Reed/Corn');

-- Insert example intercalary days
INSERT INTO calendar_special_days (calendar_system, day_name, type, calculation_rule, description) VALUES
  ('chinese', 'Run Yue', 'leap_month', 'chinese_leap_month_rule()', 'Chinese calendar leap month'),
  ('mayan_haab', 'Wayeb', 'special_period', 'day_number > 360', 'Five unlucky days at end of Haab year'),
  ('gregorian', 'Leap Day', 'leap_day', '(year % 4 = 0 AND year % 100 <> 0) OR year % 400 = 0', 'February 29th on leap years');

-- Insert initial planet data
INSERT INTO planet_models (
  planet_name, 
  description, 
  scale_km, 
  rotation_period_hours,
  orbital_period_days,
  axial_tilt_degrees
) VALUES
  ('Mercury', 'Smallest planet in our solar system', 4879, 1407.6, 88, 0.034),
  ('Venus', 'Second planet from the Sun', 12104, -5832.5, 224.7, 177.4),
  ('Earth', 'Our home planet', 12742, 24, 365.25, 23.44),
  ('Mars', 'The Red Planet', 6779, 24.6, 687, 25.19),
  ('Jupiter', 'Largest planet in our solar system', 139820, 9.9, 4333, 3.13),
  ('Saturn', 'Known for its prominent ring system', 116460, 10.7, 10759, 26.73),
  ('Uranus', 'Ice giant with unique sideways rotation', 50724, -17.2, 30687, 97.77),
  ('Neptune', 'The windiest planet', 49244, 16.1, 60190, 28.32);

-- Insert atmosphere data for planets
INSERT INTO planet_atmospheres (
  planet_model_id,
  has_atmosphere,
  color,
  opacity,
  scale,
  scatter_strength
)
SELECT 
  id,
  CASE 
    WHEN planet_name IN ('Mercury') THEN false
    ELSE true
  END,
  CASE 
    WHEN planet_name = 'Venus' THEN '#fff4e6'
    WHEN planet_name = 'Earth' THEN '#add8e6'
    WHEN planet_name = 'Mars' THEN '#ffe4b5'
    WHEN planet_name = 'Jupiter' THEN '#ffd700'
    WHEN planet_name = 'Saturn' THEN '#f4c430'
    WHEN planet_name = 'Uranus' THEN '#e0ffff'
    WHEN planet_name = 'Neptune' THEN '#4169e1'
    ELSE '#ffffff'
  END,
  CASE 
    WHEN planet_name = 'Venus' THEN 0.8
    WHEN planet_name = 'Earth' THEN 0.5
    ELSE 0.3
  END,
  1.025,
  CASE 
    WHEN planet_name = 'Earth' THEN 0.7
    ELSE 0.5
  END
FROM planet_models;

-- Insert ring data for Saturn and Uranus
INSERT INTO planet_rings (
  planet_model_id,
  inner_radius_km,
  outer_radius_km,
  opacity,
  color
)
SELECT 
  id,
  CASE 
    WHEN planet_name = 'Saturn' THEN 66900
    WHEN planet_name = 'Uranus' THEN 41837
  END,
  CASE 
    WHEN planet_name = 'Saturn' THEN 140220
    WHEN planet_name = 'Uranus' THEN 51149
  END,
  CASE 
    WHEN planet_name = 'Saturn' THEN 0.9
    WHEN planet_name = 'Uranus' THEN 0.5
  END,
  CASE 
    WHEN planet_name = 'Saturn' THEN '#c2b280'
    WHEN planet_name = 'Uranus' THEN '#e0ffff'
  END
FROM planet_models
WHERE planet_name IN ('Saturn', 'Uranus');

-- Add indexes for better query performance
CREATE INDEX idx_planet_models_name ON planet_models(planet_name);
CREATE INDEX idx_planet_textures_model ON planet_textures(planet_model_id);
CREATE INDEX idx_planet_textures_type ON planet_textures(texture_type);
CREATE INDEX idx_planet_atmospheres_model ON planet_atmospheres(planet_model_id);
CREATE INDEX idx_planet_rings_model ON planet_rings(planet_model_id);
CREATE INDEX idx_planet_effects_model ON planet_effects(planet_model_id);
CREATE INDEX idx_planet_effects_type ON planet_effects(effect_type);

-- Function to update conversation last_message_at
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET last_message_at = NEW.sent_at
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update conversation last_message_at
CREATE TRIGGER update_conversation_last_message
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_last_message();

-- Insert some initial planet images
INSERT INTO planet_images (planet_name, description, attribution, license) VALUES
  ('Earth', 'Blue Marble view of Earth', 'NASA', 'Public Domain'),
  ('Mars', 'Red Planet surface view', 'NASA/JPL', 'Public Domain'),
  ('Jupiter', 'Great Red Spot view', 'NASA/JPL', 'Public Domain'),
  ('Saturn', 'Ring system view', 'NASA/JPL', 'Public Domain'),
  ('Venus', 'Radar mapping view', 'NASA/JPL', 'Public Domain'),
  ('Mercury', 'Surface detail view', 'NASA/JPL', 'Public Domain'),
  ('Uranus', 'Blue-green disk view', 'NASA/JPL', 'Public Domain'),
  ('Neptune', 'Blue disk with storms view', 'NASA/JPL', 'Public Domain');

-- Add some common tags
INSERT INTO image_tags (planet_image_id, tag)
SELECT id, tag
FROM planet_images
CROSS JOIN (
  VALUES 
    ('planet'),
    ('solar system'),
    ('astronomy'),
    ('space')
) AS t(tag); 