// FFI functions for access_content.gleam
import { create_client, query_table, select_all, insert_row, run_query } from './supabase_ffi.mjs';

// Global Supabase client instance (initialized by init_supabase)
// Export it so other modules can import it
export let supabaseClient = null;

// Export the create_client function for other modules to use
export { create_client };

// Development values - publicly safe demo values
// For better security, configure via environment variables in production
const DEFAULT_URL = 'https://demo.supabase.co'; // Public demo URL
const DEFAULT_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRlbW8iLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYyMDY0OTAyNSwiZXhwIjoxOTM2MjI1MDI1fQ.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE'; // Public demo key

// Get Supabase credentials from environment or config endpoint
let url = DEFAULT_URL;
let key = DEFAULT_KEY;

// Function to retrieve Supabase config
async function getSupabaseConfig() {
    try {
        console.log("Attempting to fetch Supabase config from server...");
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 3000);
        
        const response = await fetch('/api/config', { 
            signal: controller.signal,
            headers: { 'Accept': 'application/json' }
        });
        clearTimeout(timeoutId);
        
        if (response.ok) {
            const config = await response.json();
            if (config.supabaseUrl && config.supabaseAnonKey) {
                console.log("Supabase credentials loaded from config endpoint");
                
                // Only use credentials that are not default/placeholder values
                if (config.supabaseUrl !== 'your_supabase_url_here' && 
                    config.supabaseAnonKey !== 'your_supabase_anon_key_here') {
                    url = config.supabaseUrl;
                    key = config.supabaseAnonKey;
                    
                    // Reinitialize if we have new credentials and client was already initialized
                    if (supabaseClient !== null) {
                        supabaseClient = create_client(url, key);
                        console.log("Supabase client reinitialized with new credentials");
                    } else {
                        initializeSupabaseClient();
                    }
                    return true;
                } else {
                    console.warn("Received placeholder credentials from server, using defaults instead");
                }
            }
        } else {
            console.warn(`Server returned ${response.status} when fetching config`);
        }
    } catch (e) {
        if (e.name === 'AbortError') {
            console.warn("Config request timed out after 3 seconds");
        } else {
            console.warn("Could not load Supabase config from endpoint, using defaults:", e.message);
        }
    }
    
    console.log("Using default development Supabase credentials");
    return false;
}

// Initialize with defaults immediately
initializeSupabaseClient();

// Try to load config from server (asynchronous)
if (typeof window !== 'undefined') {
    // First try immediately after script loads
    setTimeout(() => {
        getSupabaseConfig().then(success => {
            if (success) {
                console.log("Successfully loaded Supabase config from server");
                // Notify any waiting components
                window.dispatchEvent(new CustomEvent('supabase_initialized', { 
                    detail: { usingDefaults: false, configLoaded: true }
                }));
            }
        }).catch(err => {
            console.warn("Failed to load Supabase config, continuing with defaults:", err);
        });
    }, 0);
}

// Global Tiptap editor instance
let tiptapEditor = null;

// --- Initialization & Config ---

// Fetches Supabase config from the backend /api/config endpoint
export async function fetch_config() {
    try {
        const response = await fetch('/api/config');
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        const config = await response.json();
        if (!config.supabaseUrl || !config.supabaseAnonKey) {
            console.error('Config missing Supabase URL or Anon Key', config);
            return { 
                isOk: function() { return false; },
                isError: function() { return true; },
                value: null,
                error: "Received invalid config from server."
            };
        }
        // Gleam expects snake_case
        return { 
            isOk: function() { return true; },
            isError: function() { return false; },
            value: { supabase_url: config.supabaseUrl, supabase_anon_key: config.supabaseAnonKey },
            error: null
        };
    } catch (error) {
        console.error("Error fetching config:", error);
        return { 
            isOk: false,
            isError: true,
            value: null,
            error: error.message || "Failed to fetch config"
        };
    }
}

