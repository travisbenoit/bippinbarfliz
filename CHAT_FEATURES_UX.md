# Chat Features: Gift & Music Sharing UX Flow

This document describes the user experience flow for sending gifts and music within the chat feature.

## Overview

Users can now send both virtual gifts and songs directly from the chat interface. These appear as rich, interactive cards in the conversation thread.

## User Experience Flow

### Sending a Gift from Chat

1. **User opens a direct message** with a friend
2. **User sees two prominent buttons** at the bottom of the chat:
   - Pink Gift button (left side)
   - Blue/Purple Music button (right side)
3. **User taps the Gift button**
4. **Gift catalog modal opens** displaying:
   - Categories: Quick Reactions, Drinks, Gifts, Stickers, Celebrations
   - Items with emoji, name, price, and rarity badge
   - Filter by category
5. **User selects a virtual item** (e.g., a cocktail, rose, or crown)
6. **Optional message screen** appears:
   - Text input: "Add a message (optional)"
   - Preview of selected gift
7. **User adds a personal message** like "Enjoy your night!"
8. **User taps "Send Gift"**
9. **Gift appears in chat** as a beautiful card showing:
   - Gift emoji and rarity
   - Personal message
   - Sender info
   - Timestamp
10. **Recipient receives** an animated notification
11. **Recipient can react** to the gift with emojis

### Sending Music from Chat

1. **User opens a direct message** with a friend
2. **User taps the Music button** (blue/purple gradient)
3. **Music sharing modal opens** with:
   - Platform selector (Spotify, Apple Music, YouTube Music)
   - Search bar
   - "Send a Song to [Friend Name]" header
4. **User types a song name** (e.g., "Blinding Lights")
5. **Search results appear** showing:
   - Album artwork
   - Song title
   - Artist name
   - Platform badge
6. **User selects a song** from results
7. **Message screen appears**:
   - Selected song preview card
   - Text input: "Why are you sharing this song?"
8. **User adds context** like "This reminds me of last weekend!"
9. **User taps "Send Song"**
10. **Music card appears in chat** showing:
    - Album artwork
    - Song title & artist
    - Platform badge (Spotify green, Apple red, YouTube red)
    - Personal message in highlighted box
    - "Preview" button (if available)
    - "Open" button (opens in music platform)
11. **Recipient can**:
    - Preview the song (30 sec clip if available)
    - Open in their music app
    - Save to their library
12. **Status updates** show "Played" or "Saved" badges

## Visual Design

### Gift Cards in Chat
- Compact card format (max-width for mobile)
- Gradient background matching rarity:
  - Common: Gray
  - Rare: Blue
  - Epic: Purple
  - Legendary: Gold/Orange
- Large emoji display
- Sender avatar in top-left
- Message in light background box
- Timestamp at bottom

### Music Cards in Chat
- Compact card with album art
- Platform-colored header:
  - Spotify: Green gradient
  - Apple Music: Red/Pink gradient
  - YouTube Music: Red gradient
- Album art thumbnail (64x64px)
- Song title (bold) and artist
- Personal message in gray box
- Action buttons:
  - "Listen" (primary, platform-colored)
  - External link icon (secondary)

## Key Features

### Inline Context
- All gifts and songs appear **inline in the conversation**
- Maintains chat flow and context
- Easy to reference in conversation
- Shows timestamp of when sent

### Rich Interactions
- **Gifts**: Can be reacted to with emoji
- **Music**: Can be previewed, opened, or saved
- Both support personal messages for context

### Platform Integration
- Music opens directly in user's preferred platform
- Links are shareable outside the app
- Preview functionality (when available)

### Status Tracking
- Gifts: Sent → Viewed → Reacted
- Music: Sent → Played → Saved
- Visual badges show current status

## Design Considerations

### Mobile-First
- Cards are optimized for mobile screens
- Touch-friendly buttons (44px minimum)
- Swipeable if needed
- Compact but readable

### Accessibility
- Clear button labels
- Sufficient color contrast
- Descriptive aria labels
- Keyboard navigation support

### Performance
- Images lazy-loaded
- Search debounced (500ms)
- Cached Spotify tokens
- Smooth animations

## Future Enhancements

### Potential Additions
- Group music playlists in swarm chats
- Collaborative playlist building
- Music voting in venues
- Gift animations on send/receive
- Gift inventory and collection
- Music taste matching
- Song recommendations based on shared music
- "Now Playing" status integration
