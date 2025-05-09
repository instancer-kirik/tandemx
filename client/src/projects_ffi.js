// FFI implementations for projects.gleam

// Attempt to import the Supabase client from access_content_ffi.js
// This assumes access_content_ffi.js initializes and exports 'supabase'.
// If your Supabase client is initialized or accessed differently, adjust this import.
import { supabase } from './access_content_ffi.js';

// Navigate the browser window
export function setWindowLocation(path) {
  window.location.href = path;
}

// Helper to map Supabase string values to Gleam-like enum structures.
// Assumes DB stores strings like "Active", "WebApplication", "High".
// Adjust these if your DB stores different values.
function toGleamOption(value) {
  return value === null || typeof value === 'undefined' ? { type: 'None' } : { type: 'Some', 0: value };
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
  if (!supabase) {
    const errorMessage = "FFI: Supabase client is not initialized. Make sure access_content_ffi.js exports it and it's initialized before this call.";
    console.error(errorMessage);
    return { type: 'Error', 0: errorMessage };
  }

  try {
    console.log("FFI: supabaseFetchProjects called");
    const { data, error } = await supabase
      .from('projects') // Ensure you have a 'projects' table in Supabase
      .select('*');    // Adjust columns as needed, e.g., 'id, name, description, status_db, category_db, ...'

    if (error) {
      console.error("FFI supabaseFetchProjects error:", error);
      return { type: 'Error', 0: error.message };
    }

    // Transform Supabase data to match the Gleam Project type structure
    const gleamProjects = data.map(p => {
      // IMPORTANT: Ensure these mappings are correct for your DB schema and Gleam types.
      // The 'p.status', 'p.category', 'p.priority' should hold the string that
      // corresponds to the Gleam variant name (e.g., "Active", "WebApplication").
      // If your DB stores different values, you'll need more complex mapping here.
      return {
        id: p.id,
        name: p.name,
        description: p.description,
        status: mapToGleamEnum(p.status, 'Active'), // e.g., if p.status is "Active"
        category: mapToGleamEnum(p.category, 'WebApplication'), // e.g., if p.category is "WebApplication"
        created_at: p.created_at, // Ensure ISO string format if Gleam expects specific parsing
        due_date: toGleamOption(p.due_date),
        owner: p.owner,
        collaborators: p.collaborators || [], // Assuming array of strings
        tags: p.tags || [], // Assuming array of strings
        priority: mapToGleamEnum(p.priority, 'Medium'), // e.g., if p.priority is "Medium"
        system_environment_info: toGleamOption(p.system_environment_info), // Assuming JSONB in DB
        source_control_details: toGleamOption(p.source_control_details),   // Assuming JSONB in DB
        documentation_references: toGleamOption(p.documentation_references), // Assuming JSONB in DB
      };
    });

    const returnValue = { type: 'Ok', 0: gleamProjects };
    console.log("FFI supabaseFetchProjects returning:", JSON.stringify(returnValue));
  return returnValue; 

  } catch (e) {
    console.error("FFI supabaseFetchProjects exception:", e);
    return { type: 'Error', 0: e.message || "An unknown exception occurred" };
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