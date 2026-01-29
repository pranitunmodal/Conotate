#!/bin/bash

# Script to deploy the Supabase Edge Function for Groq API proxy
# Make sure you have: 1) Installed Supabase CLI, 2) Logged in, 3) Linked your project

echo "🚀 Deploying Supabase Edge Function: groq-proxy"
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Install it with: brew install supabase/tap/supabase"
    exit 1
fi

# Deploy Edge Functions from backend/edge-functions directory
echo "📦 Deploying Edge Functions..."
echo ""

# Note: Supabase CLI expects functions in supabase/functions/ by default
# If your CLI is configured differently, adjust paths accordingly

# Deploy classify-note function
echo "Deploying classify-note..."
supabase functions deploy classify-note --project-ref $(supabase status | grep "API URL" | awk '{print $3}' | cut -d'/' -f3 | cut -d'.' -f1) || supabase functions deploy classify-note

# Deploy generate-description function
echo "Deploying generate-description..."
supabase functions deploy generate-description --project-ref $(supabase status | grep "API URL" | awk '{print $3}' | cut -d'/' -f3 | cut -d'.' -f1) || supabase functions deploy generate-description

# Legacy groq-proxy (deprecated)
echo "Deploying groq-proxy (legacy)..."
supabase functions deploy groq-proxy --project-ref $(supabase status | grep "API URL" | awk '{print $3}' | cut -d'/' -f3 | cut -d'.' -f1) || supabase functions deploy groq-proxy

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Edge Function deployed successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Add your Groq API key as a secret:"
    echo "   supabase secrets set GROQ_API_KEY=your_groq_api_key_here"
    echo ""
    echo "   Or in the dashboard:"
    echo "   Settings → Edge Functions → Secrets → Add Secret"
    echo ""
    echo "2. Test the function by using your app - it should now use the Edge Function!"
else
    echo ""
    echo "❌ Deployment failed. Make sure you:"
    echo "   - Are logged in: supabase login"
    echo "   - Have linked your project: supabase link --project-ref YOUR_PROJECT_REF"
    exit 1
fi
