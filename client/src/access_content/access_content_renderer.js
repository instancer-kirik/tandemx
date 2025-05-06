/**
 * Access Content renderer for markdown-based items // Updated comment
 * Handles displaying content items and lists
 */

// Initialize the content renderer with global scope
(function(window) {
  // Declare supabase variable, but don't initialize yet
  let supabase; 
  let configFetched = false;

  // Initialize the state
  const state = {
    posts: [],
    currentCategory: 'all',
    isAdmin: false
  };

  // Format a date string
  function formatDate(dateString) {
    if (!dateString) return 'Unknown date';
    
    try {
      const date = new Date(dateString);
      return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      });
    } catch (e) {
      return dateString; // Fallback to original string if parsing fails
    }
  }

  // Show error message to user
  function showErrorMessage(message) {
    const mainContent = document.querySelector('.access-content-main'); // Updated selector
    if (mainContent) {
      mainContent.innerHTML = `
        <div class="error-message">
          <h3>Error</h3>
          <p>${message}</p>
          <a href="/access-content" class="back-to-posts">Back to Content</a> // Updated href
        </div>
      `;
    }
  }

  // Extract slug from URL
  function getSlugFromUrl() { // Renamed function
    const path = window.location.pathname;
    if (path.startsWith('/access-content/') && path.split('/').length > 2) { // Updated path check
      return path.split('/').pop(); // Get the last segment as slug
    }
    return null;
  }

  // Show error message (using toast or console)
  function showError(message) {
    if (typeof window.app_ffi !== 'undefined' && typeof window.app_ffi.showToast === 'function') {
      window.app_ffi.showToast(message, 'error');
    } else {
      console.error(message);
    }
  }

  // Fetch config and initialize Supabase
  async function fetchConfigAndInitSupabase() {
    try {
      const response = await fetch('/api/config');
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const config = await response.json();

      if (!config.supabaseUrl || !config.supabaseAnonKey) {
        throw new Error('Supabase configuration missing or incomplete.');
      }

      const { createClient } = window.supabase || supabase;
      if (typeof createClient !== 'function') {
        throw new Error('Supabase createClient function not found.');
      }
      supabase = createClient(config.supabaseUrl, config.supabaseAnonKey);
      configFetched = true;
      console.log('Supabase client initialized.');

      initializeApp(); // Load initial data now

    } catch (error) {
      console.error('Error fetching config or initializing Supabase:', error);
      showErrorMessage(`Failed to initialize content functionality: ${error.message}`);
      configFetched = false; 
    }
  }

  // Load content posts from Supabase
  async function loadContentPosts() {
    if (!configFetched || !supabase) {
      console.warn('Supabase client not ready, skipping loadContentPosts.');
      return; 
    }
    try {
      // Assuming Supabase table is 'posts' and has a 'slug' column
      const { data: postsData, error } = await supabase
        .from('posts')
        .select('*, slug') // Ensure slug is selected
        .order('date', { ascending: false });

      if (error) throw error;
      
      state.posts = postsData || []; // Update state
      let filteredPosts = state.posts;

      if (state.currentCategory !== 'all') {
        filteredPosts = state.posts.filter(post => post.category === state.currentCategory);
      }
      
      renderPosts(filteredPosts);
      updateRecentPosts(state.posts); // Update recent with all posts
    } catch (error) {
      console.error('Error loading content posts:', error);
      showError('Failed to load content posts');
      const postList = document.getElementById('content-post-list');
      if (postList) {
        postList.innerHTML = '<div class="error-message">Failed to load content. Please try again later.</div>';
      }
    }
  }

  // Render posts to the post list
  function renderPosts(posts) {
    const postList = document.getElementById('content-post-list');
    if (!postList) return;
    
    if (!posts || posts.length === 0) {
      postList.innerHTML = '<p>No content found.</p>';
      return;
    }
    
    // Use post.slug for the link
    const html = posts.map(post => ` 
      <article class="content-post">
        ${post.image ? `<img src="${post.image}" alt="${post.title}" class="post-image">` : ''}
        <h2><a href="/access-content/${post.slug || post.id}">${post.title}</a></h2> <!-- Use slug, fallback to id -->
        <div class="post-meta">
          <span class="post-date">${formatDate(post.date)}</span>
          <span class="post-category">${post.category}</span>
          <span class="post-author">by ${post.author}</span>
        </div>
        <p class="post-excerpt">${post.excerpt || ''}</p>
        <a href="/access-content/${post.slug || post.id}" class="read-more">Read more →</a> <!-- Use slug, fallback to id -->
      </article>
    `).join('');
    
    postList.innerHTML = html;
  }

  // Update the recent posts sidebar
  function updateRecentPosts(posts) {
    const recentList = document.getElementById('recent-posts-list');
    if (!recentList) return;
    
    const recentPosts = (posts || []).slice(0, 5);
    // Use post.slug for the link
    const html = recentPosts.map(post => `
      <li><a href="/access-content/${post.slug || post.id}" class="recent-post-link">${post.title}</a></li> <!-- Use slug, fallback to id -->
    `).join('');
    
    recentList.innerHTML = html || '<li>No recent content</li>';
  }

  // Set up event listeners
  function setupEventListeners() {
    // Category filtering
    document.querySelectorAll('.category-list a').forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        const category = e.target.dataset.category;
        filterByCategory(category);
      });
    });
    
    // Add post creation form handler
    const markdownEditor = document.getElementById('markdown-editor');
    if (markdownEditor) {
      const form = markdownEditor.querySelector('.editor-form');
      if (form) {
        form.addEventListener('submit', handlePostSubmit);
      }
      
      const createPostBtn = document.getElementById('create-post-btn');
      if (createPostBtn) {
        createPostBtn.addEventListener('click', () => markdownEditor.classList.remove('hidden'));
      }
      
      const cancelBtn = document.getElementById('cancel-markdown-btn');
      if (cancelBtn) {
        cancelBtn.addEventListener('click', () => markdownEditor.classList.add('hidden'));
      }
    }
  }

  // Filter posts by category
  function filterByCategory(category) {
    document.querySelectorAll('.category-list a').forEach(link => {
      link.classList.toggle('active', link.dataset.category === category);
    });
    state.currentCategory = category;
    // Filter state.posts locally instead of re-fetching
    const filtered = category === 'all' 
      ? state.posts 
      : state.posts.filter(post => post.category === category);
    renderPosts(filtered);
  }

  // Initialize admin features
  function initializeAdmin() {
    const adminControls = document.getElementById('admin-controls');
    if (!adminControls) return;
    
    // Use the correct session storage key
    const isAuthenticated = sessionStorage.getItem('contentAdminAuthenticated') === 'true'; 
    if (isAuthenticated) {
      showAdminInterface();
    }
  }

  // Show the admin interface
  function showAdminInterface() {
    const createPostBtn = document.getElementById('create-post-btn');
    if (createPostBtn) createPostBtn.classList.remove('hidden');
    
    const adminLoginBtn = document.getElementById('admin-login-btn');
    if (adminLoginBtn) adminLoginBtn.classList.add('hidden');
  }

  // Load and display a single content post by slug
  async function loadAndDisplayPost(slug) { // Parameter is slug
    if (!configFetched || !supabase) {
       console.warn('Supabase client not ready, skipping loadAndDisplayPost.');
       showErrorMessage('Content loader is not ready. Please try refreshing.');
       return;
    }
    
    const mainContent = document.querySelector('.access-content-main'); // Updated selector
    if (!mainContent) return;
    mainContent.innerHTML = '<div class="loading-posts">Loading content...</div>'; // Show loading

    try {
      // Fetch the specific post using its slug
      const { data: post, error } = await supabase
        .from('posts')
        .select('*')
        .eq('slug', slug) // Query by slug
        .single();

      if (error || !post) {
        throw error || new Error('Content not found');
      }

      // Update the page title
      document.title = `${post.title} - TandemX Content`;

      // **Render Fetched HTML Directly:**
      // Remove markdown parsing, as content is now stored as HTML
      const contentHtml = post.content || '<p>No content available.</p>'; 

      // Render the post content
      mainContent.innerHTML = `
        <article class="content-post-full">
          <h1>${post.title}</h1>
          <div class="post-meta">
            <span class="post-date">${formatDate(post.date)}</span>
            <span class="post-category">${post.category}</span>
            <span class="post-author">by ${post.author}</span>
          </div>
          ${post.image ? `<img src="${post.image}" alt="${post.title}" class="post-image-full">` : ''}
          <div class="post-content">${contentHtml}</div>
          <a href="/access-content" class="back-to-posts">← Back to Content</a> // Updated href
        </article>
      `;
      
      // Syntax Highlighting (if using Prism)
      if (window.Prism) {
        window.Prism.highlightAll();
      }

    } catch (error) {
      console.error('Error loading post:', error);
      showErrorMessage(`Failed to load content: ${error.message}`);
    }
  }

  // Create a new content post
  async function createContentPost(postData) {
    if (!configFetched || !supabase) {
      showError('Supabase client not initialized');
      return;
    }
    try {
      // Add slug to postData before insert
      const slug = (postData.title || '').toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
      const dataToInsert = { ...postData, slug };
        
      const { data, error } = await supabase
        .from('posts')
        .insert([dataToInsert]) // Insert data with slug
        .select();

      if (error) throw error;

      // Success notification
      if (window.app_ffi && window.app_ffi.showToast) {
        window.app_ffi.showToast('Content created successfully!', 'success');
      } else {
        alert('Content created successfully!');
      }

      // Reload the list
      loadContentPosts(); 
      
      // Hide the editor
      const markdownEditor = document.getElementById('markdown-editor');
      if (markdownEditor) {
        markdownEditor.classList.add('hidden');
        markdownEditor.querySelector('.editor-form').reset();
      }

    } catch (error) {
      console.error('Error creating content post:', error);
      showError(`Failed to create content: ${error.message}`);
    }
  }

  // Handle post submission
  function handlePostSubmit(event) {
    event.preventDefault();
    const form = event.target;
    const title = form.querySelector('#post-title').value;
    // Get content from Tiptap editor
    const content = window.tiptapEditor ? window.tiptapEditor.getHTML() : ''; 
    const category = form.querySelector('#post-category').value;
    const excerpt = form.querySelector('#post-excerpt').value; // Get excerpt
    const image = form.querySelector('#post-image').value; // Get image
    const author = 'Admin'; // Or get dynamically
    const date = new Date().toISOString();

    if (!title || !content) {
      showError('Title and content are required.');
      return;
    }

    // Pass excerpt and image too
    createContentPost({ title, content, category, author, date, excerpt, image }); 
  }

  // Initialize the application
  function initializeApp() {
    if (!configFetched) {
      console.log("Waiting for Supabase initialization...");
      return;
    }

    const slug = getSlugFromUrl(); // Get slug from URL
    const mainContent = document.querySelector('.access-content-main'); // Updated selector
    const sidebar = document.querySelector('.access-content-sidebar'); // Updated selector

    if (slug) {
      // Single content item view
      loadAndDisplayPost(slug); // Load by slug
      if (sidebar) sidebar.style.display = 'none';
    } else if (mainContent) {
      // Content list view
      loadContentPosts();
      if (sidebar) sidebar.style.display = 'block';
    }

    setupEventListeners();
    initializeAdmin();
  }

  // Initial setup: Fetch config first, then initialize app
  document.addEventListener('DOMContentLoaded', () => {
    if (typeof supabase === 'undefined' && typeof window.supabase === 'undefined') {
      console.error("Supabase client library not found.");
      showErrorMessage("Required library (Supabase) is missing.");
      return;
    }
    fetchConfigAndInitSupabase(); 
  });

})(window); 