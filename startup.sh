#!/bin/bash

# Enable debug output
set -x
set -e

echo "=========================================="
echo "STARTING NEPAL VOTING DEPLOYMENT"
echo "=========================================="

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "[LOG] Working Directory: $PWD"
echo "[LOG] Python Version: $(python --version 2>&1)"
echo "[LOG] Pip Version: $(pip --version 2>&1)"
echo "[LOG] User: $(whoami)"

# Check if files exist
echo "[CHECK] Looking for manage.py..."
if [ -f manage.py ]; then
    echo "[OK] manage.py found"
else
    echo "[ERROR] manage.py NOT found!"
    ls -la
    exit 1
fi

echo "[CHECK] Looking for requirements.txt..."
if [ -f requirements.txt ]; then
    echo "[OK] requirements.txt found"
else
    echo "[WARN] requirements.txt NOT found - will try to continue"
fi

# Install dependencies
echo "[STEP] Installing dependencies..."
pip install --upgrade pip 2>&1 || echo "[WARN] pip upgrade failed"
pip install -r requirements.txt 2>&1 || echo "[WARN] requirements install had issues"

# Try to import Django
echo "[CHECK] Testing Django import..."
python -c "import django; print('Django version:', django.VERSION)" || exit 1

# Run migrations (don't fail if this errors)
echo "[STEP] Running migrations..."
python manage.py migrate --noinput 2>&1 || echo "[WARN] Migrations completed with warnings"

# Collect static (don't fail if this errors)
echo "[STEP] Collecting static files..."
python manage.py collectstatic --noinput 2>&1 || echo "[WARN] Static collection had issues"

echo "=========================================="
echo "STARTING GUNICORN SERVER"
echo "=========================================="

# Start gunicorn with maximum debug output
exec python -m gunicorn \
  --workers 1 \
  --worker-class sync \
  --bind 0.0.0.0:8000 \
  --timeout 120 \
  --access-logfile - \
  --error-logfile - \
  --log-level debug \
  nepal_voting.wsgi:application
