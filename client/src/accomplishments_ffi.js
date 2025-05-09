// FFI functions for accomplishments.gleam
import { supabase } from './access_content_ffi.js'; // Import Supabase client

// Helper to map Supabase array/null to Gleam Option(List(String))
function mapTagsToGleam(tags) {
  if (tags && Array.isArray(tags)) {
    return { type: 'Some', 0: tags };
  } else {
    return { type: 'None' };
  }
}

// Helper to map Supabase uuid/null to Gleam Option(String)
function mapOptionalIdToGleam(id) {
   return id === null || typeof id === 'undefined' ? { type: 'None' } : { type: 'Some', 0: id };
}

// Fetches accomplishments for a given user ID
export async function fetchAccomplishments(userId) {
  if (!supabase) return { type: 'Error', 0: "Supabase client not initialized" };
  if (!userId) return { type: 'Error', 0: "User ID is required to fetch accomplishments" };

  try {
    const { data, error } = await supabase
      .from('accomplishments')
      .select('id, user_id, content, created_at, tags, project_id')
      .eq('user_id', userId) // Filter by user ID (RLS should also enforce this)
      .order('created_at', { ascending: false });

    if (error) {
      console.error("FFI fetchAccomplishments error:", error);
      // RLS errors often appear here if policies are missing/incorrect
      return { type: 'Error', 0: error.message || "Failed to fetch accomplishments" };
    }

    // Transform Supabase data to match the Gleam Accomplishment type structure
    const gleamAccomplishments = data.map(a => ({
      id: a.id,
      user_id: a.user_id, // Should match the input userId due to the .eq filter
      content: a.content,
      created_at: a.created_at, // Assuming ISO string format
      tags: mapTagsToGleam(a.tags), // Map array/null to Option(List(_))
      project_id: mapOptionalIdToGleam(a.project_id), // Map uuid/null to Option(_)
    }));

    return { type: 'Ok', 0: gleamAccomplishments };

  } catch (e) {
    console.error("FFI fetchAccomplishments exception:", e);
    return { type: 'Error', 0: e.message || "An unknown exception occurred" };
  }
}

// Submits a new accomplishment
export async function submitAccomplishment(userId, content, tags, projectId) {
  if (!supabase) return { type: 'Error', 0: "Supabase client not initialized" };
  if (!userId) return { type: 'Error', 0: "User ID is required" };
  if (!content) return { type: 'Error', 0: "Content cannot be empty" };

  try {
    const accomplishmentData = {
        user_id: userId,
        content: content,
        // Only include tags/project_id if they are provided (not null/undefined)
        ...(tags && { tags: tags }), 
        ...(projectId && { project_id: projectId }),
    };

    const { data, error } = await supabase
      .from('accomplishments')
      .insert([accomplishmentData])
      .select() // Select the newly created record
      .single(); // Expecting a single record back

    if (error) {
      console.error("FFI submitAccomplishment error:", error);
      // RLS errors on INSERT might appear here
      return { type: 'Error', 0: error.message || "Failed to submit accomplishment" };
    }

    // Transform the returned Supabase data to the Gleam Accomplishment type
    const gleamAccomplishment = {
      id: data.id,
      user_id: data.user_id,
      content: data.content,
      created_at: data.created_at,
      tags: mapTagsToGleam(data.tags),
      project_id: mapOptionalIdToGleam(data.project_id),
    };

    return { type: 'Ok', 0: gleamAccomplishment };

  } catch (e) {
    console.error("FFI submitAccomplishment exception:", e);
    return { type: 'Error', 0: e.message || "An unknown exception occurred" };
  }
} 