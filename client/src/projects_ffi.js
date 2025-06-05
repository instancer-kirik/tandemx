// FFI implementations for projects.gleam

// Import the Supabase client from access_content_ffi.js
import { supabaseClient } from './access_content_ffi.js';

// Navigate the browser window
export function setWindowLocation(path) {
  window.location.href = path;
}

// Helper to map Supabase string values to Gleam-like enum structures.
// Assumes DB stores strings like "Active", "WebApplication", "High".
// Adjust these if your DB stores different values.
function toGleamOption(value) {
  if (value === null || typeof value === 'undefined') {
    return {
      isSome: function() { return false; },
      isNone: function() { return true; },
      value: null
    };
  } else {
    return {
      isSome: function() { return true; },
      isNone: function() { return false; },
      value: value
    };
  }
}

function mapToGleamEnum(value, defaultType) {
  if (value) {
    // Assuming the value from DB directly corresponds to the Gleam variant name
    return { type: value };
  }
  return { type: defaultType }; // Fallback if value is null/undefined
}

// Fetches projects from Supabase
export async function supabaseFetchProjects() {
  try {
    console.log("FFI: supabaseFetchProjects called");
    
    // Check if supabaseClient is initialized
    if (!supabaseClient) {
      throw new Error("Supabase client is not initialized");
    }
    
    const { data, error } = await supabaseClient
      .from('projects') // Ensure you have a 'projects' table in Supabase
      .select('*');    // Adjust columns as needed, e.g., 'id, name, description, status_db, category_db, ...'

    if (error) {
      console.error("FFI supabaseFetchProjects error:", error);
      return { 
        isOk: function() { return false; }, 
        isError: function() { return true; }, 
        value: null, 
        error: error.message 
      };
    }

    // Transform Supabase data to match the Gleam Project type structure
    const gleamProjects = (data || []).map(p => {
      return {
        id: p.id || `temp-${Math.random().toString(36).substr(2, 9)}`,
        name: p.name || "Unnamed Project",
        description: p.description || "No description provided",
        status: mapToGleamEnum(p.status, 'Active'),
        category: mapToGleamEnum(p.category, 'WebApplication'),
        created_at: p.created_at || new Date().toISOString(),
        due_date: toGleamOption(p.due_date),
        owner: p.owner || "unknown@example.com",
        collaborators: p.collaborators || [],
        tags: p.tags || [],
        priority: mapToGleamEnum(p.priority, 'Medium'),
        system_environment_info: toGleamOption(p.system_environment_info),
        source_control_details: toGleamOption(p.source_control_details),
        documentation_references: toGleamOption(p.documentation_references),
      };
    });
    
    // Use fallback data if no projects were found
    if (!gleamProjects || gleamProjects.length === 0) {
      // Fallback sample projects
      const sample_project1 = {
        id: "proj_001",
        name: "Platform Integration",
        description: "Integrate various tools",
        status: { type: 'Active' },
        category: { type: 'WebApplication' },
        created_at: "2024-03-20",
        due_date: { isSome: function() { return false; }, isNone: function() { return true; }, value: null },
        owner: "admin@example.com",
        collaborators: [],
        tags: ["integration"],
        priority: { type: 'High' },
        system_environment_info: toGleamOption({ os: "Linux", runtime: "Gleam v1.0" }),
        source_control_details: toGleamOption({ branch: "main", repo: "tandemx/client" }),
        documentation_references: { isSome: function() { return false; }, isNone: function() { return true; }, value: null }
      };
      
      const sample_project2 = {
        id: "proj_002",
        name: "New Artist Portfolio Site",
        description: "Build a new website for showcasing artist portfolios.",
        status: { type: 'Planning' },
        category: { type: 'CreativeAssetOther' },
        created_at: "2024-04-10",
        due_date: toGleamOption("2024-09-01"),
        owner: "artist_relations@example.com",
        collaborators: [],
        tags: ["web", "portfolio", "creative"],
        priority: { type: 'Medium' },
        system_environment_info: { isSome: function() { return false; }, isNone: function() { return true; }, value: null },
        source_control_details: { isSome: function() { return false; }, isNone: function() { return true; }, value: null },
        documentation_references: toGleamOption({ wiki: "internal.wiki/artist-portfolio" })
      };
      
      return {
        isOk: function() { return true; },
        isError: function() { return false; },
        value: [sample_project1, sample_project2],
        error: null
      };
    }
    
    const returnValue = { 
      isOk: function() { return true; }, 
      isError: function() { return false; }, 
      value: gleamProjects, 
      error: null 
    };
    console.log("FFI supabaseFetchProjects returning:", "Result with projects array");
    return returnValue; 

  } catch (e) {
    console.error("FFI supabaseFetchProjects exception:", e);
    return { 
      isOk: function() { return false; }, 
      isError: function() { return true; }, 
      value: null, 
      error: e.message || "An unknown exception occurred" 
    };
  }
}

// Remove or comment out the old synchronous placeholder
// export function fetchProjects() {
//   console.log("FFI: fetchProjects called (simulating sync fetch)");
//   const sample_project1 = {
//     id: "proj_001",
//     name: "Platform Integration",
//     description: "Integrate various tools",
//     status: { type: 'Active' },
//     category: { type: 'WebApplication' },
//     created_at: "2024-03-20",
//     due_date: { type: 'None' },
//     owner: "admin@example.com",
//     collaborators: [],
//     tags: ["integration"],
//     priority: { type: 'High' },
//     system_environment_info: { type: 'Some', 0: { os: "Linux", runtime: "Gleam v1.0" } },
//     source_control_details: { type: 'Some', 0: { branch: "main", repo: "tandemx/client" } },
//     documentation_references: { type: 'None' }
//   };
//   const sample_project2 = {
//     id: "proj_002",
//     name: "New Artist Portfolio Site",
//     description: "Build a new website for showcasing artist portfolios.",
//     status: { type: 'Planning' },
//     category: { type: 'CreativeAssetOther' },
//     created_at: "2024-04-10",
//     due_date: { type: 'Some', 0: "2024-09-01" },
//     owner: "artist_relations@example.com",
//     collaborators: [],
//     tags: ["web", "portfolio", "creative"],
//     priority: { type: 'Medium' },
//     system_environment_info: { type: 'None' },
//     source_control_details: { type: 'None' },
//     documentation_references: { type: 'Some', 0: { wiki: "internal.wiki/artist-portfolio"}}
//   };
//   const returnValue = { type: 'Ok', 0: [sample_project1, sample_project2] };
//   console.log("FFI fetchProjects returning:", JSON.stringify(returnValue));
//   return returnValue;
// } 