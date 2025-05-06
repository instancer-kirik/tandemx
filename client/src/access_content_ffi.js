// FFI functions for access_content.gleam

// Global Supabase client instance (initialized by init_supabase)
let supabase = null;

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
            return { Error: "Received invalid config from server." };
        }
        // Gleam expects snake_case
        return { Ok: { supabase_url: config.supabaseUrl, supabase_anon_key: config.supabaseAnonKey } };
    } catch (error) {
        console.error("Error fetching config:", error);
        return { Error: error.message || "Failed to fetch config" };
    }
}

// Initializes the Supabase client library
export function init_supabase(url, key) {
    try {
        // Assumes Supabase JS v2 is available globally or imported
        if (typeof supabase !== 'undefined' && supabase?.createClient) {
           supabase = supabase.createClient(url, key);
            console.log("Supabase client initialized.");
            return { Ok: null };
        } else {
            console.error('Supabase client library (supabase-js v2) not found.');
            return { Error: "Supabase library not available." };
        }
    } catch (error) {
        console.error("Error initializing Supabase:", error);
        return { Error: error.message || "Failed to initialize Supabase" };
    }
}

// Initializes the Tiptap editor
export function init_tiptap(selector, initialContent) {
    try {
        // Assumes Tiptap libraries are loaded (e.g., via CDN)
        if (typeof Editor === 'undefined' || typeof StarterKit === 'undefined') {
            console.error("Tiptap core or StarterKit not found. Ensure Tiptap is loaded.");
            return { Error: "Tiptap library not available." };
        }
        const element = document.querySelector(selector);
        if (!element) {
             console.error(`Tiptap mount element not found: ${selector}`);
            return { Error: `Mount point ${selector} not found` };
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
        return { Ok: null };
    } catch (error) {
        console.error("Error initializing Tiptap:", error);
        return { Error: error.message || "Failed to initialize Tiptap" };
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
            return { Ok: tiptapEditor.getHTML() }; // Wrap in Ok
        }
        console.warn("get_tiptap_html called but editor not initialized or already destroyed.");
        return { Error: "Editor not available" }; // Return Error
    } catch (error) {
        console.error("Error getting Tiptap HTML:", error);
        return { Error: error.message || "Failed to get Tiptap HTML" };
    }
}

// --- Data Fetching (Supabase) ---

// Creates a new post in the Supabase 'posts' table
export async function create_post(postData) {
    if (!supabase) return { Error: "Supabase client not initialized" };
    try {
        // Map Gleam snake_case to Supabase column names if different
        // Assuming Supabase columns match PostDataForFFI fields directly
        const { data, error } = await supabase
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
            return { Error: error.message || "Failed to create post" };
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
        return { Ok: gleamPost };
    } catch (error) {
        console.error("Exception creating post:", error);
        return { Error: error.message || "Exception occurred during post creation" };
    }
}

