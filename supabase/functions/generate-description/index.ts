// Supabase Edge Function for generating section descriptions
// Uses Groq API to generate natural descriptions based on notes in a section

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"

interface DescriptionRequest {
  notes: Array<{ text: string }>
  sectionName: string
}

interface DescriptionResponse {
  description: string
}

// Call Groq API to generate description
async function callGroqAPI(
  notes: Array<{ text: string }>,
  sectionName: string,
  groqApiKey: string
): Promise<string> {
  if (notes.length === 0) {
    return `This is the ${sectionName} section. Add notes to generate a summary.`
  }

  const notesText = notes
    .slice(0, 5)
    .map((note) => note.text)
    .join("\n")

  const prompt = `Based on these notes from the "${sectionName}" section, generate a brief, natural description (1-2 sentences):

${notesText}

Description:`

  const requestBody = {
    model: "llama-3.1-8b-instant",
    messages: [{ role: "user", content: prompt }],
    max_tokens: 100,
    temperature: 0.7,
  }

  const response = await fetch(GROQ_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${groqApiKey}`,
    },
    body: JSON.stringify(requestBody),
  })

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`Groq API error: ${errorText}`)
  }

  const data = await response.json()
  const description = data.choices?.[0]?.message?.content?.trim() || `A collection of notes about ${sectionName}.`

  return description
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
    // Verify authentication
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      )
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? ""
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? ""

    if (!supabaseUrl || !supabaseAnonKey) {
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey)
    const token = authHeader.replace("Bearer ", "").trim()

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

    // Get Groq API key
    const groqApiKey = Deno.env.get("GROQ_API_KEY")
    if (!groqApiKey) {
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }

    // Parse request body
    const requestBody: DescriptionRequest = await req.json()
    const { notes, sectionName } = requestBody

    if (!sectionName || typeof sectionName !== "string") {
      return new Response(
        JSON.stringify({ error: "Invalid request: sectionName is required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    if (!Array.isArray(notes)) {
      return new Response(
        JSON.stringify({ error: "Invalid request: notes must be an array" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    // Generate description
    try {
      const description = await callGroqAPI(notes, sectionName, groqApiKey)

      return new Response(
        JSON.stringify({ description }),
        {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
          },
        }
      )
    } catch (error) {
      console.error("Description generation error:", error)
      // Fallback description
      const fallbackDescription = notes.length === 0
        ? `This is the ${sectionName} section. Add notes to generate a summary.`
        : `A collection of notes about ${sectionName}.`

      return new Response(
        JSON.stringify({ description: fallbackDescription }),
        {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      )
    }
  } catch (error) {
    console.error("Edge function error:", error)
    return new Response(
      JSON.stringify({ error: "Internal server error", details: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
