// JavaScript FFI module for Supabase client

// Import Supabase library from CDN if not available locally
let createClient;

// Try to use the global supabase object if it exists
if (typeof window !== 'undefined' && window.supabase) {
  console.log('Using global Supabase client');
  createClient = window.supabase.createClient;
} else {
  // Dynamically import Supabase from CDN if needed
  console.log('Loading Supabase client from CDN');
  const script = document.createElement('script');
  script.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';
  script.async = true;
  document.head.appendChild(script);
  
  // Wait for script to load before creating client
  script.onload = () => {
    console.log('Supabase client loaded from CDN');
    createClient = window.supabase.createClient;
  };
}

// Create a Supabase client
export function create_client(url, key) {
  console.log(`Creating Supabase client for ${url}`);
  
  // If the Supabase client library is loaded, use it
  if (typeof createClient === 'function') {
    try {
      return createClient(url, key);
    } catch (e) {
      console.error('Error creating Supabase client:', e);
    }
  }
  
  // Fallback implementation with required methods
  return {
    host: url,
    key: key,
    from: function(table) {
      console.log(`Creating query builder for table: ${table}`);
      return {
        table: table,
        _select: '*',
        _filters: [],
        _limit: null,
        _order: null,
        
        select: function(columns = '*') {
          this._select = columns;
          return this;
        },
        
        eq: function(column, value) {
          this._filters.push({ type: 'eq', column, value });
          return this;
        },
        
        limit: function(count) {
          this._limit = count;
          return this;
        },
        
        order: function(column, options) {
          this._order = { column, ...options };
          return this;
        },
        
        single: function() {
          this._limit = 1;
          return this._execute(true);
        },
        
        maybeSingle: function() {
          this._limit = 1;
          return this._execute(false);
        },
        
        _execute: async function() {
          console.log(`[FALLBACK] Executing query on ${this.table}:`, {
            select: this._select,
            filters: this._filters,
            limit: this._limit,
            order: this._order
          });
          
          try {
            // Make a real fetch request to Supabase REST API
            const headers = {
              'apikey': key,
              'Authorization': `Bearer ${key}`,
              'Content-Type': 'application/json'
            };
            
            // Build the URL with filters
            let apiUrl = `${url}/rest/v1/${this.table}?select=${this._select}`;
            
            // Apply filters
            this._filters.forEach(filter => {
              if (filter.type === 'eq') {
                apiUrl += `&${filter.column}=eq.${encodeURIComponent(filter.value)}`;
              }
            });
            
            // Add limit if specified
            if (this._limit) {
              apiUrl += `&limit=${this._limit}`;
            }
            
            // Add order if specified
            if (this._order) {
              apiUrl += `&order=${this._order.column}.${this._order.ascending ? 'asc' : 'desc'}`;
            }
            
            console.log(`[FALLBACK] Fetching from: ${apiUrl}`);
            const response = await fetch(apiUrl, { headers });
            
            if (!response.ok) {
              throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            const data = await response.json();
            return { data, error: null };
          } catch (error) {
            console.error('[FALLBACK] Error executing query:', error);
            return { data: null, error: error.message };
          }
        }
      };
    },
    
    auth: {
      signIn: async function(credentials) {
        console.warn('[FALLBACK] Auth.signIn called but not fully implemented');
        return { data: null, error: null };
      },
      signOut: async function() {
        console.warn('[FALLBACK] Auth.signOut called but not fully implemented');
        return { error: null };
      },
      onAuthStateChange: function(callback) {
        console.warn('[FALLBACK] Auth.onAuthStateChange called but not fully implemented');
        return { data: { subscription: { unsubscribe: () => {} } } };
      }
    }
  };
}

// Helper functions that work with the above client

export function query_table(client, table) {
  return client.from(table);
}

export function select_all(builder) {
  return builder.select('*');
}

export function select_columns(builder, columns) {
  return builder.select(columns);
}

export function filter_eq(builder, column, value) {
  return builder.eq(column, value);
}

export function insert_row(builder, data) {
  return {
    ...builder,
    insert: async function() {
      try {
        console.log(`Inserting data into ${builder.table}:`, data);
        
        // Use Supabase insert if available
        if (builder.insert) {
          return await builder.insert(data);
        }
        
        // Otherwise use fallback
        const headers = {
          'apikey': builder.client?.key || '',
          'Authorization': `Bearer ${builder.client?.key || ''}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation'
        };
        
        const apiUrl = `${builder.client?.host || ''}/rest/v1/${builder.table}`;
        
        const response = await fetch(apiUrl, { 
          method: 'POST',
          headers,
          body: JSON.stringify(data)
        });
        
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const responseData = await response.json();
        return { data: responseData, error: null };
      } catch (error) {
        console.error('Error inserting data:', error);
        return { data: null, error: error.message };
      }
    }
  };
}

export function run_query(builder) {
  console.log('Running query...');
  
  // Execute the query and convert to Gleam-compatible format
  return builder._execute().then(result => {
    if (result.error) {
      return {
        type: "Error",
        0: result.error
      };
    } else {
      return {
        type: "Ok",
        0: result.data || []
      };
    }
  }).catch(error => {
    return {
      type: "Error",
      0: error.message
    };
  });
}

// Utility for HTTP requests (kept for compatibility)
export function js_fetch(url, options) {
  try {
    const parsedOptions = JSON.parse(options);
    return fetch(url, parsedOptions)
      .then(async response => {
        const body = await response.text();
        return {
          type: "Ok",
          0: {
            status: response.status,
            body: body
          }
        };
      })
      .catch(error => ({
        type: "Error",
        0: error.message
      }));
  } catch (error) {
    return {
      type: "Error",
      0: error.message
    };
  }
}