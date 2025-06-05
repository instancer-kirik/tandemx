-- Create enum types for project status, categories, and priorities
CREATE TYPE project_status AS ENUM ('Planning', 'Active', 'OnHold', 'ProjectCompleted', 'Archived');
CREATE TYPE project_category AS ENUM ('WebApplication', 'MobileApplication', 'DesktopApplication', 'Game', 'LibraryOrFramework', 'ApiService', 'HardwareOrIot', 'DataScienceOrMl', 'CreativeAssetBlender', 'CreativeAssetOther', 'ScriptOrUtility', 'Documentation', 'Research', 'OtherCategory');
CREATE TYPE project_priority AS ENUM ('Low', 'Medium', 'High', 'Urgent');

-- Create projects table
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  status project_status NOT NULL DEFAULT 'Planning',
  category project_category NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  due_date TIMESTAMP WITH TIME ZONE,
  owner TEXT NOT NULL,
  collaborators TEXT[] DEFAULT '{}',
  tags TEXT[] DEFAULT '{}',
  priority project_priority NOT NULL DEFAULT 'Medium',
  system_environment_info JSONB,
  source_control_details JSONB,
  documentation_references JSONB,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_category ON projects(category);
CREATE INDEX idx_projects_priority ON projects(priority);
CREATE INDEX idx_projects_owner ON projects(owner);
CREATE INDEX idx_projects_tags ON projects USING GIN (tags);

-- Create update trigger for projects
CREATE TRIGGER update_projects_updated_at
  BEFORE UPDATE ON projects
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can read projects" ON projects
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create projects" ON projects
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Project owners can update their projects" ON projects
  FOR UPDATE USING (auth.email() = owner);

CREATE POLICY "Project owners can delete their projects" ON projects
  FOR DELETE USING (auth.email() = owner);

-- Insert sample projects
INSERT INTO projects (name, description, status, category, owner, collaborators, tags, priority, system_environment_info, source_control_details, documentation_references)
VALUES
(
  'Platform Integration',
  'Integrate various tools into a cohesive platform experience.',
  'Active',
  'WebApplication',
  'admin@example.com',
  ARRAY['dev1@example.com', 'design@example.com'],
  ARRAY['integration', 'platform', 'web'],
  'High',
  '{"os": "Linux", "runtime": "Gleam v1.0"}',
  '{"branch": "main", "repo": "tandemx/client"}',
  NULL
),
(
  'New Artist Portfolio Site',
  'Build a new website for showcasing artist portfolios with interactive galleries.',
  'Planning',
  'CreativeAssetOther',
  'artist_relations@example.com',
  ARRAY[]::TEXT[],
  ARRAY['web', 'portfolio', 'creative'],
  'Medium',
  NULL,
  NULL,
  '{"wiki": "internal.wiki/artist-portfolio"}'
);