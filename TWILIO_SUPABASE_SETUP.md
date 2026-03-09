# Twilio SMS Setup for Global Phone Authentication

This guide will help you configure Twilio with Supabase to enable phone authentication globally.

## Prerequisites

- A Supabase project (you already have this)
- A Twilio account (free trial works for testing)

## Step 1: Create Twilio Account

1. Go to [https://www.twilio.com/try-twilio](https://www.twilio.com/try-twilio)
2. Sign up for a free account
3. Verify your email and phone number
4. You'll get **free trial credits** ($15-20 USD) to test with

## Step 2: Get Your Twilio Credentials

1. Go to your [Twilio Console Dashboard](https://console.twilio.com/)
2. Find and copy these values:
   - **Account SID** (starts with `AC...`)
   - **Auth Token** (click to reveal)

## Step 3: Get a Twilio Phone Number

1. In Twilio Console, go to **Phone Numbers** → **Manage** → **Buy a number**
2. Select your country (or use a US number for global SMS)
3. Make sure the number has **SMS capabilities** checked
4. Purchase/claim the number (free on trial)
5. Copy your **Twilio Phone Number** (e.g., `+1234567890`)

## Step 4: Configure Supabase

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Authentication** → **Providers**
4. Scroll down and enable **Phone**
5. Under **Phone provider settings**, select **Twilio**
6. Enter your credentials:
   - **Twilio Account SID**: (paste from Step 2)
   - **Twilio Auth Token**: (paste from Step 2)
   - **Twilio Message Service SID**: (optional, leave blank for now)
7. Click **Save**

## Step 5: Configure Phone Settings (Important!)

1. Still in **Authentication** → **Providers** → **Phone**
2. Configure these settings:
   - **Confirm phone**: Enable this to require OTP verification
   - **OTP expiry duration**: 60 seconds (default is fine)
   - **OTP length**: 6 digits (default)
3. Click **Save**

## Step 6: Test It!

1. Open your Barfliz app
2. Click "Sign Up"
3. Enter a **real phone number** (including country code)
4. You should receive an SMS with a 6-digit code
5. Enter the code to verify

## Twilio Trial Limitations

During the free trial:
- ✅ Works globally (sends SMS to any country)
- ✅ Free $15-20 in credits
- ⚠️ Can only send to **verified phone numbers**
- ⚠️ SMS includes "Sent from your Twilio trial account" message

### Adding Verified Numbers (Trial Only)

1. Go to Twilio Console → **Phone Numbers** → **Manage** → **Verified Caller IDs**
2. Click **Add a new number**
3. Enter the phone number you want to test with
4. Twilio will call or SMS you to verify
5. Now you can send OTP codes to this number

## Going to Production

When ready for production:

1. **Upgrade your Twilio account** (add payment method)
   - No more "trial account" message in SMS
   - Can send to any phone number without verification
   - Pay-as-you-go pricing (~$0.0075 per SMS)

2. **Optional: Get a Messaging Service SID**
   - Better for high volume
   - Supports multiple phone numbers
   - Better deliverability

## Pricing Reference

Twilio SMS pricing (approximate):
- **US/Canada**: $0.0075 per SMS
- **UK**: $0.04 per SMS
- **Australia**: $0.08 per SMS
- **Most countries**: $0.02-0.15 per SMS

Check current pricing: [https://www.twilio.com/sms/pricing](https://www.twilio.com/sms/pricing)

## Troubleshooting

### "Unable to create record" error
- Make sure Phone provider is enabled in Supabase
- Verify your Twilio credentials are correct
- Check that your Twilio account is active

### Not receiving SMS
- Verify the phone number format includes country code (e.g., `+1` for US)
- On trial account, make sure the number is verified in Twilio
- Check Twilio Console → Monitor → Logs → Messaging for delivery status

### "Invalid phone number" error
- Ensure you're using E.164 format: `+[country code][number]`
- Example: `+1234567890` (US), `+61412345678` (AU), `+447700900000` (UK)

### SMS not arriving (even though Twilio shows sent)
- Some carriers block short codes or automated messages
- Try a different phone number
- Check spam/blocked messages on your phone

## Alternative Providers

If Twilio doesn't work well in your region, Supabase also supports:

1. **MessageBird** - Good for Europe/Asia
2. **Vonage** - Global coverage
3. **Textlocal** - Good for India/UK

Configuration is similar - just select a different provider in Supabase settings.

## Support

- **Twilio Support**: [https://support.twilio.com](https://support.twilio.com)
- **Supabase Docs**: [https://supabase.com/docs/guides/auth/phone-login](https://supabase.com/docs/guides/auth/phone-login)

---

**You're all set!** Once configured, phone authentication will work globally for all users. 🌍
