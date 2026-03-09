# Recommendations for Tomorrow

## High Priority

1. **Code Splitting & Performance**
   - Bundle size is large (~1.7MB). Lazy load heavy components:
     - Music player features
     - Payment/Venmo flows
     - Geofencing debug tools
   - Use React.lazy() and Suspense to defer non-critical features

2. **Real-Time Subscriptions**
   - Verify Supabase subscriptions are working for:
     - Friend location updates
     - Venue crowd counts
     - Message notifications
   - Check for memory leaks in subscription cleanup

3. **Error Handling & UX**
   - Add error boundaries around geofencing and Radar integration
   - Better messaging for:
     - Location permission denials
     - Failed weather API calls
     - Spotify search failures
     - Offline scenarios
   - Consider toast notifications for errors

## Medium Priority

4. **Mobile Responsiveness**
   - Verify all modals work properly on small screens
   - Test bottom navigation on iPhone notch/dynamic island
   - Check map view on mobile devices

5. **Feature Polish**
   - Geofence trigger timing (test actual venue entries/exits)
   - Music sharing reliability
   - Payment flow edge cases
   - Virtual items/gifts purchase flow

6. **Database Optimization**
   - Add indexes to frequently queried columns (user_id, venue_id, location)
   - Review RLS policies for performance
   - Check migration queries for N+1 patterns

## Low Priority

7. **Flutter App Alignment**
   - Keep feature parity between web and Flutter versions
   - Sync UI patterns where possible

8. **Testing**
   - Add tests for critical flows (auth, payments, location)
   - Integration tests for geofencing triggers

---

**Focus order:** Start with #1-3, then tackle #4-5 if time allows.
