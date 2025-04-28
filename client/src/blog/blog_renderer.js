/**
 * Blog renderer for markdown-based posts
 * Handles displaying blog posts and post lists
 */

// Initialize the blog renderer with global scope
(function(window) {
  // Initialize Supabase client
  const supabaseUrl = 'your-project-url.supabase.co';
  const supabaseKey = 'your-anon-key';
  const supabase = supabase.createClient(supabaseUrl, supabaseKey);

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
    const mainContent = document.querySelector('.blog-main');
    if (mainContent) {
      mainContent.innerHTML = `
        <div class="error-message">
          <h3>Error</h3>
          <p>${message}</p>
          <a href="/blog" class="back-to-posts">Back to Blog</a>
        </div>
      `;
    }
  }

  // Extract post ID from URL
  function getPostIdFromUrl() {
    const path = window.location.pathname;
    if (path.startsWith('/blog/') && path !== '/blog/' && path !== '/blog') {
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

  // Load blog posts from Supabase
  async function loadBlogPosts() {
    try {
      const { data: posts, error } = await supabase
        .from('posts')
        .select('*')
        .order('date', { ascending: false });

      if (error) throw error;
      
      if (state.currentCategory !== 'all') {
        posts = posts.filter(post => post.category === state.currentCategory);
      }
      
      renderPosts(posts);
      updateRecentPosts(posts);
    } catch (error) {
      console.error('Error loading blog posts:', error);
      showError('Failed to load blog posts');
      // Show error in the post list area too
      const postList = document.getElementById('blog-post-list');
      if (postList) {
        postList.innerHTML = '<div class="error-message">Failed to load blog posts. Please try again later.</div>';
      }
    }
  }

  // Render posts to the post list
  function renderPosts(posts) {
    const postList = document.getElementById('blog-post-list');
    if (!postList) return;
    
    if (!posts || !posts.length) {
      postList.innerHTML = '<p>No posts found.</p>';
      return;
    }
    
    const html = posts.map(post => `
      <article class="blog-post">
        ${post.image ? `<img src="${post.image}" alt="${post.title}" class="post-image">` : ''}
        <h2><a href="/blog/${post.id}">${post.title}</a></h2>
        <div class="post-meta">
          <span class="post-date">${formatDate(post.date)}</span>
          <span class="post-category">${post.category}</span>
          <span class="post-author">by ${post.author}</span>
        </div>
        <p class="post-excerpt">${post.excerpt || ''}</p>
        <a href="/blog/${post.id}" class="read-more">Read more →</a>
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
      <li><a href="/blog/${post.id}" class="recent-post-link">${post.title}</a></li>
    `).join('');
    
    recentList.innerHTML = html || '<li>No recent posts</li>';
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
    loadBlogPosts(); // Reload posts with the new category
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

  // Load and display a single blog post
  async function loadAndDisplayPost(postId) {
    try {
      // Show loading state
      const mainContent = document.querySelector('.blog-main');
      if (mainContent) {
        mainContent.innerHTML = '<div class="loading-post">Loading post...</div>';
      }
      
      const { data: post, error } = await supabase
        .from('posts')
        .select('*')
        .eq('id', postId)
        .single();

      if (error) throw error;
      
      if (!post) {
        showErrorMessage('Blog post not found.');
        return;
      }

      // Create post view
      const postView = `
        <div class="full-blog-post">
          <h1 class="post-title">${post.title || 'Untitled Post'}</h1>
          <div class="post-meta">
            <span class="post-date">${formatDate(post.date)}</span>
            <span class="post-author">by ${post.author || 'instance.select'}</span>
            <span class="post-category">${post.category || 'Uncategorized'}</span>
          </div>
          
          <div class="post-content">
            ${marked.parse(post.content)}
          </div>
          
          <div class="post-navigation">
            <a href="/blog" class="back-to-posts">← Back to All Posts</a>
          </div>
        </div>
      `;
      
      // Update page
      if (mainContent) {
        mainContent.innerHTML = postView;
      }
      
      // Update page title
      document.title = `${post.title || 'Blog Post'} - instance.select`;
    } catch (error) {
      console.error('Error loading post:', error);
      showErrorMessage('Failed to load the blog post. It may have been moved or deleted.');
    }
  }

  // Create a new blog post
  async function createBlogPost(postData) {
    try {
      const { data, error } = await supabase
        .from('posts')
        .insert([postData])
        .select()
        .single();

      if (error) throw error;

      showError('Post created successfully!'); // Use as success message
      
      // Reload posts to show the new one
      loadBlogPosts();
      
      return data;
    } catch (error) {
      console.error('Error creating post:', error);
      showError(error.message);
      throw error;
    }
  }

  // Handle post form submission
  function handlePostSubmit(event) {
    event.preventDefault();
    
    const postData = {
      id: document.getElementById('post-id').value,
      title: document.getElementById('post-title').value,
      content: document.getElementById('post-content').value,
      date: document.getElementById('post-date').value,
      author: 'instance.select', // Default author
      category: document.getElementById('post-category').value,
      excerpt: document.getElementById('post-excerpt').value,
      image: document.getElementById('post-image').value || null
    };

    createBlogPost(postData)
      .then(() => {
        // Hide the editor
        document.getElementById('markdown-editor').classList.add('hidden');
        
        // Clear the form
        document.getElementById('post-id').value = '';
        document.getElementById('post-title').value = '';
        document.getElementById('post-content').value = '';
        document.getElementById('post-excerpt').value = '';
        document.getElementById('post-image').value = '';
      })
      .catch(error => {
        console.error('Failed to create post:', error);
      });
  }

  // Export the initBlog function to global scope
  window.initBlog = function() {
    console.log('Initializing blog...');
    
    // Load blog posts
    loadBlogPosts();
    
    // Set up event listeners
    setupEventListeners();
    
    // Initialize admin features
    initializeAdmin();
    
    // Check if we need to load a specific post
    const postId = getPostIdFromUrl();
    if (postId) {
      loadAndDisplayPost(postId);
    }
    
    console.log('Blog initialization complete');
  };

})(window); 