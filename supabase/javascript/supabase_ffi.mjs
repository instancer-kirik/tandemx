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