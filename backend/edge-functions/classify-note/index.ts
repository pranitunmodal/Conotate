// Supabase Edge Function for note classification
// Handles all AI classification logic: command parsing, prompt building, AI calls, JSON parsing, and mapping

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"

interface ClassificationRequest {
  text: string
  availableSections: Array<{ id: string; name: string }>
}

interface ClassificationResponse {
  sectionId: string
  confidence: number
}

interface Section {
  id: string
  name: string
}

// Parse commands from text (/task, /idea, /note, @section)
function parseCommands(
  text: string,
  availableSections: Section[]
): { cleanText: string; forcedCategory: string | null; sectionName: string | null } {
  const trimmed = text.trim()

  // Check for /task, /idea, /note commands
  if (trimmed.toLowerCase().startsWith("/task")) {
    const clean = trimmed.substring(5).trim()
    return { cleanText: clean, forcedCategory: "tasks", sectionName: null }
  }

  if (trimmed.toLowerCase().startsWith("/idea")) {
    const clean = trimmed.substring(5).trim()
    return { cleanText: clean, forcedCategory: "ideas", sectionName: null }
  }

  if (trimmed.toLowerCase().startsWith("/note")) {
    const clean = trimmed.substring(5).trim()
    return { cleanText: clean, forcedCategory: "notes", sectionName: null }
  }

  // Check for @SectionName content pattern (e.g., "@food momos")
  const atPattern = /@(\w+)\s+(.+)/i
  const match = trimmed.match(atPattern)
  if (match) {
    const sectionName = match[1]
    const content = match[2]

    // Find matching section
    const section = availableSections.find(
      (s) => s.name.toLowerCase() === sectionName.toLowerCase()
    )
    if (section) {
      return { cleanText: content, forcedCategory: section.id, sectionName: section.name }
    }
  }

  return { cleanText: trimmed, forcedCategory: null, sectionName: null }
}

// Extract JSON from text (handles both {} and () formats)
function extractJSON(text: string): string {
  // Try curly braces first (standard JSON)
  const curlyStart = text.indexOf("{")
  const curlyEnd = text.lastIndexOf("}")
  if (curlyStart !== -1 && curlyEnd !== -1 && curlyStart < curlyEnd) {
    return text.substring(curlyStart, curlyEnd + 1)
  }

  // Fallback to parentheses
  const parenStart = text.indexOf("(")
  const parenEnd = text.lastIndexOf(")")
  if (parenStart !== -1 && parenEnd !== -1 && parenStart < parenEnd) {
    return text.substring(parenStart, parenEnd + 1)
  }

  return text
}

// Fallback classification using keyword matching
function fallbackClassification(text: string): ClassificationResponse {
  const lower = text.toLowerCase().trim()

  const taskKeywords = ["get", "buy", "call", "email", "todo", "task", "do", "make"]
  const ideaKeywords = ["what if", "idea", "concept", "brainstorm", "imagine"]

  if (taskKeywords.some((keyword) => lower.includes(keyword))) {
    return { sectionId: "tasks", confidence: 0.5 }
  }

  if (ideaKeywords.some((keyword) => lower.includes(keyword))) {
    return { sectionId: "ideas", confidence: 0.5 }
  }

  return { sectionId: "unsorted", confidence: 0.4 }
}

// Map category to section ID
function mapCategoryToSectionId(
  category: string,
  availableSections: Section[],
  confidence: number
): string {
  const categoryLower = category.toLowerCase()

  // Standard categories
  if (categoryLower === "task" || categoryLower === "tasks") {
    return "tasks"
  }
  if (categoryLower === "idea" || categoryLower === "ideas") {
    return "ideas"
  }
  if (categoryLower === "note" || categoryLower === "notes") {
    return "notes"
  }
  if (categoryLower === "unsorted") {
    return "unsorted"
  }

  // Try to find matching user-defined section
  const matchingSection = availableSections.find(
    (s) => s.name.toLowerCase() === categoryLower
  )
  if (matchingSection) {
    return matchingSection.id
  }

  // Low confidence goes to unsorted
  if (confidence < 0.6) {
    return "unsorted"
  }

  return "unsorted"
}

// Call Groq API for classification
async function callGroqAPI(text: string, groqApiKey: string): Promise<string> {
  const systemPrompt = `You are a classification assistant for a personal organization app.
Classify the user's input into one of these categories:
- "task": Actionable items, todos, reminders, things to do
- "idea": Creative thoughts, possibilities, brainstorming, "what if" scenarios, imaginative concepts
- "note": Information to remember, facts, meeting notes, summaries
- "unsorted": When unclear, gibberish, ambiguous, or doesn't fit other categories

CRITICAL RULES:
1. If text is gibberish (not real words/phrases like "adhcfsbjhd", "zidwudd") → "unsorted" with confidence < 0.6
2. If text is ambiguous (single words like "banana" without context) → "unsorted" with confidence < 0.6
3. If text doesn't clearly fit any category → "unsorted" with confidence < 0.6
4. Creative/whimsical concepts (e.g., "cat powered laundry") → "idea" with high confidence
5. Action items (e.g., "get eggs") → "task" with high confidence
6. Information/facts (e.g., "Meeting at 3pm") → "note" with high confidence

Respond ONLY with valid JSON in this exact format:
{"category": "task|idea|note|unsorted", "confidence": 0.0-1.0}`

  const requestBody = {
    model: "llama-3.1-8b-instant",
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: text },
    ],
    max_tokens: 150,
    temperature: 0.1,
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
  return data.choices?.[0]?.message?.content || ""
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
    const requestBody: ClassificationRequest = await req.json()
    const { text, availableSections } = requestBody

    if (!text || typeof text !== "string") {
      return new Response(
        JSON.stringify({ error: "Invalid request: text is required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    // Parse commands first
    const { cleanText, forcedCategory, sectionName } = parseCommands(text, availableSections || [])

    // If command forces a category, return immediately
    if (forcedCategory) {
      return new Response(
        JSON.stringify({
          sectionId: forcedCategory,
          confidence: 1.0,
        }),
        {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      )
    }

    // Classify with AI
    try {
      const aiResponse = await callGroqAPI(cleanText, groqApiKey)

      // Extract JSON from response
      const jsonString = extractJSON(aiResponse)
      let aiResult: { category: string; confidence: number }

      try {
        aiResult = JSON.parse(jsonString)
      } catch {
        // If JSON parsing fails, use fallback
        const result = fallbackClassification(cleanText)
        return new Response(JSON.stringify(result), {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        })
      }

      // Validate category
      if (!aiResult.category || aiResult.category.trim() === "") {
        const result = fallbackClassification(cleanText)
        return new Response(JSON.stringify(result), {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        })
      }

      // Validate confidence
      const validatedConfidence = Math.max(0.0, Math.min(1.0, aiResult.confidence || 0.5))

      // Map category to section ID
      const sectionId = mapCategoryToSectionId(
        aiResult.category,
        availableSections || [],
        validatedConfidence
      )

      return new Response(
        JSON.stringify({
          sectionId,
          confidence: validatedConfidence,
        }),
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
      // If AI call fails, use fallback
      console.error("AI classification error:", error)
      const result = fallbackClassification(cleanText)
      return new Response(JSON.stringify(result), {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      })
    }
  } catch (error) {
    console.error("Edge function error:", error)
    return new Response(
      JSON.stringify({ error: "Internal server error", details: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
