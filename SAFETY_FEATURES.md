# Safety & Security Features

## Overview
Barfliz includes comprehensive safety features to help users stay safe during their nightlife experiences.

## How to Access
1. Open the app
2. Navigate to **Settings** (bottom navigation)
3. Tap on **Safety & Security** under the Support section

---

## Features

### 1. Emergency 911 Call
**What it does:** Quick access to emergency services

**How it works:**
- Large, prominent red button at the top of the Safety & Security screen
- Tap "Call 911" button
- Confirmation dialog appears to prevent accidental calls
- Tapping "Yes, Call 911" immediately dials emergency services
- Can cancel if pressed accidentally

**Visual Design:**
- Red gradient card with white phone icon
- Large "Call 911" button in white with red text
- Clear warning messaging

---

### 2. Safety Friends
**What it does:** Manage a list of trusted contacts who can receive your location in emergencies

**How it works:**
- Add trusted contacts with name and phone number
- Store multiple safety friends
- View all your safety contacts in one place
- Remove contacts when needed

**Adding a Safety Friend:**
1. Tap the "+" button in the Safety Friends section
2. Enter friend's name
3. Enter friend's phone number (formatted as (555) 123-4567)
4. Tap "Add Friend"
5. Friend is added to your safety contacts list

**Managing Safety Friends:**
- Each contact shows their initial, name, and formatted phone number
- Tap the trash icon to remove a contact
- All data is stored securely in your personal database

---

### 3. Share My Location
**What it does:** Send your current GPS location to all safety friends instantly

**How it works:**
1. Ensure you have at least one safety friend added
2. Tap "Share My Location" button
3. App requests your current GPS location
4. Creates a Google Maps link with your coordinates
5. Records the location share in the database with:
   - Latitude & Longitude
   - Google Maps URL
   - Timestamp
   - Alert type (location_share)

**Use Cases:**
- Going to a new venue alone
- Meeting someone for the first time
- Staying out late
- Any situation where friends should know your whereabouts

**Visual Design:**
- Blue location pin icon
- Clear description
- Loading spinner while sharing
- Success confirmation when complete

---

## Safety Alert Log
All location shares are logged in the `safety_alerts` table with:
- User ID
- GPS coordinates (latitude/longitude)
- Google Maps link for easy viewing
- Alert type
- Timestamp

This creates an audit trail of when and where you shared your location.

---

## Security Features

### Database Security
- **Row Level Security (RLS)** enabled on all safety tables
- Users can only access their own safety friends and alerts
- No user can view another user's safety information
- Secure authentication required for all operations

### Privacy
- Location data is only shared when you explicitly tap "Share My Location"
- No background location tracking
- Safety friends are stored privately
- Only you can see and manage your safety contacts

---

## Technical Implementation

### Database Tables

**safety_friends**
```sql
- id (uuid, primary key)
- user_id (uuid, references auth.users)
- friend_name (text)
- friend_phone (text)
- created_at (timestamp)
```

**safety_alerts**
```sql
- id (uuid, primary key)
- user_id (uuid, references auth.users)
- latitude (numeric)
- longitude (numeric)
- location_url (text)
- alert_type (text)
- created_at (timestamp)
```

### Security Policies
- Users can only SELECT their own records
- Users can only INSERT their own records
- Users can only UPDATE their own records
- Users can only DELETE their own records
- All policies verify `auth.uid() = user_id`

---

## Best Practices

1. **Add Multiple Safety Friends** - Have 2-3 trusted contacts
2. **Keep Contacts Updated** - Remove old numbers, add current ones
3. **Share Your Location** - When going somewhere new or meeting strangers
4. **Use the 911 Feature** - Only for real emergencies
5. **Tell Friends** - Let your safety friends know they're on your list

---

## UI/UX Highlights

- **Prominent Emergency Button** - Red gradient design for visibility
- **Clear Visual Hierarchy** - Emergency call at top, safety friends below
- **Easy Management** - Simple add/remove interface
- **Safety Tips** - Amber warning box with safety reminders
- **Confirmation Dialogs** - Prevents accidental emergency calls
- **Loading States** - Shows progress when sharing location
- **Success Feedback** - Alerts confirm when location is shared

---

## Future Enhancement Ideas

- SMS notifications to safety friends when location is shared
- Automatic location sharing at scheduled times
- Geofencing alerts (notify friends when you leave an area)
- Emergency broadcast to all safety friends at once
- Video/audio recording feature
- Check-in timer (alerts friends if you don't check in)
- Integration with ride-sharing apps
- Safe word feature in messages
