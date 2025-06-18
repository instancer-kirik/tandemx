// supabase-config.js - Configuration helper for Supabase
(function() {
  // Default configuration for development
  window.SUPABASE_CONFIG = {
    url: 'https://demo.supabase.co',
    key: 'public-anon-key',
    loaded: false,
    env: 'development'
  };

  // Try to load configuration from server
  async function loadConfig() {
    try {
      console.log('Attempting to fetch Supabase config from server...');
      
      // Try multiple endpoint variations due to path handling differences
      const endpoints = [
        '/api/config',
        'api/config',
        '/config',
        'config'
      ];
      
      let response = null;
      let data = null;
      
      for (const endpoint of endpoints) {
        try {
          response = await fetch(endpoint, {
            method: 'GET',
            headers: { 'Accept': 'application/json' },
            cache: 'no-store'
          });
          
          if (response.ok) {
            data = await response.json();
            break;
          }
        } catch (innerErr) {
          console.warn(`Failed to fetch from ${endpoint}: ${innerErr.message}`);
        }
      }
      
      if (!data) {
        throw new Error('Could not fetch configuration from any endpoint');
      }
      
      // Update global config with server values
      if (data.supabase && data.supabase.url) {
        window.SUPABASE_CONFIG.url = data.supabase.url;
        window.SUPABASE_CONFIG.loaded = true;
      }
      
      if (data.supabase && data.supabase.key) {
        window.SUPABASE_CONFIG.key = data.supabase.key;
      }
      
      if (data.env) {
        window.SUPABASE_CONFIG.env = data.env;
      }
      
      console.log(`Supabase config loaded from server: ${window.SUPABASE_CONFIG.url}`);
      
      // Dispatch event so other scripts know config is ready
      window.dispatchEvent(new CustomEvent('supabase-config-loaded', {
        detail: window.SUPABASE_CONFIG
      }));
      
      return window.SUPABASE_CONFIG;
    } catch (err) {
      console.warn('Error loading Supabase config from server, using defaults:', err.message);
      
      // Dispatch event even with default config
      window.dispatchEvent(new CustomEvent('supabase-config-loaded', {
        detail: window.SUPABASE_CONFIG
      }));
      
      return window.SUPABASE_CONFIG;
    }
  }

  // Export loadConfig function
  window.loadSupabaseConfig = loadConfig;
  
  // Auto-load config when script is included
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadConfig);
  } else {
    loadConfig();
  }
})();