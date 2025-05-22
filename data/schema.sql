-- data/schema.sql
-- Create teams table
-- Note: created_at changed to BIGINT to store Unix epoch seconds
CREATE TABLE IF NOT EXISTS teams (
    team_id VARCHAR(255) PRIMARY KEY,
    group_activity VARCHAR(255) NOT NULL,
    country_code VARCHAR(3) NOT NULL,
    created_at BIGINT NOT NULL
);

-- Create members table
-- Note: joined_at changed to BIGINT to store Unix epoch seconds
CREATE TABLE IF NOT EXISTS members (
    membership_id VARCHAR(255) PRIMARY KEY,
    group_id VARCHAR(255) NOT NULL,
    role_title VARCHAR(255) NOT NULL,
    joined_at BIGINT NOT NULL,
    FOREIGN KEY (group_id) REFERENCES teams(team_id)
);

-- Create events table
-- Note: event_start, event_end, created_at changed to BIGINT to store Unix epoch seconds
CREATE TABLE IF NOT EXISTS events (
    event_id VARCHAR(255) PRIMARY KEY,
    team_id VARCHAR(255) NOT NULL,
    event_start BIGINT NOT NULL,
    event_end BIGINT NOT NULL,
    created_at BIGINT NOT NULL,
    FOREIGN KEY (team_id) REFERENCES teams(team_id)
);

-- Create event_rsvps table
-- Note: responded_at changed to BIGINT to store Unix epoch seconds
CREATE TABLE IF NOT EXISTS event_rsvps (
    event_rsvp_id VARCHAR(255) PRIMARY KEY,
    event_id VARCHAR(255) NOT NULL,
    member_id VARCHAR(255) NOT NULL,
    rsvp_status INTEGER NOT NULL,
    responded_at BIGINT, -- Can be NULL for unanswered
    FOREIGN KEY (event_id) REFERENCES events(event_id),
    FOREIGN KEY (member_id) REFERENCES members(membership_id)
);