# Supabase Edge Function Setup for Groq API Proxy

## Overview

This guide explains how to set up a Supabase Edge Function that acts as a proxy for Groq API calls. This allows you to:
- Store your Groq API key securely as a Supabase secret
- Users never need to enter API keys
- Control API usage and costs centrally
- Works seamlessly with TestFlight distribution

## Architecture

```
macOS App → Supabase Edge Function → Groq API
```

The Edge Function:
1. Authenticates the user via Supabase Auth
2. Retrieves the Groq API key from Supabase secrets
3. Forwards the request to Groq API
4. Returns the response to the app

## Step 1: Install Supabase CLI

1. Install the Supabase CLI:
   ```bash
   brew install supabase/tap/supabase
   ```

2. Login to Supabase:
   ```bash
   supabase login
   ```

3. Link your project:
   ```bash
   cd /path/to/conotate_v2.0
   supabase link --project-ref YOUR_PROJECT_REF
   ```
   
   You can find your project ref in your Supabase dashboard URL: `https://supabase.com/dashboard/project/YOUR_PROJECT_REF`

## Step 2: Add Groq API Key as Secret

1. In your Supabase Dashboard, go to **Settings** → **Edge Functions** → **Secrets**
2. Click **Add Secret**
3. Enter:
   - **Name**: `GROQ_API_KEY`
   - **Value**: Your Groq API key (from https://console.groq.com/)
4. Click **Save**

Alternatively, using the CLI:
```bash
supabase secrets set GROQ_API_KEY=your_groq_api_key_here
```

## Step 3: Deploy Edge Function

The Edge Function code is already in `supabase/functions/groq-proxy/index.ts`.

### Option A: Using the deployment script (Recommended)

1. Run the deployment script:
   ```bash
   ./deploy-edge-function.sh
   ```

### Option B: Manual deployment

1. Deploy the function:
   ```bash
   supabase functions deploy groq-proxy
   ```

2. Verify deployment:
   - Go to **Edge Functions** in your Supabase Dashboard
   - You should see `groq-proxy` listed

## Step 4: Test the Edge Function

You can test the function using curl:

```bash
# Get your access token (you'll need to be logged in via the app first)
# Then test:
curl -X POST \
  'https://YOUR_PROJECT_REF.supabase.co/functions/v1/groq-proxy' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "llama-3.1-8b-instant",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 10
  }'
```

## Step 5: Verify App Integration

1. Build and run your app
2. Log in with Supabase credentials
3. Create a note - it should be classified automatically using AI
4. Check the console logs - you should see successful API calls

## Troubleshooting

### Error: "Supabase not configured"
- Make sure `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set in your Xcode scheme

### Error: "Unauthorized" from Edge Function
- The user must be logged in via Supabase Auth
- Check that the access token is being sent correctly

### Error: "Server configuration error"
- The `GROQ_API_KEY` secret is not set in Supabase
- Go to Settings → Edge Functions → Secrets and add it

### Error: "Groq API error"
- Check your Groq API key is valid
- Verify you have credits/quota in your Groq account
- Check Supabase Edge Function logs in the dashboard

## Local Development

To test the Edge Function locally:

1. Start Supabase locally:
   ```bash
   supabase start
   ```

2. Set the secret locally:
   ```bash
   supabase secrets set GROQ_API_KEY=your_key_here --local
   ```

3. Serve the function locally:
   ```bash
   supabase functions serve groq-proxy
   ```

4. Update your app to use the local URL (for testing only):
   - In `SupabaseService.swift`, temporarily change `edgeFunctionURL` to use `http://localhost:54321/functions/v1/groq-proxy`

## Cost Considerations

- **Supabase Edge Functions**: Free tier includes 500K invocations/month
- **Groq API**: Pay-per-use pricing (very affordable)
- **Data Transfer**: Minimal, as Edge Function is close to Groq servers

## Security Notes

- The Groq API key is stored securely in Supabase secrets
- Only authenticated users can access the Edge Function
- The API key never leaves Supabase servers
- All requests are logged in Supabase Edge Function logs

## Updating the Edge Function

If you need to modify the Edge Function:

1. Edit `supabase/functions/groq-proxy/index.ts`
2. Redeploy:
   ```bash
   supabase functions deploy groq-proxy
   ```

## Next Steps

Once set up, your app will:
- ✅ Work seamlessly with TestFlight (no user API keys needed)
- ✅ Use your centralized Groq API key
- ✅ Authenticate users automatically
- ✅ Scale without user intervention
