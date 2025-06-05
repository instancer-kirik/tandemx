// JavaScript FFI module for Supabase client
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

// Create a Supabase client
export function create_client(url, key) {
  // Simple client object to satisfy the interface
  return {
    host: url,
    key: key
  };
}

// Query a table
export function query_table(client, table) {
  console.log(`Querying table: ${table} with client:`, client);
  return {
    client: client,
    table: table,
    method: "GET",
    select_columns: { type: "Some", 0: "*" },
    filters: [],
    body: { type: "None" },
    expect_single: false
  };
}

// Select all from a table
export function select_all(builder) {
  return {
    client: builder.client,
    table: builder.table,
    method: "GET",
    select_columns: { type: "Some", 0: "*" },
    filters: builder.filters,
    body: builder.body,
    expect_single: builder.expect_single
  };
}

// Select specific columns
export function select_columns(builder, columns) {
  return {
    client: builder.client,
    table: builder.table,
    method: "GET",
    select_columns: { type: "Some", 0: columns },
    filters: builder.filters,
    body: builder.body,
    expect_single: builder.expect_single
  };
}

// Insert a row into a table
export function insert_row(builder, data) {
  return {
    client: builder.client,
    table: builder.table,
    method: "POST",
    select_columns: builder.select_columns,
    filters: builder.filters,
    body: { type: "Some", 0: data },
    expect_single: builder.expect_single
  };
}

// Filter by equality
export function filter_eq(builder, column, value) {
  const newFilters = [...builder.filters, ["eq", column, value]];
  return {
    client: builder.client,
    table: builder.table,
    method: builder.method,
    select_columns: builder.select_columns,
    filters: newFilters,
    body: builder.body,
    expect_single: builder.expect_single
  };
}

// Run a custom query
export function run_query(builder) {
  console.log(`Running query with:`, builder);
  // Mock successful response
  return {
    type: "Ok",
    0: []
  };
}