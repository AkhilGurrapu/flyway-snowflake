#!/usr/bin/env bash

# This script executes Flyway commands for database migration
# Parameters:
# 1=DB_URL - Snowflake JDBC URL
# 2=DEPLOY_USERNAME - Snowflake username
# 3=SFPASS - Snowflake password
# 4=DEPLOY_DATABASE - Target database
# 5=DEPLOY_WAREHOUSE - Snowflake warehouse
# 6=FLYWAY_TASK - Flyway command (info/migrate)
# 7=BASELINE - Whether to baseline the database

# Display Flyway version
echo "Flyway Version"
flyway -v
echo "Starting FlyWay Deployment"

# Validate required parameters
if [ -z "${1}" ] || [ -z "${2}" ] || [ -z "${3}" ] || [ -z "${4}" ]; then
    echo "Error: Required parameters missing"
    exit 1
fi

# Set Flyway environment variables
export FLYWAY_URL="${1}"
export FLYWAY_USER="${2}"
export FLYWAY_PASSWORD="${3}"

# Required for Snowflake JDBC driver compatibility
export JAVA_ARGS=-"-add-opens java.base/java.nio=ALL-UNNAMED"

# Set Flyway schema for tracking migrations
export FLYWAY_DEFAULT_SCHEMA=FLYWAY

echo "Running Flyway migration"

# Execute Flyway commands
# First repair any inconsistencies in the schema history
flyway repair -locations="databases/${4}"

# Execute the main Flyway command (info or migrate)
flyway -X -locations="databases/${4^^}" -baselineOnMigrate=${7} ${6} -outOfOrder=true

# Check execution status
if [ $? -eq 0 ]; then
    echo "Flyway migration completed successfully"
    exit 0
else
    echo "Error: Flyway Migration failed. See above for details."
    exit 1
fi