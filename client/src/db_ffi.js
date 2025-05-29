import {
  create_client,
  query_table,
  select_all,
  select_columns,
  insert_row,
  update_row,
  delete_row,
  filter_eq,
  run_query
} from '../../supabase/build/dev/javascript/supabase/supabase_ffi.mjs'

// Simplified environment variable detection
function getSupabaseConfig() {
  // Check for environment variables in various places
  let url = 'https://xlmibzeenudmkqgiyaif.supabase.co'; // Default from your existing .env
  let key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhsbWliemVlbnVkbWtxZ2l5YWlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMzODAxNzMsImV4cCI6MjA1ODk1NjE3M30.Yn9AIaqkstjgz1coNJGB-o66L7wiJZZvCXfqyM6Wavs';
  
  // If running in browser with window._env, use those values if available
  if (typeof window !== 'undefined' && window._env) {
    url = window._env.SUPABASE_URL || window._env.NEXT_PUBLIC_SUPABASE_URL || url;
    key = window._env.SUPABASE_ANON_KEY || window._env.NEXT_PUBLIC_SUPABASE_ANON_KEY || key;
  }
  
  // If running in Node.js, check process.env
  if (typeof process !== 'undefined' && process.env) {
    if (process.env.SUPABASE_URL) url = process.env.SUPABASE_URL;
    if (process.env.NEXT_PUBLIC_SUPABASE_URL) url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    if (process.env.SUPABASE_ANON_KEY) key = process.env.SUPABASE_ANON_KEY;
    if (process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  }
  
  return { url, key };
}

// Initialize the client
const { url, key } = getSupabaseConfig();
const client = create_client(url, key);
console.log('🔌 Supabase client initialized with URL:', url.substring(0, 25) + '...');

export function initDb() {
  return client
}

export function createMeeting(meeting) {
  const query = select_all(insert_row(query_table(client, 'meetings'), meeting))
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result[0]
    })
}

export function getMeeting(id) {
  const query = filter_eq(select_all(query_table(client, 'meetings')), 'id', id)
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result[0]
    })
}

export function listMeetings() {
  const query = select_all(query_table(client, 'meetings'))
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result
    })
}

export function updateMeeting(id, updates) {
  const query = select_all(filter_eq(update_row(query_table(client, 'meetings'), updates), 'id', id))
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result[0]
    })
}

export function deleteMeeting(id) {
  const query = filter_eq(delete_row(query_table(client, 'meetings')), 'id', id)
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return true
    })
}

// Contact management
export function createContact(contact) {
  const query = select_all(insert_row(query_table(client, 'contacts'), contact))
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result[0]
    })
}

export function getContact(id) {
  const query = filter_eq(select_all(query_table(client, 'contacts')), 'id', id)
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result[0]
    })
}

export function listContacts() {
  const query = select_all(query_table(client, 'contacts'))
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result
    })
}

// Calendar operations
export function createCalendarEvent(event) {
  const query = select_all(insert_row(query_table(client, 'calendar_events'), event))
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result[0]
    })
}

export function getCalendarEvent(id) {
  const query = filter_eq(select_all(query_table(client, 'calendar_events')), 'id', id)
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result[0]
    })
}

export function listCalendarEvents(startDate, endDate) {
  let query = select_all(query_table(client, 'calendar_events'))
    
  if (startDate) {
    query = filter_eq(query, 'start_timestamp', startDate)
  }
  if (endDate) {
    query = filter_eq(query, 'end_timestamp', endDate)
  }
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result
    })
}

// Blog post operations
export function createBlogPost(post) {
  const query = select_all(insert_row(query_table(client, 'posts'), post))
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result[0]
    })
}

export function getBlogPost(id) {
  const query = filter_eq(select_all(query_table(client, 'posts')), 'id', id)
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result[0]
    })
}

export function listBlogPosts(options = {}) {
  let query = select_all(query_table(client, 'posts'))
  
  // Filter by published status if specified
  if (options.published !== undefined) {
    query = filter_eq(query, 'published', options.published.toString())
  }
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result
    })
}

export function updateBlogPost(id, updates) {
  const query = select_all(filter_eq(update_row(query_table(client, 'posts'), updates), 'id', id))
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result[0]
    })
}

export function deleteBlogPost(id) {
  const query = filter_eq(delete_row(query_table(client, 'posts')), 'id', id)
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return true
    })
}

// Calendar system operations
export function getCalendarEpochs(calendarSystem) {
  let query = select_all(query_table(client, 'calendar_epoch_correlations'))
  
  if (calendarSystem) {
    query = filter_eq(query, 'calendar_system', calendarSystem)
  }
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result
    })
}

export function convertCalendarDate(params) {
  // Using the RPC function defined in the SQL
  const query = insert_row(
    query_table(client, 'rpc/convert_calendar_date'),
    {
      source_calendar: params.sourceCalendar,
      source_variant: params.sourceVariant,
      source_components: params.sourceComponents,
      target_calendar: params.targetCalendar,
      target_variant: params.targetVariant
    }
  )
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result
    })
}

// Calendar special days
export function getCalendarSpecialDays(calendarSystem) {
  let query = select_all(query_table(client, 'calendar_special_days'))
  
  if (calendarSystem) {
    query = filter_eq(query, 'calendar_system', calendarSystem)
  }
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result
    })
}

// Planet models
export function getPlanetModels() {
  const query = select_all(query_table(client, 'planet_models'))
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result
    })
}

export function getPlanetModel(name) {
  const query = filter_eq(
    select_columns(
      query_table(client, 'planet_models'),
      '*,planet_textures(*),planet_atmospheres(*),planet_rings(*),planet_effects(*)'
    ),
    'planet_name',
    name
  )
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result[0]
    })
}

// Interest submissions
export function createInterestSubmission(submission) {
  const query = select_all(insert_row(query_table(client, 'interest_submissions'), submission))
  
  return run_query(query)
    .then(result => {
      if (result instanceof Error) throw result
      return result[0]
    })
} 