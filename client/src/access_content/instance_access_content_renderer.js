/**
 * Instance Access Content renderer for markdown-based items
 * Handles displaying content items and lists
 */

// Initialize the content renderer with global scope
(function(window) {
  // Declare supabase variable, but don't initialize yet
  let supabase; 
  let configFetched = false;

  // Initialize the blog state
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
    const mainContent = document.querySelector('.instance-access-content-main');
    if (mainContent) {
      mainContent.innerHTML = `
        <div class="error-message">
          <h3>Error</h3>
          <p>${message}</p>
          <a href="/instance-access-content" class="back-to-posts">Back to Content</a>
        </div>
      `;
    }
  }

  // Extract post ID from URL
  function getPostIdFromUrl() {
    const path = window.location.pathname;
    if (path.startsWith('/instance-access-content/') && path !== '/instance-access-content/') {
      return path.split('/').pop();
    }
    return null;
  }

  // Show error message
  function showError(message) {
    if (typeof window.app_ffi !== 'undefined' && typeof window.app_ffi.showToast === 'function') {
      window.app_ffi.showToast(message, 'error');
    } else {
      console.error(message);
    }
  }

  // NEW: Function to fetch config and initialize Supabase
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

      // Initialize the client using the fetched config
      // Ensure we use the global Supabase object (assuming it's loaded via CDN/script tag)
      // If Supabase is imported as a module, the import name should be used instead of window.supabase
      const { createClient } = window.supabase || supabase; // Handle potential module import pattern too
      if (typeof createClient !== 'function') {
        throw new Error('Supabase createClient function not found. Ensure Supabase library is loaded.');
      }
      supabase = createClient(config.supabaseUrl, config.supabaseAnonKey);
      configFetched = true;
      console.log('Supabase client initialized.');

      // Now that Supabase is initialized, load initial data
      initializeApp(); 

    } catch (error) {
      console.error('Error fetching config or initializing Supabase:', error);
      showErrorMessage(`Failed to initialize content functionality: ${error.message}`);
      // Prevent further execution if Supabase fails
      configFetched = false; 
    }
  }

  // Load content posts from Supabase
  async function loadContentPosts() {
    if (!configFetched || !supabase) {
      console.warn('Supabase client not ready, skipping loadContentPosts.');
      // Optionally show a message or retry later
      return; 
    }
    try {
      const { data: postsData, error } = await supabase
        .from('posts')
        .select('*')
        .order('date', { ascending: false });

      if (error) throw error;
      
      let filteredPosts = postsData;

      if (state.currentCategory !== 'all') {
        filteredPosts = postsData.filter(post => post.category === state.currentCategory);
      }
      
      renderPosts(filteredPosts);
      updateRecentPosts(filteredPosts);
    } catch (error) {
      console.error('Error loading content posts:', error);
      showError('Failed to load content posts');
      // Show error in the post list area too
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
    
    if (!posts || !posts.length) {
      postList.innerHTML = '<p>No content found.</p>';
      return;
    }
    
    const html = posts.map(post => `
      <article class="content-post">
        ${post.image ? `<img src="${post.image}" alt="${post.title}" class="post-image">` : ''}
        <h2><a href="/instance-access-content/${post.id}">${post.title}</a></h2>
        <div class="post-meta">
          <span class="post-date">${formatDate(post.date)}</span>
          <span class="post-category">${post.category}</span>
          <span class="post-author">by ${post.author}</span>
        </div>
        <p class="post-excerpt">${post.excerpt || ''}</p>
        <a href="/instance-access-content/${post.id}" class="read-more">Read more →</a>
      </article>
    `).join('');
    
    postList.innerHTML = html;
  }

  // Update the recent posts sidebar
  function updateRecentPosts(posts) {
    const recentList = document.getElementById('recent-posts-list');
    if (!recentList) return;
    
    const recentPosts = posts.slice(0, 5);
    const html = recentPosts.map(post => `
      <li><a href="/instance-access-content/${post.id}" class="recent-post-link">${post.title}</a></li>
    `).join('');
    
    recentList.innerHTML = html || '<li>No recent content</li>';
  }

  // Set up event listeners for the blog
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
      
      // Show editor when create post button is clicked
      const createPostBtn = document.getElementById('create-post-btn');
      if (createPostBtn) {
        createPostBtn.addEventListener('click', () => {
          markdownEditor.classList.remove('hidden');
        });
      }
      
      // Hide editor when cancel button is clicked
      const cancelBtn = document.getElementById('cancel-markdown-btn');
      if (cancelBtn) {
        cancelBtn.addEventListener('click', () => {
          markdownEditor.classList.add('hidden');
        });
      }
    }
  }

  // Filter posts by category
  function filterByCategory(category) {
    document.querySelectorAll('.category-list a').forEach(link => {
      link.classList.toggle('active', link.dataset.category === category);
    });
    state.currentCategory = category;
    loadContentPosts(); // Reload posts with the new category
  }

  // Initialize admin features
  function initializeAdmin() {
    const adminControls = document.getElementById('admin-controls');
    if (!adminControls) return;
    
    // Check if already authenticated
    const isAuthenticated = sessionStorage.getItem('blogAdminAuthenticated') === 'true';
    if (isAuthenticated) {
      showAdminInterface();
    }
  }

  // Show the admin interface
  function showAdminInterface() {
    const createPostBtn = document.getElementById('create-post-btn');
    if (createPostBtn) {
      createPostBtn.classList.remove('hidden');
    }
    
    const adminLoginBtn = document.getElementById('admin-login-btn');
    if (adminLoginBtn) {
      adminLoginBtn.classList.add('hidden');
    }
  }

  // Load and display a single content post
  async function loadAndDisplayPost(postId) {
    if (!configFetched || !supabase) {
       console.warn('Supabase client not ready, skipping loadAndDisplayPost.');
       showErrorMessage('Content loader is not ready. Please try refreshing.');
       return;
    }
    
    const mainContent = document.querySelector('.instance-access-content-main');
    if (!mainContent) return;

    try {
      // Fetch the specific post using its ID
      const { data: post, error } = await supabase
        .from('posts')
        .select('*')
        .eq('id', postId)
        .single();

      if (error || !post) {
        throw error || new Error('Post not found');
      }

      // Update the page title
      document.title = `${post.title} - TandemX Content`;

      // Use the marked library directly (loaded via CDN)
      const contentHtml = typeof marked !== 'undefined' 
                          ? marked.parse(post.content || '') 
                          : '<p>Error: Markdown parser (Marked.js) not loaded.</p>';

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
          <a href="/instance-access-content" class="back-to-posts">← Back to Content</a>
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
      const { data, error } = await supabase
        .from('posts')
        .insert([postData])
        .select();

      if (error) throw error;

      // Success notification
      if (window.app_ffi && window.app_ffi.showToast) {
        window.app_ffi.showToast('Content created successfully!', 'success');
      } else {
        alert('Content created successfully!');
      }

      // Optionally, redirect or update the list
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
    const content = form.querySelector('#post-content').value;
    const category = form.querySelector('#post-category').value;
    const author = 'Admin'; // Or get dynamically if you have user auth
    const date = new Date().toISOString(); // Current date
    const id = title.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, ''); // Simple slug

    if (!title || !content) {
      showError('Title and content are required.');
      return;
    }

    createContentPost({ id, title, content, category, author, date });
  }

  // Initialize the application
  function initializeApp() {
    if (!configFetched) {
      // If Supabase isn't ready, don't proceed with app logic
      console.log("Waiting for Supabase initialization...");
      return;
    }

    const postId = getPostIdFromUrl();
    const mainContent = document.querySelector('.instance-access-content-main');
    const sidebar = document.querySelector('.instance-access-content-sidebar');

    if (postId) {
      // Single post view
      loadAndDisplayPost(postId);
      if (sidebar) sidebar.style.display = 'none'; // Hide sidebar on single post view
    } else if (mainContent) {
      // Post list view
      loadContentPosts();
      if (sidebar) sidebar.style.display = 'block';
    }

    setupEventListeners();
    initializeAdmin();
  }

  // Initial setup: Fetch config first, then initialize app
  document.addEventListener('DOMContentLoaded', () => {
     // Check if Supabase client script is loaded
    if (typeof supabase === 'undefined' && typeof window.supabase === 'undefined') {
      console.error("Supabase client library not found. Please ensure it's included in your HTML.");
      showErrorMessage("Required library (Supabase) is missing. Cannot load content.");
      return; // Stop initialization if Supabase script isn't loaded
    }
    fetchConfigAndInitSupabase(); 
  });

  // Expose necessary functions to the global scope if needed
  // e.g., window.blogRenderer = { init: initializeApp };

})(window); 