// Initializes the Supabase client library
export function init_supabase(url, key) {
    try {
        // Create the Supabase client using our custom implementation
        const client = create_client(url, key);
        if (client) {
            supabaseClient = client;
            console.log("Supabase client initialized and exported.");
            return { type: "Ok", 0: null };
        } else {
            console.error('Failed to create Supabase client.');
            return { type: "Error", 0: "Failed to create Supabase client." };
        }
    } catch (error) {
        console.error("Error initializing Supabase:", error);
        return { type: "Error", 0: error.message || "Failed to initialize Supabase" };
    }
}

// Initialize function that will be called once credentials are available
function initializeSupabaseClient() {
    try {
        if (supabaseClient === null) {
            // Ensure we have values before initializing
            if (!url || !key) {
                console.warn("Missing Supabase credentials, using defaults");
                url = DEFAULT_URL;
                key = DEFAULT_KEY;
            }
            
            supabaseClient = create_client(url, key);
            
            const credType = url === DEFAULT_URL ? "default development" : "custom";
            console.log(`Supabase client initialized with ${credType} credentials`);
            
            // Make Supabase client available globally for debugging in dev environments only
            if (typeof window !== 'undefined') {
                // Don't expose actual credentials in the global object
                window.__supabaseClient = {
                    isInitialized: true,
                    usingDefaults: url === DEFAULT_URL,
                    instance: supabaseClient
                };
                
                // Make a method to retry config loading
                window.__retrySupabaseConfig = function() {
                    return getSupabaseConfig();
                };
                
                // Dispatch an event to notify other modules that Supabase is ready
                window.dispatchEvent(new CustomEvent('supabase_initialized', { 
                    detail: { usingDefaults: url === DEFAULT_URL }
                }));
            }
            
            return true;
        }
        return false;
    } catch (e) {
        console.error("Failed to initialize Supabase client:", e);
        // In case of error, set client to null to allow retrying
        supabaseClient = null;
        return false;
    }
}

// Export the initialized client for other modules to use
export { supabaseClient as supabase };

// Initializes the Tiptap editor
export function init_tiptap(selector, initialContent) {
    try {
        // Assumes Tiptap libraries are loaded (e.g., via CDN)
        if (typeof Editor === 'undefined' || typeof StarterKit === 'undefined') {
            console.error("Tiptap core or StarterKit not found. Ensure Tiptap is loaded.");
            return { 
                isOk: false,
                isError: true,
                value: null,
                error: "Tiptap library not available."
            };
        }
        const element = document.querySelector(selector);
        if (!element) {
             console.error(`Tiptap mount element not found: ${selector}`);
            return { 
                isOk: false,
                isError: true,
                value: null,
                error: `Mount point ${selector} not found`
            };
        }

        if (tiptapEditor) {
            console.warn("Tiptap already initialized. Destroying previous instance.");
            tiptapEditor.destroy();
        }

        tiptapEditor = new Editor({
            element: element,
            extensions: [
                StarterKit.configure({
                    // configure options here if needed
                }),
                // Add other extensions like Link, Image, etc. if needed
            ],
            content: initialContent || '<p></p>',
            // Add editor props like handlePaste, handleDrop if needed
        });
        console.log("Tiptap editor initialized.");
        window.tiptapEditor = tiptapEditor; // Make accessible globally if needed elsewhere
        return { 
            isOk: function() { return true; },
            isError: function() { return false; },
            value: null,
            error: null
        };
    } catch (error) {
        console.error("Error initializing Tiptap:", error);
        return { 
            isOk: false,
            isError: true,
            value: null,
            error: error.message || "Failed to initialize Tiptap"
        };
    }
}

// Destroys the Tiptap editor instance
export function destroy_tiptap() {
    if (tiptapEditor && !tiptapEditor.isDestroyed) {
        tiptapEditor.destroy();
        tiptapEditor = null;
        window.tiptapEditor = null;
        console.log("Tiptap editor destroyed.");
    }
    return null; // Return Nil
}

