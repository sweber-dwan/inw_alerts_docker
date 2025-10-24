#!/bin/bash
# Script to check Docker volume information

echo "================================================"
echo "Docker Volume Information"
echo "================================================"
echo ""

# List all volumes
echo "📦 All Docker Volumes:"
docker volume ls

echo ""
echo "================================================"
echo "GDELT Postgres Volume Details:"
echo "================================================"
docker volume inspect inw_alerts_docker_postgres_data

echo ""
echo "================================================"
echo "Volume Size:"
echo "================================================"
docker system df -v | grep postgres_data

echo ""
echo "================================================"
echo "Database Size Inside Container:"
echo "================================================"
docker exec gdelt_postgres du -sh /var/lib/postgresql/data

echo ""
echo "================================================"
echo "Database Tables:"
echo "================================================"
docker exec gdelt_postgres psql -U gdelt_user -d gdelt_db -c "\dt"

echo ""
echo "================================================"
echo "Row Counts:"
echo "================================================"
docker exec gdelt_postgres psql -U gdelt_user -d gdelt_db -c "SELECT COUNT(*) as total_events FROM gdelt_events;"

