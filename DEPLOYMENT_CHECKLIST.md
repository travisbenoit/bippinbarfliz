# Twilio SMS Deployment Checklist

## Before Inviting Testers - CRITICAL STEP

You MUST run this command ONE TIME to deploy the Twilio secrets to production:

```bash
npx supabase secrets set \
  TWILIO_ACCOUNT_SID=AC55a0061f7b574ff96bb37ec19e0f9ed7 \
  TWILIO_AUTH_TOKEN=9f67aae1fc66f2b94b0e2fbb2c0b3a7e \
  TWILIO_PHONE_NUMBER=+61488829851
```

This uploads your Twilio credentials to Supabase's secure environment variables. Without this, the edge functions cannot send SMS.

## What Happens When a User Signs Up

### Step 1: User enters phone number
- User enters: +61412345678 (or any valid international number)
- App calls `twilio-send-otp` edge function

### Step 2: SMS is sent via Twilio
- Edge function generates random 4-digit code (e.g., 3847)
- Twilio sends SMS: "Your Barfliz verification code is: 3847"
- From number: +61488829851
- Code stored temporarily in localStorage

### Step 3: User enters code
- User types the 4-digit code from SMS
- App calls `twilio-verify-otp` edge function
- Function verifies code matches

### Step 4: Account created in database
**This happens automatically via database trigger**

**In `auth.users` table:**
- id: (UUID)
- email: p61412345678@barfliz.phone (auto-generated)
- created_at: timestamp
- encrypted_password: (secure hash)

**In `public.users` table (auto-created by trigger):**
- id: (same UUID)
- phone_number: +61412345678
- phone_country_code: AU
- registration_country: AU
- name: "New User" (default, user updates in onboarding)
- dob: "2000-01-01" (default, user updates in onboarding)
- all other profile fields with sensible defaults

### Step 5: User completes onboarding
- Updates name, birthday, drinks preferences, etc.
- All stored in `public.users` table

## Database Is Queryable

Yes! You can query user data like a real company:

```sql
-- See all users
SELECT id, phone_number, name, created_at FROM public.users;

-- Users by country
SELECT phone_country_code, COUNT(*)
FROM public.users
GROUP BY phone_country_code;

-- Recent signups
SELECT phone_number, name, created_at
FROM public.users
ORDER BY created_at DESC
LIMIT 10;

-- User with specific phone
SELECT * FROM public.users
WHERE phone_number = '+61412345678';
```

## Testing Locally vs Production

**Local Development:**
- Uses `.env` file credentials
- Works on `localhost:5173`

**Production (Netlify/Vercel/etc):**
- Requires secrets to be set via command above
- Edge functions run on Supabase infrastructure
- Frontend calls edge functions via HTTPS

## Current Status

✅ Edge functions deployed
✅ Frontend code integrated
✅ Database trigger active
✅ Test page created
❌ Production secrets NOT set (you must do this)

## After Setting Secrets

1. Test with `test-twilio.html` first
2. Try full sign-up flow
3. Check database to confirm user created
4. Invite beta testers
5. Monitor Twilio dashboard for delivery rates

## Demo Accounts (Bypass SMS)

For instant testing without SMS:
- +61400000001 (code: 0001) - Darwin demo
- +15550000001 (code: 0001) - Florida demo
