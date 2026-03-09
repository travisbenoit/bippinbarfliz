/*
  # Add Message Notifications Trigger

  1. Purpose
    - Automatically create notifications when users receive new messages
    - Ensures users are notified in real-time about incoming DMs and swarm messages
  
  2. Changes
    - Create function to generate notifications for new messages
    - Create trigger on messages table that fires after insert
    - Notifications are only sent to recipients, not the sender
  
  3. Notification Types
    - `message_dm`: Direct message received
    - `message_swarm`: Swarm chat message received
*/

-- Function to create message notifications
CREATE OR REPLACE FUNCTION create_message_notification()
RETURNS TRIGGER AS $$
DECLARE
  recipient_id uuid;
  sender_name text;
  notification_title text;
  notification_body text;
BEGIN
  -- Get sender's name
  SELECT name INTO sender_name
  FROM users
  WHERE id = NEW.sender_user_id;

  -- Handle DM notifications
  IF NEW.conversation_type = 'dm' THEN
    -- Determine who the recipient is (the other person in the DM)
    IF NEW.dm_user_a = NEW.sender_user_id THEN
      recipient_id := NEW.dm_user_b;
    ELSE
      recipient_id := NEW.dm_user_a;
    END IF;

    -- Create notification for the recipient
    INSERT INTO notifications (
      recipient_user_id,
      actor_user_id,
      notification_type,
      title,
      body
    ) VALUES (
      recipient_id,
      NEW.sender_user_id,
      'message_dm',
      sender_name || ' sent you a message',
      SUBSTRING(NEW.body, 1, 100)
    );

  -- Handle swarm message notifications
  ELSIF NEW.conversation_type = 'swarm' AND NEW.swarm_id IS NOT NULL THEN
    -- Get all swarm members except the sender
    INSERT INTO notifications (
      recipient_user_id,
      actor_user_id,
      notification_type,
      title,
      body,
      swarm_id
    )
    SELECT 
      sm.user_id,
      NEW.sender_user_id,
      'message_swarm',
      sender_name || ' messaged in swarm',
      SUBSTRING(NEW.body, 1, 100),
      NEW.swarm_id
    FROM swarm_members sm
    WHERE sm.swarm_id = NEW.swarm_id
      AND sm.user_id != NEW.sender_user_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that fires after new messages
DROP TRIGGER IF EXISTS on_message_created ON messages;
CREATE TRIGGER on_message_created
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION create_message_notification();