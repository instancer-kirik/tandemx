export async function sendRequest(method, url, headers, body) {
  const startTime = performance.now();
  
  try {
    const response = await fetch(url, {
      method: method,
      headers: headers,
      body: method !== 'GET' ? body : undefined,
    });

    const responseHeaders = {};
    response.headers.forEach((value, key) => {
      responseHeaders[key] = value;
    });

    const responseBody = await response.text();
    const timeMs = Math.round(performance.now() - startTime);

    return {
      Ok: {
        status: response.status,
        headers: responseHeaders,
        body: responseBody,
        time_ms: timeMs,
      }
    };
  } catch (error) {
    return {
      Error: error.message || 'Network error occurred'
    };
  }
} 