/*
  # Create Emergency Numbers Table

  1. New Tables
    - `emergency_numbers`
      - `id` (uuid, primary key)
      - `country` (text, unique) - Country code (AU, US, etc.)
      - `emergency_number` (text) - Emergency phone number for the country
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on `emergency_numbers` table
    - Public read access (data is not sensitive and needed for all users)
    - Admin-only write access (via admin policy)

  3. Initial Data
    - Add emergency numbers for Australia (000) and United States (911)
*/

CREATE TABLE IF NOT EXISTS emergency_numbers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  country text UNIQUE NOT NULL,
  emergency_number text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE emergency_numbers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read emergency numbers"
  ON emergency_numbers FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Admins can insert emergency numbers"
  ON emergency_numbers FOR INSERT
  TO authenticated
  WITH CHECK (false);

CREATE POLICY "Admins can update emergency numbers"
  ON emergency_numbers FOR UPDATE
  TO authenticated
  USING (false)
  WITH CHECK (false);

INSERT INTO emergency_numbers (country, emergency_number)
VALUES
  ('AU', '000'),
  ('US', '911')
ON CONFLICT (country) DO NOTHING;