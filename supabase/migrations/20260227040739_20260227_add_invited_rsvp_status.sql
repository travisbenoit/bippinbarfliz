/*
  # Add 'invited' RSVP Status to Swarm Members

  1. Changes
    - Drop existing RSVP check constraint on swarm_members table
    - Add new constraint that includes 'invited' as a valid RSVP status
    - This allows swarm hosts to invite friends who haven't responded yet
  
  2. Valid RSVP Statuses
    - 'invited': User has been invited but hasn't responded
    - 'going': User confirmed attendance
    - 'maybe': User might attend
    - 'not_going': User declined
*/

-- Drop the old constraint
ALTER TABLE swarm_members 
DROP CONSTRAINT IF EXISTS swarm_members_rsvp_check;

-- Add new constraint with 'invited' option
ALTER TABLE swarm_members 
ADD CONSTRAINT swarm_members_rsvp_check 
CHECK (rsvp = ANY (ARRAY['invited'::text, 'going'::text, 'maybe'::text, 'not_going'::text]));