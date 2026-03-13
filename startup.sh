#!/bin/bash

set -e

echo "Starting Nepal Voting App..."

# Navigate to the app directory (Oryx extracts to /tmp/xxx and sets app path)
# The ORYX_APP_PATH or default to current working directory
APP_PATH="${ORYX_APP_PATH:-.}"

cd "$APP_PATH"

# If in Oryx temp directory, look for nepal_voting subdirectory
if [ ! -f "manage.py" ] && [ -d "nepal_voting" ]; then
    cd nepal_voting
    echo "Found nepal_voting subdirectory, switched to it"
fi

echo "Current directory: $(pwd)"
echo "Contents: $(ls -la)"

# Install/upgrade packages
echo "Installing requirements..."
pip install --upgrade pip
pip install -r requirements.txt

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput || true

# Run migrations
echo "Running migrations..."
python manage.py migrate --noinput || true

# Start gunicorn
echo "Starting gunicorn on port 8000..."
exec gunicorn \
  --workers 3 \
  --worker-class sync \
  --bind 0.0.0.0:8000 \
  --timeout 120 \
  --access-logfile - \
  --error-logfile - \
  nepal_voting.wsgi:application