// Gets the HTML content from the Tiptap editor
export function get_tiptap_html() {
    try {
        if (tiptapEditor && !tiptapEditor.isDestroyed) {
            return { 
                isOk: true,
                isError: false,
                value: tiptapEditor.getHTML(),
                error: null
            }; // Wrap in Ok
        }
        console.warn("get_tiptap_html called but editor not initialized or already destroyed.");
        return { 
            isOk: false,
            isError: true,
            value: null,
            error: "Editor not available"
        }; // Return Error
    } catch (error) {
        console.error("Error getting Tiptap HTML:", error);
        return { 
            isOk: false,
            isError: true,
            value: null,
            error: error.message || "Failed to get Tiptap HTML"
        };
    }
}

// --- Data Fetching (Supabase) ---

// Creates a new post in the Supabase 'posts' table
export async function create_post(postData) {
    if (!supabaseClient) return { 
        isOk: function() { return false; },
        isError: function() { return true; },
        value: null,
        error: "Supabase client not initialized"
    };
    try {
        // Map Gleam snake_case to Supabase column names if different
        // Assuming Supabase columns match PostDataForFFI fields directly
        const { data, error } = await supabaseClient
            .from('posts')
            .insert([{
                title: postData.title,
                slug: postData.slug,
                content: postData.content,
                category: postData.category,
                author: postData.author,
                date: postData.date, // Ensure this is ISO format
                excerpt: postData.excerpt,
                image: postData.image
            }])
            .select()
            .single(); // Assuming you want the created record back

        if (error) {
            console.error("Error creating post:", error);
            return { 
                isOk: function() { return false; },
                isError: function() { return true; },
                value: null,
                error: error.message || "Failed to create post" 
            };
        }
        // Map Supabase response back to Gleam Post type
        const gleamPost = {
            id: data.id, // Assuming id is returned
            slug: data.slug || null,
            title: data.title || null,
            content: data.content || null,
            date: data.date || null,
            author: data.author || null,
            category: data.category || null,
        };
        return { 
            isOk: true,
            isError: false,
            value: gleamPost,
            error: null
        };
    } catch (error) {
        console.error("Exception creating post:", error);
        return { 
            isOk: false,
            isError: true,
            value: null,
            error: error.message || "Exception occurred during post creation" 
        };
    }
}

// Fetches all posts from the Supabase 'posts' table
export async function fetch_posts() {
    if (!supabaseClient) return { 
        isOk: function() { return false; },
        isError: function() { return true; },
        value: null,
        error: "Supabase client not initialized"
    };
    try {
        const { data, error } = await supabaseClient
            .from('posts')
            .select('id, slug, title, date, author, category') // Select specific fields needed for list view
            .order('date', { ascending: false }); // Example order

        if (error) {
            console.error("Error fetching posts:", error);
            return { 
                isOk: function() { return false; },
                isError: function() { return true; },
                value: null,
                error: error.message || "Failed to fetch posts" 
            };
        }
        // Map results to the Gleam Post structure
        const gleamPosts = data.map(post => ({
            id: post.id,
            slug: post.slug || null,
            title: post.title || null,
            content: null, // Not fetching full content for list view
            date: post.date || null,
            author: post.author || null,
            category: post.category || null,
        }));
        return { 
            isOk: true,
            isError: false,
            value: gleamPosts,
            error: null
        };
    } catch (error) {
        console.error("Exception fetching post by slug:", error);
        return { 
            isOk: function() { return false; },
            isError: function() { return true; },
            value: null,
            error: error.message || "Exception creating post" 
        };
    }
}

