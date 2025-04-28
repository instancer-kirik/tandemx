-- Create a table for blog posts with enhanced fields matching our frontend
CREATE TABLE posts (
  id text PRIMARY KEY,
  title text NOT NULL,
  content text NOT NULL,
  excerpt text,
  date timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  author text NOT NULL DEFAULT 'instance.select',
  category text NOT NULL DEFAULT 'uncategorized',
  image text,
  published boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can read published posts" ON posts
  FOR SELECT USING (published = true);

CREATE POLICY "Authenticated users can create posts" ON posts
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update posts" ON posts
  FOR UPDATE USING (auth.role() = 'authenticated');

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
  BEFORE UPDATE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION handle_updated_at(); 