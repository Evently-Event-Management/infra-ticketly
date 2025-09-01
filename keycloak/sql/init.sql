-- Connect to your RDS instance and create the keycloak schema
CREATE SCHEMA keycloak;
-- Grant permissions to your RDS user
GRANT ALL PRIVILEGES ON SCHEMA keycloak TO ticketly;