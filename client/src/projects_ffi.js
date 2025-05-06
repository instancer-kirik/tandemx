// FFI implementations for projects.gleam

// Navigate the browser window
export function setWindowLocation(path) {
  window.location.href = path;
}

// Placeholder function to simulate fetching projects
// In a real app, this would fetch from an API (e.g., Supabase)
export function fetchProjects() {
  console.log("FFI: fetchProjects called (simulating fetch)");
  // Simulate async fetch
  return new Promise(resolve => {
    setTimeout(() => {
      // Sample project data matching the Gleam Project type structure
      // Note: Enum-like fields (status, priority) are represented as strings here.
      // The Gleam side would need decoders if fetching complex JSON.
      // For this simple placeholder, we assume direct mapping is okay
      // for the simulation, or that backend sends data matching Gleam enums.
      const sample_project1 = {
        id: "proj_001",
        name: "Platform Integration", 
        description: "Integrate various tools", 
        status: { type: 'Active' }, 
        category: { type: 'WebApplication' },
        created_at: "2024-03-20", 
        due_date: { type: 'None' }, 
        owner: "admin@example.com", 
        collaborators: [], 
        tags: ["integration"], 
        priority: { type: 'High' },
        system_environment_info: { type: 'Some', 0: { os: "Linux", runtime: "Gleam v1.0" } },
        source_control_details: { type: 'Some', 0: { branch: "main", repo: "tandemx/client" } },
        documentation_references: { type: 'None' }
      };
      const sample_project2 = {
        id: "proj_002", 
        name: "New Artist Portfolio Site", 
        description: "Build a new website for showcasing artist portfolios.", 
        status: { type: 'Planning' }, 
        category: { type: 'CreativeAssetOther' },
        created_at: "2024-04-10", 
        due_date: { type: 'Some', 0: "2024-09-01" },
        owner: "artist_relations@example.com", 
        collaborators: [], 
        tags: ["web", "portfolio", "creative"], 
        priority: { type: 'Medium' },
        system_environment_info: { type: 'None' },
        source_control_details: { type: 'None' },
        documentation_references: { type: 'Some', 0: { wiki: "internal.wiki/artist-portfolio"}}
      };

      // Wrap in Gleam's Ok constructor format for Result.Ok
      resolve({ type: 'Ok', 0: [sample_project1, sample_project2] });

    }, 500); // 500ms delay
  });
} 