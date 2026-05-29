CREATE TABLE IF NOT EXISTS tournaments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id UUID REFERENCES clubs(id) ON DELETE SET NULL,
  name VARCHAR(140) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'upcoming',
  teams_count INT NOT NULL DEFAULT 0,
  location TEXT,
  prize NUMERIC(12,2) NOT NULL DEFAULT 0,
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tournaments_club_id ON tournaments(club_id);