// Fetches a single post by its slug from Supabase
export async function fetch_post_by_slug(slug) {
    if (!supabaseClient) return { 
        isOk: function() { return false; },
        isError: function() { return true; },
        value: null,
        error: "Supabase client not initialized"
    };
    try {
        const { data, error } = await supabaseClient
            .from('posts')
            .select('*') // Select all columns for single view
            .eq('slug', slug)
            .maybeSingle(); // Use maybeSingle() for Option type

        if (error) {
            console.error(`Error fetching post with slug ${slug}:`, error);
            return { 
                isOk: function() { return false; },
                isError: function() { return true; },
                value: null,
                error: error.message || "Failed to fetch post" 
            };
        }

        if (!data) {
            // Create a None value
            const noneValue = {
                isSome: function() { return false; },
                isNone: function() { return true; },
                value: null
            };
            
            return { 
                isOk: function() { return true; },
                isError: function() { return false; },
                value: noneValue,
                error: null
            }; // Gleam expects Ok(None)
        }

        // Map result to the Gleam Post structure
        const gleamPost = {
             id: data.id,
             slug: data.slug || null,
             title: data.title || null,
             content: data.content || null,
             date: data.date || null,
             author: data.author || null,
             category: data.category || null,
        };
        // Create a Some value with the post
        const someValue = {
            isSome: function() { return true; },
            isNone: function() { return false; },
            value: gleamPost
        };
        
        return { 
            isOk: function() { return true; },
            isError: function() { return false; },
            value: someValue,
            error: null
        }; // Gleam expects Ok(Some(Post))
    } catch (error) {
        console.error("Exception fetching post by slug:", error);
        return { 
            isOk: function() { return false; },
            isError: function() { return true; },
            value: null,
            error: error.message || "Exception occurred while fetching post" 
        };
    }
}

// --- URL & Navigation ---

// Gets the slug from the current URL path
export function get_slug_from_url() {
    try {
        const pathSegments = window.location.pathname.split('/').filter(Boolean);
        if (pathSegments.length >= 2 && pathSegments[0] === 'access-content') {
            return { 
                isOk: true,
                isError: false,
                value: pathSegments[1],
                error: null
            }; // Wrap Some(slug) in Ok
        }
        return { 
            isOk: true,
            isError: false,
            value: null,
            error: null
        }; // Wrap None in Ok
    } catch (error) {
        console.error("Error getting slug from URL:", error);
        return { 
            isOk: false,
            isError: true,
            value: null,
            error: error.message || "Failed to get slug from URL"
        };
    }
}

// --- UI & Misc ---

// Shows a toast notification (implementation depends on chosen library or custom code)
export function show_toast(message, toast_type) {
    try {
        console.log(`[Toast - ${toast_type}]: ${message}`);
        // Add actual toast implementation here
        return { 
            isOk: true,
            isError: false,
            value: null,
            error: null
        }; // Wrap Nil in Ok
    } catch (error) {
        console.error("Error showing toast:", error);
        return { 
            isOk: false,
            isError: true,
            value: null,
            error: error.message || "Failed to show toast"
        };
    }
}

// --- Admin & Auth (Supabase) ---

// Placeholder for admin check
export function checkAdminAuth() {
    // In a real scenario, this would check the user's roles/permissions
    // For now, let's assume the user is not an admin for this specific context
    // or integrate with the global admin check if appropriate.
    console.warn("checkAdminAuth FFI called, returning false by default.");
    return { 
        isOk: true,
        isError: false,
        value: false,
        error: null
    }; // Return Ok(False)
}

// Placeholder for setting admin auth
export function setAdminAuth() {
    // This function would typically be used after a successful admin login
    // to set a flag or token.
    console.warn("setAdminAuth FFI called, placeholder implementation.");
    return { 
        isOk: true,
        isError: false,
        value: null,
        error: null
    }; // Return Ok(Nil)
}

// Placeholder for checking a password
export function checkPasswordFFI(inputId) {
    // This function would get a password from an input field (identified by inputId)
    // and check it against a stored hash or via an API call.
    console.warn(`checkPasswordFFI FFI called for input: ${inputId}, returning false by default.`);
    const passwordElement = document.getElementById(inputId);
    if (passwordElement && passwordElement.value) {
        // Actual password check logic would go here
        // For now, let's simulate a failed check
        console.log("Password input found, but check is a placeholder.");
    } else {
        console.error(`Password input with ID '${inputId}' not found or empty.`);
    }
    return { 
        isOk: true,
        isError: false,
        value: false,
        error: null
    }; // Return Ok(False) for now
}

