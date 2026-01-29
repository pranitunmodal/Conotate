// Supabase Edge Function to proxy Groq API calls
// This function uses the GROQ_API_KEY secret stored in Supabase

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"

interface GroqRequest {
  model: string
  messages: Array<{ role: string; content: string }>
  max_tokens?: number
  temperature?: number
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    })
  }

  try {
    // Get the authorization header to verify user is authenticated
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      )
    }

    // Initialize Supabase client to verify user
    // These are automatically provided by Supabase Edge Functions
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? ""
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? ""
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    
    if (!supabaseUrl || (!supabaseAnonKey && !supabaseServiceRoleKey)) {
      console.error("Supabase configuration missing", {
        hasUrl: !!supabaseUrl,
        hasAnonKey: !!supabaseAnonKey,
        hasServiceKey: !!supabaseServiceRoleKey
      })
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }
    
    // Extract token from Authorization header
    const token = authHeader.replace("Bearer ", "").trim()
    
    if (!token || token.length === 0) {
      return new Response(
        JSON.stringify({ error: "Invalid token", details: "Token is empty" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      )
    }

    // Create Supabase client with anon key (sufficient for verifying user tokens)
    // Service role key is not needed for getUser() - it can verify user tokens with anon key
    if (!supabaseAnonKey) {
      console.error("SUPABASE_ANON_KEY not found")
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }
    
    const supabase = createClient(supabaseUrl, supabaseAnonKey)

    // Verify the user's session by getting the user from the token
    // getUser() with a token verifies the JWT and returns the user
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)

    if (authError) {
      console.error("Auth error:", {
        message: authError.message,
        status: authError.status,
        name: authError.name
      })
      return new Response(
        JSON.stringify({ 
          code: 401,
          message: "Invalid JWT",
          details: authError.message 
        }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      )
    }

    if (!user) {
      return new Response(
        JSON.stringify({ 
          code: 401,
          message: "Unauthorized",
          details: "User not found" 
        }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      )
    }

    // Get Groq API key from Supabase secrets
    const groqApiKey = Deno.env.get("GROQ_API_KEY")
    if (!groqApiKey) {
      console.error("GROQ_API_KEY secret not found")
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }

    // Parse the request body
    const groqRequest: GroqRequest = await req.json()

    // Forward request to Groq API
    const groqResponse = await fetch(GROQ_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${groqApiKey}`,
      },
      body: JSON.stringify(groqRequest),
    })

    if (!groqResponse.ok) {
      const errorText = await groqResponse.text()
      console.error("Groq API error:", errorText)
      return new Response(
        JSON.stringify({ error: "Groq API error", details: errorText }),
        { 
          status: groqResponse.status, 
          headers: { "Content-Type": "application/json" } 
        }
      )
    }

    const groqData = await groqResponse.json()

    // Return the response with CORS headers
    return new Response(JSON.stringify(groqData), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    })
  } catch (error) {
    console.error("Edge function error:", error)
    return new Response(
      JSON.stringify({ error: "Internal server error", details: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
