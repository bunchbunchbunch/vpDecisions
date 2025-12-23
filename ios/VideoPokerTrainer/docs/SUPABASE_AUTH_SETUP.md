# Supabase Auth Setup Guide

Follow these steps to enable Google OAuth in your Video Poker Trainer app.

## Step 1: Create the Profiles Table

Run this SQL in your Supabase SQL Editor (Dashboard > SQL Editor > New Query):

```sql
-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  default_game TEXT DEFAULT 'jacks-or-better-9-6',
  sound_enabled BOOLEAN DEFAULT true,
  haptics_enabled BOOLEAN DEFAULT true,
  close_decisions_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Policy: Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## Step 2: Enable Google OAuth Provider

1. Go to your Supabase Dashboard
2. Navigate to **Authentication** > **Providers**
3. Find **Google** and enable it
4. You'll need to provide:
   - **Client ID** (from Google Cloud Console)
   - **Client Secret** (from Google Cloud Console)

## Step 3: Set Up Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to **APIs & Services** > **Credentials**
4. Click **Create Credentials** > **OAuth 2.0 Client IDs**
5. Configure the OAuth consent screen first if prompted
6. For Application type, select **Web application**
7. Add these Authorized redirect URIs:
   - `https://ctqefgdvqiaiumtmcjdz.supabase.co/auth/v1/callback`
8. Copy the **Client ID** and **Client Secret**

### OAuth Credentials Configuration

> **Note**: Your Google OAuth Client ID and Client Secret are configured in:
> - Google Cloud Console (APIs & Services > Credentials)
> - Supabase Dashboard (Authentication > Providers > Google)
>
> These credentials should be kept secure and not committed to version control.

## Step 4: Add Redirect URL to Supabase

1. In Supabase Dashboard, go to **Authentication** > **URL Configuration**
2. Add these to **Redirect URLs**:
   - `vptrainer://auth/callback` (for mobile app)
   - `exp://localhost:8081/--/auth/callback` (for Expo Go development)
   - `http://localhost:8081` (for web development)

## Step 5: Test the Integration

1. Restart Expo: `npx expo start --clear`
2. Open the app
3. You should see the sign-in screen
4. Tap "Continue with Google"
5. Complete the OAuth flow
6. You should be redirected back to the app and see the home screen

## Troubleshooting

### "redirect_uri_mismatch" Error
Make sure the redirect URL in your Google Cloud Console matches exactly what Supabase expects. Check the error message for the expected URL.

### Auth Session Not Persisting
The app uses AsyncStorage for session persistence. Make sure `@react-native-async-storage/async-storage` is properly installed.

### Profile Not Creating
Check that the profiles table was created correctly and RLS policies are in place. Look at the Supabase logs for any errors.

## Environment Variables (Optional)

For production, you may want to move these to environment variables:

```javascript
const SUPABASE_URL = process.env.EXPO_PUBLIC_SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;
```

Create a `.env` file:
```
EXPO_PUBLIC_SUPABASE_URL=https://ctqefgdvqiaiumtmcjdz.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
```