// Gets the current logged-in user session from Supabase
export async function get_current_user() {
    if (!supabaseClient) {
        console.warn("FFI: Supabase client is not initialized. Make sure access_content_ffi.js exports it and it's initialized before this call.");
        return { 
            isOk: function() { return false; },
            isError: function() { return true; },
            value: null,
            error: "Supabase client not initialized"
        };
    }
    try {
        const { data: { user }, error } = await supabaseClient.auth.getUser();
        if (error) {
            // Log error but return Ok(None) as per typical Gleam FFI for optional results
            console.warn("FFI getCurrentUser error, treating as no user:", error.message);
            // Create a None value
            const noneValue = {
                isSome: function() { return false; },
                isNone: function() { return true; },
                value: null
            };
            
            return { 
                isOk: function() { return true; },
                isError: function() { return false; },
                value: noneValue,
                error: null
            }; 
        }
        if (user) {
            // Create a Some value with the user
            const someValue = {
                isSome: function() { return true; },
                isNone: function() { return false; },
                value: { id: user.id, email: user.email || null }
            };
            
            return { 
                isOk: function() { return true; },
                isError: function() { return false; },
                value: someValue,
                error: null
            }; // Map to SupabaseUser
        } else {
            // Create a None value
            const noneValue = {
                isSome: function() { return false; },
                isNone: function() { return true; },
                value: null
            };
            
            return { 
                isOk: function() { return true; },
                isError: function() { return false; },
                value: noneValue,
                error: null
            }; // No user found
        }
    } catch (e) {
        console.error("FFI getCurrentUser exception:", e);
        return { 
            isOk: function() { return false; },
            isError: function() { return true; },
            value: null,
            error: e.message || "Exception in getCurrentUser"
        };
    }
}

// Initiates the Supabase sign-in flow with GitHub (or another provider)
export async function sign_in_with_github() {
    if (!supabaseClient) return { 
        isOk: function() { return false; },
        isError: function() { return true; },
        value: null,
        error: "Supabase client not initialized"
    };
    try {
        const { error } = await supabaseClient.auth.signInWithOAuth({
            provider: 'github',
            // options: {
            //   redirectTo: window.location.origin // Or a specific callback URL
            // }
        });
        if (error) {
            console.error("FFI signInWithGitHub error:", error);
            console.error("Error with GitHub sign-in:", error);
            return { 
                isOk: function() { return false; },
                isError: function() { return true; },
                value: null,
                error: error.message
            };
        }
        return {
            isOk: true,
            isError: false,
            value: null,
            error: null
        }; // signInWithOAuth redirects, so Ok(null) is fine
    } catch (e) {
        console.error("FFI signInWithGitHub exception:", e);
        return { 
            isOk: function() { return false; },
            isError: function() { return true; },
            value: null,
            error: e.message || "Exception in signInWithGitHub"
        };
    }
}

// Signs the current user out of Supabase
export async function sign_out_user() {
    if (!supabaseClient) return { 
        isOk: function() { return false; },
        isError: function() { return true; },
        value: null,
        error: "Supabase client not initialized"
    };
    
    try {
        const { error } = await supabaseClient.auth.signOut();
        
        if (error) {
            console.error("Error during sign out:", error);
            return { 
                isOk: function() { return false; },
                isError: function() { return true; },
                value: null,
                error: error.message || "Failed to sign out"
            };
        }
        
        return { 
            isOk: function() { return true; },
            isError: function() { return false; },
            value: null,
            error: null
        }; 
    } catch (e) {
        console.error("Exception during sign out:", e);
        return { 
            isOk: function() { return false; },
            isError: function() { return true; },
            value: null,
            error: e.message || "Exception during sign out"
        };
    }
}

// --- Utilities ---

