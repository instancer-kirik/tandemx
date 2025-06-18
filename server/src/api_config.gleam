import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option
import gleam/result
import gleam/string
import gleam/erlang/process
import gleam/io
import gleam/json
import gleam/dynamic
import glenvy/env
import glenvy/dotenv

pub fn handle_request(_req: Request(String)) -> Response(String) {
  // Load environment variables from .env file
  let _ = dotenv.load()
  
  let supabase_url = env.string("SUPABASE_URL")
  let supabase_anon_key = env.string("SUPABASE_ANON_KEY")
  
  case supabase_url, supabase_anon_key {
    Ok(url), Ok(key) -> {
      let config = json.object([
        #("supabaseUrl", json.string(url)),
        #("supabaseAnonKey", json.string(key))
      ])
      
      response.new(200)
      |> response.set_header("content-type", "application/json")
      |> response.set_header("Access-Control-Allow-Origin", "*")
      |> response.set_body(json.to_string(config))
    }
    _, _ -> {
      let error_config = json.object([
        #("error", json.string("Supabase configuration not available")),
        #("status", json.int(500))
      ])
      
      response.new(500)
      |> response.set_header("content-type", "application/json")
      |> response.set_header("Access-Control-Allow-Origin", "*")
      |> response.set_body(json.to_string(error_config))
    }
  }
}

pub fn register() {
  // Load environment variables from .env file
  let _ = dotenv.load()
  io.println("Registering API config endpoint at /api/config")
  
  // Log environment variable status
  case env.string("SUPABASE_URL"), env.string("SUPABASE_ANON_KEY") {
    Ok(_), Ok(_) -> io.println("Supabase environment variables found")
    _, _ -> io.println("Warning: Supabase environment variables not found")
  }
}