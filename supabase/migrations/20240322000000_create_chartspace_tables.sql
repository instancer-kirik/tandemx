-- Create chartspace_nodes table
CREATE TABLE chartspace_nodes (
  id TEXT PRIMARY KEY,
  position JSONB NOT NULL,
  label TEXT NOT NULL,
  node_type TEXT NOT NULL,
  status TEXT NOT NULL,
  description TEXT NOT NULL,
  deadline TEXT,
  assignees JSONB NOT NULL DEFAULT '[]',
  completion_percentage INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create chartspace_connections table
CREATE TABLE chartspace_connections (
  id TEXT PRIMARY KEY,
  from_node TEXT NOT NULL REFERENCES chartspace_nodes(id) ON DELETE CASCADE,
  to_node TEXT NOT NULL REFERENCES chartspace_nodes(id) ON DELETE CASCADE,
  connection_type TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes
CREATE INDEX chartspace_nodes_node_type_idx ON chartspace_nodes(node_type);
CREATE INDEX chartspace_nodes_status_idx ON chartspace_nodes(status);
CREATE INDEX chartspace_connections_from_node_idx ON chartspace_connections(from_node);
CREATE INDEX chartspace_connections_to_node_idx ON chartspace_connections(to_node);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers
CREATE TRIGGER update_chartspace_nodes_updated_at
  BEFORE UPDATE ON chartspace_nodes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chartspace_connections_updated_at
  BEFORE UPDATE ON chartspace_connections
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add RLS policies
ALTER TABLE chartspace_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE chartspace_connections ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Enable read access for all users" ON chartspace_nodes
  FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users" ON chartspace_nodes
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users" ON chartspace_nodes
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete for authenticated users" ON chartspace_nodes
  FOR DELETE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable read access for all users" ON chartspace_connections
  FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users" ON chartspace_connections
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users" ON chartspace_connections
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete for authenticated users" ON chartspace_connections
  FOR DELETE USING (auth.role() = 'authenticated'); 