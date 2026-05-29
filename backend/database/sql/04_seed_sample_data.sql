INSERT INTO users (full_name, email, phone, password_hash)
VALUES
('Ahmed Hassan', 'ahmed@shido.app', '+252611111111', 'hash1'),
('Mohamed Ali', 'mohamed@shido.app', '+252622222222', 'hash2')
ON CONFLICT (email) DO NOTHING;

INSERT INTO clubs (name, location)
VALUES
('City Star Club', 'Mogadishu'),
('Golden Players Club', 'Hargeisa'),
('Royal Shido Club', 'Bosaso')
ON CONFLICT DO NOTHING;

INSERT INTO players (full_name, nickname, club_id)
SELECT 'Ahmed Hassan', 'Hammer', c.id FROM clubs c WHERE c.name='City Star Club'
ON CONFLICT DO NOTHING;
INSERT INTO players (full_name, nickname, club_id)
SELECT 'Mohamed Ali', 'Ace', c.id FROM clubs c WHERE c.name='City Star Club'
ON CONFLICT DO NOTHING;
INSERT INTO players (full_name, nickname, club_id)
SELECT 'Omar Faruk', 'Storm', c.id FROM clubs c WHERE c.name='Golden Players Club'
ON CONFLICT DO NOTHING;

INSERT INTO games (club_id, status, winning_score)
SELECT c.id, 'active', 101 FROM clubs c WHERE c.name='City Star Club'
ON CONFLICT DO NOTHING;
INSERT INTO games (club_id, status, winning_score)
SELECT c.id, 'finished', 101 FROM clubs c WHERE c.name='Golden Players Club'
ON CONFLICT DO NOTHING;

INSERT INTO reports (report_type, format, payload)
VALUES
('daily', 'pdf', '{"title":"Daily Report"}'),
('weekly', 'csv', '{"title":"Weekly Report"}')
ON CONFLICT DO NOTHING;

INSERT INTO notifications (title, message, type)
VALUES
('Game Finished', 'Game #124 has been finished.', 'game'),
('Round Added', 'Round 3 added in latest game.', 'round'),
('Payment Received', 'Payment received from City Star Club.', 'payment')
ON CONFLICT DO NOTHING;

INSERT INTO payments (amount, method, status, reference_no)
VALUES
(100, 'cash', 'paid', 'PAY-1001'),
(150, 'zaad', 'pending', 'PAY-1002')
ON CONFLICT DO NOTHING;

INSERT INTO app_settings (setting_key, setting_value, description)
VALUES
('language', 'English', 'Default app language'),
('notifications_enabled', 'true', 'Allow push notifications'),
('privacy_mode', 'standard', 'Privacy level')
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO tournaments (name, status, teams_count, location, prize, start_date, end_date)
VALUES
('City Star Tournament', 'upcoming', 32, 'Mogadishu', 2000, CURRENT_DATE + 5, CURRENT_DATE + 10),
('Golden Cup 2024', 'upcoming', 16, 'Hargeisa', 1200, CURRENT_DATE + 12, CURRENT_DATE + 14),
('Royal Shido League', 'upcoming', 24, 'Bosaso', 1500, CURRENT_DATE + 20, CURRENT_DATE + 26)
ON CONFLICT DO NOTHING;