// Fetches all posts from the Supabase 'posts' table
export async function fetch_posts() {
    if (!supabase) return { Error: "Supabase client not initialized" };
    try {
        const { data, error } = await supabase
            .from('posts')
            .select('id, slug, title, date, author, category') // Select specific fields needed for list view
            .order('date', { ascending: false }); // Example order

        if (error) {
            console.error("Error fetching posts:", error);
            return { Error: error.message || "Failed to fetch posts" };
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
        return { Ok: gleamPosts };
    } catch (error) {
        console.error("Exception fetching posts:", error);
        return { Error: error.message || "Exception occurred during post fetching" };
    }
}

// Fetches a single post by its slug from Supabase
export async function fetch_post_by_slug(slug) {
    if (!supabase) return { Error: "Supabase client not initialized" };
    try {
        const { data, error } = await supabase
            .from('posts')
            .select('*') // Select all columns for single view
            .eq('slug', slug)
            .maybeSingle(); // Use maybeSingle() for Option type

        if (error) {
            console.error(`Error fetching post with slug ${slug}:`, error);
            return { Error: error.message || "Failed to fetch post" };
        }

        if (!data) {
            return { Ok: null }; // Gleam expects Ok(None) -> represented as Ok(null)
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
        return { Ok: gleamPost }; // Gleam expects Ok(Some(Post)) -> represented as Ok(Post)
    } catch (error) {
        console.error("Exception fetching post by slug:", error);
        return { Error: error.message || "Exception occurred fetching post" };
    }
}

// --- URL & Navigation ---

// Gets the slug from the current URL path
export function get_slug_from_url() {
    try {
        const pathSegments = window.location.pathname.split('/').filter(Boolean);
        if (pathSegments.length >= 2 && pathSegments[0] === 'access-content') {
            return { Ok: pathSegments[1] }; // Wrap Some(slug) in Ok
        }
        return { Ok: null }; // Wrap None in Ok
    } catch (error) {
        console.error("Error getting slug from URL:", error);
        return { Error: error.message || "Failed to get slug from URL" };
    }
}

// --- UI & Misc ---

// Shows a toast notification (implementation depends on chosen library or custom code)
export function show_toast(message, toast_type) {
    try {
        console.log(`[Toast - ${toast_type}]: ${message}`);
        // Add actual toast implementation here
        return { Ok: null }; // Wrap Nil in Ok
    } catch (error) {
        console.error("Error showing toast:", error);
        return { Error: error.message || "Failed to show toast" };
    }
}

// --- Admin & Auth (Supabase) ---

// Gets the current logged-in user session from Supabase
export async function get_current_user() {
    if (!supabase) return { Error: "Supabase client not initialized" };
    try {
        const { data: { session }, error: sessionError } = await supabase.auth.getSession();
        if (sessionError) throw sessionError;

        if (!session) {
            return { Ok: null }; // No active session, return Ok(None)
        }

        // Session exists, get user data
        const { data: { user }, error: userError } = await supabase.auth.getUser();
        if (userError) throw userError;

        if (!user) {
             console.warn("Session found but failed to get user data.");
             return { Ok: null }; // Should ideally not happen if session exists
        }

        // Map to Gleam SupabaseUser type
        const gleamUser = {
            id: user.id,
            email: user.email || null, // email might be null
        };
        return { Ok: gleamUser }; // Return Ok(Some(User))

    } catch (error) {
        console.error("Error getting current user:", error);
        return { Error: error.message || "Failed to get current user session" };
    }
}

// Initiates the Supabase sign-in flow with GitHub (or another provider)
export async function sign_in_with_github() {
    if (!supabase) return { Error: "Supabase client not initialized" };
    try {
        // Redirects the user to the provider's login page
        const { error } = await supabase.auth.signInWithOAuth({
            provider: 'github',
            // Add options like redirectTo if needed:
            // options: {
            //   redirectTo: window.location.origin + '/access-content' 
            // }
        });
        if (error) throw error;

        // Important: This function likely won't "return" in the traditional sense
        // because of the redirect. The user will come back to the page, and
        // the CheckSession logic should run again to detect the new session.
        return { Ok: null };

    } catch (error) {
        console.error("Error signing in with GitHub:", error);
        return { Error: error.message || "Failed to initiate GitHub sign-in" };
    }
}

// Signs the current user out of Supabase
export async function sign_out_user() {
    if (!supabase) return { Error: "Supabase client not initialized" };
    try {
        const { error } = await supabase.auth.signOut();
        if (error) throw error;

        console.log("User signed out.");
        // Clear any potentially related local/session storage if needed
        // sessionStorage.removeItem('contentAdminAuthenticated'); // Removed old insecure flag
        return { Ok: null }; // Return Ok(Nil)

    } catch (error) {
        console.error("Error signing out:", error);
        return { Error: error.message || "Failed to sign out" };
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
export function set_inner_html(selector, html) {
    try {
        const element = document.querySelector(selector);
        if (element) {
            element.innerHTML = html;
            return { Ok: null }; // Wrap Nil in Ok
        } else {
            console.warn(`Element not found for set_inner_html: ${selector}`);
            return { Error: `Element ${selector} not found` };
        }
    } catch (error) {
        console.error(`Error setting innerHTML for ${selector}:`, error);
        return { Error: error.message || "Failed to set innerHTML" };
    }
}

// Gets the current date as an ISO string
export function get_current_iso_date() {
    try {
        return { Ok: new Date().toISOString() }; // Wrap string in Ok
    } catch (error) {
        console.error("Error getting current date:", error);
        return { Error: error.message || "Failed to get current date" };
    }
} 