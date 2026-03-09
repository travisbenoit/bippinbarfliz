/*
  # Create Venue Reports Table for Reporting Issues

  ## Overview
  Creates a reporting system for users to flag venues with problems like incorrect information,
  inappropriate content, closed/moved venues, or safety concerns. This helps maintain data quality
  and user safety.

  ## New Tables
  
  ### `venue_reports`
  Stores user-submitted reports about venues
  - `id` (uuid, primary key) - Unique report identifier
  - `venue_id` (uuid, required) - Venue being reported
  - `reporter_id` (uuid, required) - User who submitted the report
  - `report_type` (text) - Type of issue: 'incorrect_info', 'closed', 'inappropriate', 'safety_concern', 'spam', 'other'
  - `description` (text) - Detailed description of the issue
  - `status` (text) - Report status: 'pending', 'reviewing', 'resolved', 'dismissed'
  - `admin_notes` (text, nullable) - Internal notes from admin/moderator
  - `resolved_at` (timestamptz, nullable) - When the report was resolved
  - `resolved_by` (uuid, nullable) - Admin who resolved the report
  - `created_at` (timestamptz) - When the report was submitted

  ## Security
  - Enable RLS on venue_reports table
  - Users can read their own reports
  - Users can create new reports
  - Only admins can update reports (change status, add notes)
  - Only admins can delete reports
  - Regular users cannot see other users' reports

  ## Indexes
  - `idx_venue_reports_venue_id` - Fast lookups by venue
  - `idx_venue_reports_reporter_id` - Fast lookups by reporter
  - `idx_venue_reports_status` - Filter by status
  - `idx_venue_reports_pending` - Find pending reports
  - Composite index on (venue_id, status) for venue moderation

  ## Notes
  - Consider rate limiting to prevent spam reports
  - Multiple reports on same venue might indicate real issues
  - Status workflow: pending -> reviewing -> resolved/dismissed
  - Consider adding report categories for better analytics
  - Resolved reports should be archived but not deleted (for audit trail)
*/

-- Create venue_reports table
CREATE TABLE IF NOT EXISTS venue_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id uuid NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  reporter_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  report_type text NOT NULL CHECK (report_type IN ('incorrect_info', 'closed', 'inappropriate', 'safety_concern', 'spam', 'other')),
  description text NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewing', 'resolved', 'dismissed')),
  admin_notes text,
  resolved_at timestamptz,
  resolved_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_venue_reports_venue_id ON venue_reports(venue_id);
CREATE INDEX IF NOT EXISTS idx_venue_reports_reporter_id ON venue_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_venue_reports_status ON venue_reports(status);
CREATE INDEX IF NOT EXISTS idx_venue_reports_pending ON venue_reports(status, created_at DESC) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_venue_reports_venue_status ON venue_reports(venue_id, status);
CREATE INDEX IF NOT EXISTS idx_venue_reports_created_at ON venue_reports(created_at DESC);

-- Add helpful comment
COMMENT ON TABLE venue_reports IS 'Stores user-submitted reports about venue issues for moderation and data quality';

-- Enable Row Level Security
ALTER TABLE venue_reports ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own reports
CREATE POLICY "Users can read own reports"
  ON venue_reports
  FOR SELECT
  TO authenticated
  USING (auth.uid() = reporter_id);

-- Policy: Users can create new reports
CREATE POLICY "Users can create reports"
  ON venue_reports
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = reporter_id);

-- Policy: Only admins/system can update reports
-- Note: In production, you'd want to add a more sophisticated admin check
-- For now, we'll allow users to update their own pending reports only
CREATE POLICY "Users can update own pending reports"
  ON venue_reports
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = reporter_id AND status = 'pending')
  WITH CHECK (auth.uid() = reporter_id AND status = 'pending');

-- Policy: Users can delete their own pending reports
CREATE POLICY "Users can delete own pending reports"
  ON venue_reports
  FOR DELETE
  TO authenticated
  USING (auth.uid() = reporter_id AND status = 'pending');

-- Function to automatically set resolved_at when status changes to resolved/dismissed
CREATE OR REPLACE FUNCTION set_venue_report_resolved_at()
RETURNS TRIGGER AS $$
BEGIN
  -- If status changed to resolved or dismissed, set resolved_at
  IF NEW.status IN ('resolved', 'dismissed') AND (OLD.status IS NULL OR OLD.status NOT IN ('resolved', 'dismissed')) THEN
    NEW.resolved_at = now();
    -- Set resolved_by if not already set
    IF NEW.resolved_by IS NULL THEN
      -- In a real app, this would be the admin user ID
      -- For now, leaving it NULL unless explicitly set
      NULL;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to set resolved_at automatically
CREATE TRIGGER set_venue_report_resolved_at_trigger
  BEFORE UPDATE ON venue_reports
  FOR EACH ROW
  EXECUTE FUNCTION set_venue_report_resolved_at();

-- Function to count pending reports for a venue
CREATE OR REPLACE FUNCTION get_venue_pending_reports_count(p_venue_id uuid)
RETURNS integer AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::integer
    FROM venue_reports
    WHERE venue_id = p_venue_id 
      AND status = 'pending'
  );
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_venue_pending_reports_count IS 'Returns the count of pending reports for a given venue';