// Generates a URL-friendly slug from a title string
export function generate_slug_ffi(title) {
    try {
        if (!title || typeof title !== 'string') {
           return { Error: "Invalid title for slug generation" };
        }
        const slug =
            title
                .toLowerCase()
                .trim()
                .replace(/\s+/g, '-')           // Replace spaces with -
                .replace(/[^؀-\u06FF\w-]+/g, '') // Remove all non-word chars except hyphen (adjust Unicode range if needed)
                .replace(/--+/g, '-')         // Replace multiple - with single -
                .replace(/^-+/, '')             // Trim - from start of text
                .replace(/-+$/, '');            // Trim - from end of text

        if (!slug) {
            // Handle cases where title results in empty slug (e.g., title is just symbols)
            // Generate a fallback slug based on timestamp or random string
             console.warn(`Generated empty slug for title: "${title}". Using fallback.`);
             return { Ok: `content-${Date.now()}`};
        }

        return { Ok: slug };
    } catch (error) {
        console.error("Error generating slug:", error);
        return { Error: error.message || "Failed to generate slug" };
    }
}

// Sets the innerHTML of an element found by selector
// Sets the innerHTML of an element
export function set_inner_html(selector, html) {
    try {
        const element = document.querySelector(selector);
        if (element) {
            element.innerHTML = html;
            return { 
                isOk: true,
                isError: false,
                value: null,
                error: null
            }; // Wrap Nil in Ok
        } else {
            console.warn(`Element not found for set_inner_html: ${selector}`);
            return { 
                isOk: false,
                isError: true,
                value: null,
                error: `Element ${selector} not found` 
            };
        }
    } catch (error) {
        console.error(`Error setting innerHTML for ${selector}:`, error);
        return { 
            isOk: false,
            isError: true,
            value: null,
            error: error.message || "Failed to set innerHTML" 
        };
    }
}

// Gets the current date as ISO string
export function get_current_iso_date() {
    try {
        return { 
            isOk: true,
            isError: false,
            value: new Date().toISOString(),
            error: null
        }; // Wrap string in Ok
    } catch (error) {
        console.error("Error getting current date:", error);
        return { 
            isOk: false,
            isError: true,
            value: null,
            error: error.message || "Failed to get current date" 
        };
    }
}

// Initialize the client with credentials
// Also try to initialize on DOM load to avoid race conditions
document.addEventListener('DOMContentLoaded', () => {
    if (supabaseClient === null) {
        console.log("DOMContentLoaded: Initializing Supabase client");
        // Try to initialize if we don't have a client yet
        initializeSupabaseClient();
        // And try to get config
        getSupabaseConfig();
    } else {
        console.log("DOMContentLoaded: Supabase client already initialized, checking for server credentials");
        getSupabaseConfig();
    }
});

// Final fallback - if window loads and we still don't have a client
if (typeof window !== 'undefined') {
    window.addEventListener('load', () => {
        if (supabaseClient === null) {
            console.log("Window load: Last attempt to initialize Supabase client");
            initializeSupabaseClient();
        }
        
        // Try config endpoint one more time with longer timeout
        setTimeout(() => {
            if (url === DEFAULT_URL) {
                console.log("Window loaded: Final attempt to get server config");
                getSupabaseConfig().then(success => {
                    if (success) {
                        console.log("Successfully loaded Supabase config on final attempt");
                    }
                });
            }
        }, 1000);
        
        // Force dispatch of initialized event even if client was already initialized
        // This helps modules that might have missed the initial event
        if (supabaseClient !== null) {
            window.dispatchEvent(new CustomEvent('supabase_initialized', { 
                detail: { usingDefaults: url === DEFAULT_URL, forced: true }
            }));
        }
    });
}

export function checkAccess(userId, contentId) {
  const query = select_all(
    query_table(client, 'content_access')
  )
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result
    })
}

export function grantAccess(userId, contentId) {
  const query = select_all(
    insert_row(
      query_table(client, 'content_access'),
      {
        user_id: userId,
        content_id: contentId,
        granted_at: new Date().toISOString()
      }
    )
  )
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result[0]
    })
} 