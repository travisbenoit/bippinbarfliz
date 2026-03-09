# Spotify Integration Setup Guide

This guide will walk you through setting up Spotify integration to enable real song search and sharing in your app.

## Overview

The app currently uses mock data for music search. To enable real Spotify integration, you'll need to:
1. Create a Spotify Developer account
2. Register your application
3. Implement OAuth authentication
4. Use the Spotify Web API for search

## Step 1: Create a Spotify Developer Account

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Log in with your Spotify account (or create one if needed)
3. Accept the Terms of Service

## Step 2: Create an App

1. Click **"Create app"** in the dashboard
2. Fill in the app details:
   - **App name**: Your app name (e.g., "Swarm Social")
   - **App description**: Brief description of your app
   - **Redirect URI**: `http://localhost:5173/callback` (for development)
     - For production, add your deployed URL: `https://yourdomain.com/callback`
   - **Website**: Optional
   - **API/SDK**: Check "Web API"
3. Click **"Save"**
4. You'll receive:
   - **Client ID**: A public identifier for your app
   - **Client Secret**: Keep this secret! Never expose it in frontend code

## Step 3: Add Environment Variables

Add your Spotify credentials to `.env`:

```env
# Spotify API Configuration
VITE_SPOTIFY_CLIENT_ID=your_client_id_here
VITE_SPOTIFY_REDIRECT_URI=http://localhost:5173/callback
```

**Important**: The Client Secret should NEVER be in your frontend code. You'll need to implement a backend proxy for token exchange.

## Step 4: Implementation Options

### Option A: Client Credentials Flow (Recommended for Search Only)

This is simpler but only allows searching - no user-specific actions like saving songs.

Create a Supabase Edge Function to handle token generation:

```typescript
// supabase/functions/spotify-search/index.ts
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const { query } = await req.json();

    // Get access token using Client Credentials
    const authString = btoa(`${Deno.env.get('SPOTIFY_CLIENT_ID')}:${Deno.env.get('SPOTIFY_CLIENT_SECRET')}`);

    const tokenResponse = await fetch('https://accounts.spotify.com/api/token', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${authString}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    });

    const { access_token } = await tokenResponse.json();

    // Search Spotify
    const searchResponse = await fetch(
      `https://api.spotify.com/v1/search?q=${encodeURIComponent(query)}&type=track&limit=20`,
      {
        headers: {
          'Authorization': `Bearer ${access_token}`,
        },
      }
    );

    const data = await searchResponse.json();

    // Transform Spotify data to your format
    const songs = data.tracks.items.map((track: any) => ({
      id: track.id,
      title: track.name,
      artist: track.artists.map((a: any) => a.name).join(', '),
      albumArtUrl: track.album.images[0]?.url,
      previewUrl: track.preview_url,
      externalUrl: track.external_urls.spotify,
      platform: 'spotify'
    }));

    return new Response(JSON.stringify({ songs }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
```

Add Spotify secrets to your Supabase project:
```bash
# In your Supabase project settings, add these secrets:
SPOTIFY_CLIENT_ID=your_client_id
SPOTIFY_CLIENT_SECRET=your_client_secret
```

Update `musicService.ts`:

```typescript
private async searchSpotify(query: string): Promise<Song[]> {
  try {
    const { data: { session } } = await supabase.auth.getSession();

    const response = await fetch(
      `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/spotify-search`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${session?.access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ query }),
      }
    );

    const { songs } = await response.json();
    return songs;
  } catch (error) {
    console.error('Spotify search error:', error);
    return [];
  }
}
```

### Option B: Authorization Code Flow (Full User Access)

This allows users to save songs to their Spotify library, but requires more complex OAuth setup.

1. **Add OAuth flow to your app**:
   - User clicks "Connect Spotify"
   - Redirect to Spotify authorization page
   - User grants permissions
   - Spotify redirects back with authorization code
   - Exchange code for access token (via backend)
   - Store access token securely

2. **Implement token refresh**:
   - Access tokens expire after 1 hour
   - Use refresh token to get new access token
   - Store tokens securely in your database

This is more complex and requires:
- A callback route to handle OAuth redirect
- Secure token storage
- Token refresh logic
- Backend proxy for sensitive operations

## Step 5: Deploy the Edge Function

```bash
# Deploy the Spotify search function
supabase functions deploy spotify-search
```

## Security Best Practices

1. **Never expose Client Secret in frontend code**
2. **Always use HTTPS in production**
3. **Implement rate limiting** on your API endpoints
4. **Validate all user inputs** before sending to Spotify API
5. **Handle token expiration** gracefully
6. **Store tokens encrypted** if using OAuth flow

## Rate Limits

Spotify API has rate limits:
- **Client Credentials**: ~100 requests per minute
- **User Authorization**: Varies by endpoint

Implement caching and debouncing for search queries to avoid hitting limits.

## Testing

1. Use the Spotify Web API Console to test queries: [https://developer.spotify.com/console/](https://developer.spotify.com/console/)
2. Test with various search terms to ensure proper data transformation
3. Verify error handling for failed requests
4. Test rate limit handling

## Additional Resources

- [Spotify Web API Documentation](https://developer.spotify.com/documentation/web-api)
- [Spotify Authorization Guide](https://developer.spotify.com/documentation/general/guides/authorization/)
- [Spotify Web API Reference](https://developer.spotify.com/documentation/web-api/reference/)

## Support

For Spotify API issues, check:
- [Spotify Community Forum](https://community.spotify.com/t5/Spotify-for-Developers/bd-p/Spotify_Developer)
- [Spotify API Status](https://developer.spotify.com/status/)
