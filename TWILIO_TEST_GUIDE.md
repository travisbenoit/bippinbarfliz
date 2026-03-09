# Twilio SMS Integration - Test Guide

## Status: ✅ Ready to Test

Your Twilio integration is configured and deployed. The system sends real SMS messages via Twilio.

## What's Configured

- **Account SID**: AC55a0061f7b574ff96bb37ec19e0f9ed7
- **Phone Number**: +61488829851 (Australian number)
- **OTP Format**: 4-digit codes
- **Platform**: Web (mobile coming soon)

## How It Works

1. **Send OTP**: User enters phone number → System sends 4-digit code via SMS through Twilio
2. **Verify OTP**: User enters code → System validates and creates/logs in account

## Testing Options

### Option 1: Test Page (Quick Test)
Open `test-twilio.html` in your browser to test the Twilio functions directly:
1. Enter a phone number (with country code, e.g., +61412345678)
2. Click "Send Verification Code"
3. Check your phone for the SMS
4. The code also displays on screen for testing
5. Enter the code and verify

### Option 2: Full App Flow
Test through the actual sign-up flow:
1. Start your dev server: `npm run dev`
2. Navigate to sign-up
3. Enter a phone number
4. Receive SMS with 4-digit code
5. Enter code to complete verification

## Important Notes

### For Production Deployment
The environment variables in `.env` are for local development only. For production, you need to manually set the Twilio secrets in Supabase by running:

```bash
npx supabase secrets set \
  TWILIO_ACCOUNT_SID=AC55a0061f7b574ff96bb37ec19e0f9ed7 \
  TWILIO_AUTH_TOKEN=9f67aae1fc66f2b94b0e2fbb2c0b3a7e \
  TWILIO_PHONE_NUMBER=+61488829851
```

### Phone Number Format
Always include the country code:
- Australia: +61412345678
- USA: +14155551234
- etc.

### SMS Delivery
- Messages should arrive within seconds
- Check spam/blocked messages if not received
- Verify the phone number format is correct

## Edge Functions

Two functions are deployed:
- `twilio-send-otp`: Generates and sends 4-digit OTP via SMS
- `twilio-verify-otp`: Validates the OTP code

## Troubleshooting

If SMS isn't received:
1. Verify phone number format includes country code
2. Check Twilio dashboard for delivery status
3. Ensure the phone can receive SMS
4. Try test page to see specific error messages

## Demo Accounts (No SMS Required)

For testing without SMS:
- **Darwin Demo**: +61400000001 (code: 0001)
- **Florida Demo**: +15550000001 (code: 0001)

These bypass Twilio and work instantly.
