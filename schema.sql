-- Create enum types
CREATE TYPE node_type AS ENUM ('goal', 'task', 'resource', 'outcome', 'milestone', 'space', 'artist', 'project');
CREATE TYPE node_status AS ENUM ('not_started', 'in_progress', 'completed', 'blocked');
CREATE TYPE connection_type AS ENUM ('dependency', 'reference', 'flow');
CREATE TYPE space_type AS ENUM ('studio', 'gallery', 'practice_room', 'workshop', 'treehouse', 'other');

-- Create nodes table
CREATE TABLE nodes (
  id TEXT PRIMARY KEY,
  x FLOAT NOT NULL,
  y FLOAT NOT NULL,
  label TEXT NOT NULL,
  node_type node_type NOT NULL,
  status node_status NOT NULL DEFAULT 'not_started',
  description TEXT,
  deadline TIMESTAMP,
  completion_percentage INTEGER CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create connections table
CREATE TABLE connections (
  id TEXT PRIMARY KEY,
  source_id TEXT NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
  target_id TEXT NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
  connection_type connection_type NOT NULL DEFAULT 'dependency',
  label TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create collaborators table
CREATE TABLE collaborators (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  color TEXT NOT NULL,
  cursor_x FLOAT,
  cursor_y FLOAT,
  selected_node_id TEXT REFERENCES nodes(id) ON DELETE SET NULL,
  last_active TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create Findry tables
CREATE TABLE spaces (
  id TEXT PRIMARY KEY,
  node_id TEXT REFERENCES nodes(id) ON DELETE CASCADE,
  space_type space_type NOT NULL,
  square_footage INTEGER NOT NULL,
  equipment_list JSONB,
  availability_schedule JSONB,
  pricing_terms JSONB,
  acoustics_rating INTEGER CHECK (acoustics_rating >= 0 AND acoustics_rating <= 10),
  lighting_details JSONB,
  access_hours JSONB,
  location_data JSONB,
  photos TEXT[],
  virtual_tour_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE artists (
  id TEXT PRIMARY KEY,
  node_id TEXT REFERENCES nodes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  creative_discipline TEXT[],
  space_requirements JSONB,
  project_timeline TSRANGE,
  budget_range INT4RANGE,
  equipment_needs TEXT[],
  preferred_hours JSONB,
  portfolio_urls TEXT[],
  group_size INTEGER,
  noise_level INTEGER CHECK (noise_level >= 0 AND noise_level <= 10),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE matches (
  id TEXT PRIMARY KEY,
  space_id TEXT REFERENCES spaces(id) ON DELETE CASCADE,
  artist_id TEXT REFERENCES artists(id) ON DELETE CASCADE,
  compatibility_score FLOAT CHECK (compatibility_score >= 0 AND compatibility_score <= 1),
  matched_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE bookings (
  id TEXT PRIMARY KEY,
  match_id TEXT REFERENCES matches(id) ON DELETE CASCADE,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  payment_status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_nodes_type ON nodes(node_type);
CREATE INDEX idx_nodes_status ON nodes(status);
CREATE INDEX idx_connections_source ON connections(source_id);
CREATE INDEX idx_connections_target ON connections(target_id);
CREATE INDEX idx_collaborators_selected_node ON collaborators(selected_node_id);

-- Create indexes for Findry tables
CREATE INDEX idx_spaces_type ON spaces(space_type);
CREATE INDEX idx_spaces_acoustics ON spaces(acoustics_rating);
CREATE INDEX idx_artists_discipline ON artists USING GIN (creative_discipline);
CREATE INDEX idx_artists_noise ON artists(noise_level);
CREATE INDEX idx_matches_score ON matches(compatibility_score);
CREATE INDEX idx_matches_status ON matches(status);
CREATE INDEX idx_bookings_time ON bookings(start_time, end_time);
CREATE INDEX idx_bookings_status ON bookings(status);

-- Create update trigger for nodes
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_nodes_updated_at
  BEFORE UPDATE ON nodes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_connections_updated_at
  BEFORE UPDATE ON connections
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_collaborators_updated_at
  BEFORE UPDATE ON collaborators
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add triggers for Findry tables
CREATE TRIGGER update_spaces_updated_at
  BEFORE UPDATE ON spaces
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_artists_updated_at
  BEFORE UPDATE ON artists
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_matches_updated_at
  BEFORE UPDATE ON matches
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at
  BEFORE UPDATE ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create a table for blog posts
CREATE TABLE blog_posts (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  title text NOT NULL,
  content text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  author_id uuid REFERENCES auth.users(id),
  published boolean DEFAULT false
);

-- Enable Row Level Security
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can read published posts" ON blog_posts
  FOR SELECT USING (published = true);

CREATE POLICY "Users can create posts" ON blog_posts
  FOR INSERT WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can update their own posts" ON blog_posts
  FOR UPDATE USING (auth.uid() = author_id);

-- Create function to handle updated_at
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER handle_updated_at
  BEFORE UPDATE ON blog_posts
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at(); 