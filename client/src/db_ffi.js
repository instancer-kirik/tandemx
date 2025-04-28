import { createClient } from '@supabase/supabase-js'

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
const supabase = createClient(url, key);
console.log('🔌 Supabase client initialized with URL:', url.substring(0, 25) + '...');

export function initDb() {
  return supabase
}

export function createMeeting(meeting) {
  return supabase
    .from('meetings')
    .insert([meeting])
    .select()
    .then(({ data, error }) => {
      if (error) throw error
      return data[0]
    })
}

export function getMeeting(id) {
  return supabase
    .from('meetings')
    .select('*')
    .eq('id', id)
    .single()
    .then(({ data, error }) => {
      if (error) throw error
      return data
    })
}

export function listMeetings() {
  return supabase
    .from('meetings')
    .select('*')
    .order('date', { ascending: true })
    .then(({ data, error }) => {
      if (error) throw error
      return data
    })
}

export function updateMeeting(id, updates) {
  return supabase
    .from('meetings')
    .update(updates)
    .eq('id', id)
    .select()
    .then(({ data, error }) => {
      if (error) throw error
      return data[0]
    })
}

export function deleteMeeting(id) {
  return supabase
    .from('meetings')
    .delete()
    .eq('id', id)
    .then(({ error }) => {
      if (error) throw error
      return true
    })
}

// Contact management
export function createContact(contact) {
  return supabase
    .from('contacts')
    .insert([contact])
    .select()
    .then(({ data, error }) => {
      if (error) throw error
      return data[0]
    })
}

export function getContact(id) {
  return supabase
    .from('contacts')
    .select('*')
    .eq('id', id)
    .single()
    .then(({ data, error }) => {
      if (error) throw error
      return data
    })
}

export function listContacts() {
  return supabase
    .from('contacts')
    .select('*')
    .order('full_name', { ascending: true })
    .then(({ data, error }) => {
      if (error) throw error
      return data
    })
}

// Calendar operations
export function createCalendarEvent(event) {
  return supabase
    .from('calendar_events')
    .insert([event])
    .select()
    .then(({ data, error }) => {
      if (error) throw error
      return data[0]
    })
}

export function getCalendarEvent(id) {
  return supabase
    .from('calendar_events')
    .select('*')
    .eq('id', id)
    .single()
    .then(({ data, error }) => {
      if (error) throw error
      return data
    })
}

export function listCalendarEvents(startDate, endDate) {
  let query = supabase
    .from('calendar_events')
    .select('*')
    
  if (startDate) {
    query = query.gte('start_timestamp', startDate)
  }
  if (endDate) {
    query = query.lte('end_timestamp', endDate)
  }
  
  return query
    .order('start_timestamp', { ascending: true })
    .then(({ data, error }) => {
      if (error) throw error
      return data
    })
}

// Blog post operations
export function createBlogPost(post) {
  return supabase
    .from('posts')
    .insert([post])
    .select()
    .then(({ data, error }) => {
      if (error) throw error
      return data[0]
    })
}

export function getBlogPost(id) {
  return supabase
    .from('posts')
    .select('*')
    .eq('id', id)
    .single()
    .then(({ data, error }) => {
      if (error) throw error
      return data
    })
}

export function listBlogPosts(options = {}) {
  let query = supabase
    .from('posts')
    .select('*')
  
  // Filter by published status if specified
  if (options.published !== undefined) {
    query = query.eq('published', options.published)
  }
  
  // Filter by category if specified
  if (options.category) {
    query = query.eq('category', options.category)
  }
  
  // Apply limit if specified
  if (options.limit) {
    query = query.limit(options.limit)
  }
  
  return query
    .order('date', { ascending: false })
    .then(({ data, error }) => {
      if (error) throw error
      return data
    })
}

export function updateBlogPost(id, updates) {
  return supabase
    .from('posts')
    .update(updates)
    .eq('id', id)
    .select()
    .then(({ data, error }) => {
      if (error) throw error
      return data[0]
    })
}

export function deleteBlogPost(id) {
  return supabase
    .from('posts')
    .delete()
    .eq('id', id)
    .then(({ error }) => {
      if (error) throw error
      return true
    })
}

// Calendar system operations
export function getCalendarEpochs(calendarSystem) {
  let query = supabase
    .from('calendar_epoch_correlations')
    .select('*')
  
  if (calendarSystem) {
    query = query.eq('calendar_system', calendarSystem)
  }
  
  return query.then(({ data, error }) => {
    if (error) throw error
    return data
  })
}

export function convertCalendarDate(params) {
  // Using the RPC function defined in the SQL
  return supabase
    .rpc('convert_calendar_date', {
      source_calendar: params.sourceCalendar,
      source_variant: params.sourceVariant,
      source_components: params.sourceComponents,
      target_calendar: params.targetCalendar,
      target_variant: params.targetVariant
    })
    .then(({ data, error }) => {
      if (error) throw error
      return data
    })
}

// Calendar special days
export function getCalendarSpecialDays(calendarSystem) {
  let query = supabase
    .from('calendar_special_days')
    .select('*')
  
  if (calendarSystem) {
    query = query.eq('calendar_system', calendarSystem)
  }
  
  return query.then(({ data, error }) => {
    if (error) throw error
    return data
  })
}

// Planet models
export function getPlanetModels() {
  return supabase
    .from('planet_models')
    .select('*')
    .then(({ data, error }) => {
      if (error) throw error
      return data
    })
}

export function getPlanetModel(name) {
  return supabase
    .from('planet_models')
    .select(`
      *,
      planet_textures (*),
      planet_atmospheres (*),
      planet_rings (*),
      planet_effects (*)
    `)
    .eq('planet_name', name)
    .single()
    .then(({ data, error }) => {
      if (error) throw error
      return data
    })
}

// Interest submissions
export function createInterestSubmission(submission) {
  return supabase
    .from('interest_submissions')
    .insert([submission])
    .select()
    .then(({ data, error }) => {
      if (error) throw error
      return data[0]
    })
} 