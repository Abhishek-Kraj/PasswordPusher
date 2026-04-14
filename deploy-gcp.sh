#!/bin/bash
set -euo pipefail

# ============================================================
# PasswordPusher — GCP Cloud Run Deployment Script
# Project: alshaya-titan | Region: europe-west1
# Estimated cost: ~$12-15/month
# ============================================================

PROJECT_ID="alshaya-titan"
REGION="europe-west1"
SERVICE_NAME="pwpush-alshaya"
DB_INSTANCE="pwpush-db"
DB_NAME="pwpush_production"
DB_USER="pwpush"
IMAGE="docker.io/pglombardo/pwpush:latest"

echo "=== Step 1: Set project ==="
gcloud config set project ${PROJECT_ID}

echo "=== Step 2: Enable required APIs ==="
gcloud services enable \
  run.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  vpcaccess.googleapis.com \
  --project=${PROJECT_ID}

echo "=== Step 3: Generate secrets ==="
SECRET_KEY_BASE=$(openssl rand -hex 64)
PWPUSH_MASTER_KEY=$(openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=' | head -c 32)

echo "=== Step 4: Store secrets in Secret Manager ==="
printf "%s" "${SECRET_KEY_BASE}" | \
  gcloud secrets create pwpush-secret-key-base \
    --data-file=- \
    --project=${PROJECT_ID} \
    --replication-policy=automatic 2>/dev/null || \
  echo "Secret pwpush-secret-key-base already exists, skipping"

printf "%s" "${PWPUSH_MASTER_KEY}" | \
  gcloud secrets create pwpush-master-key \
    --data-file=- \
    --project=${PROJECT_ID} \
    --replication-policy=automatic 2>/dev/null || \
  echo "Secret pwpush-master-key already exists, skipping"

printf "%s" "${DB_PASSWORD}" | \
  gcloud secrets create pwpush-db-password \
    --data-file=- \
    --project=${PROJECT_ID} \
    --replication-policy=automatic 2>/dev/null || \
  echo "Secret pwpush-db-password already exists, skipping"

echo "=== Step 5: Create Cloud SQL PostgreSQL instance ==="
echo "This takes 5-10 minutes..."
gcloud sql instances create ${DB_INSTANCE} \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --storage-size=10GB \
  --storage-auto-increase \
  --availability-type=zonal \
  --edition=enterprise \
  2>/dev/null || echo "Instance ${DB_INSTANCE} already exists, skipping"

echo "=== Step 6: Create database and user ==="
gcloud sql databases create ${DB_NAME} \
  --instance=${DB_INSTANCE} \
  --project=${PROJECT_ID} \
  2>/dev/null || echo "Database ${DB_NAME} already exists, skipping"

gcloud sql users create ${DB_USER} \
  --instance=${DB_INSTANCE} \
  --password="${DB_PASSWORD}" \
  --project=${PROJECT_ID} \
  2>/dev/null || echo "User ${DB_USER} already exists, skipping"

echo "=== Step 7: Get Cloud SQL connection name ==="
CONNECTION_NAME=$(gcloud sql instances describe ${DB_INSTANCE} \
  --project=${PROJECT_ID} \
  --format='value(connectionName)')
echo "Connection name: ${CONNECTION_NAME}"

echo "=== Step 8: Get project number for IAM ==="
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')

echo "=== Step 9: Grant Secret Manager access to Cloud Run service account ==="
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --condition=None \
  --quiet 2>/dev/null || true

echo "=== Step 10: Grant Cloud SQL Client access ==="
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/cloudsql.client" \
  --condition=None \
  --quiet 2>/dev/null || true

echo "=== Step 11: Build DATABASE_URL ==="
# Cloud Run uses Cloud SQL Proxy via Unix socket
DATABASE_URL="postgres://${DB_USER}:${DB_PASSWORD}@//cloudsql/${CONNECTION_NAME}/${DB_NAME}"
echo "DATABASE_URL configured (using Cloud SQL proxy socket)"

echo "=== Step 12: Deploy to Cloud Run ==="
gcloud run deploy ${SERVICE_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --image=${IMAGE} \
  --platform=managed \
  --port=5100 \
  --memory=512Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=2 \
  --timeout=300 \
  --allow-unauthenticated \
  --add-cloudsql-instances=${CONNECTION_NAME} \
  --set-env-vars="DATABASE_URL=${DATABASE_URL}" \
  --set-env-vars="RAILS_ENV=production" \
  --set-env-vars="PWP__ALLOW_ANONYMOUS=false" \
  --set-env-vars="PWP__DISABLE_SIGNUPS=false" \
  --set-env-vars="PWP__DISABLE_LOGINS=false" \
  --set-env-vars="PWP__ENABLE_URL_PUSHES=true" \
  --set-env-vars="PWP__ENABLE_FILE_PUSHES=true" \
  --set-env-vars="PWP__ENABLE_QR_PUSHES=true" \
  --set-env-vars="PWP__HOST_PROTOCOL=https" \
  --set-env-vars="PWP__SECURE_COOKIES=true" \
  --set-env-vars="PWP__BRAND__TITLE=Alshaya Password Pusher" \
  --set-env-vars="PWP__BRAND__TAGLINE=Securely share passwords and sensitive data" \
  --set-env-vars="PWP__TIMEZONE=Asia/Kuwait" \
  --set-env-vars="PWP__LOG_LEVEL=info" \
  --set-env-vars="PWP__LOG_TO_STDOUT=true" \
  --set-env-vars="PWP__FILES__STORAGE=local" \
  --set-env-vars="PWP__PW__EXPIRE_AFTER_DAYS_DEFAULT=7" \
  --set-env-vars="PWP__PW__EXPIRE_AFTER_VIEWS_DEFAULT=5" \
  --set-env-vars="PWP__PW__ENABLE_RETRIEVAL_STEP=true" \
  --set-env-vars="PWP__PW__RETRIEVAL_STEP_DEFAULT=true" \
  --set-env-vars="PWP__PW__ENABLE_DELETABLE_PUSHES=true" \
  --set-env-vars="HTTP_PORT=8080" \
  --set-env-vars="HTTPS_PORT=8443" \
  --set-secrets="SECRET_KEY_BASE=pwpush-secret-key-base:latest" \
  --set-secrets="PWPUSH_MASTER_KEY=pwpush-master-key:latest"

echo "=== Step 13: Get service URL ==="
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --format='value(status.url)')

echo ""
echo "============================================"
echo "  Deployment complete!"
echo "============================================"
echo "  URL: ${SERVICE_URL}"
echo "  DB:  ${CONNECTION_NAME}"
echo ""
echo "  Next steps:"
echo "  1. Open ${SERVICE_URL} and verify it loads"
echo "  2. Create an admin account at ${SERVICE_URL}/users/sign_up"
echo "  3. Set PWP__HOST_DOMAIN to your custom domain if needed"
echo ""
echo "  Monthly cost estimate:"
echo "    Cloud SQL db-f1-micro:  ~\$7.67"
echo "    Cloud Run (low traffic): ~\$2-5"
echo "    Secret Manager:          ~\$0.06"
echo "    Total:                   ~\$10-13/month"
echo "============================================"

# Save deployment info locally
cat > /Users/abhishek/alshaya-work/PasswordPusher/.deployment-info <<DEPLOY_EOF
PROJECT_ID=${PROJECT_ID}
REGION=${REGION}
SERVICE_NAME=${SERVICE_NAME}
SERVICE_URL=${SERVICE_URL}
DB_INSTANCE=${DB_INSTANCE}
DB_NAME=${DB_NAME}
CONNECTION_NAME=${CONNECTION_NAME}
DEPLOYED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DEPLOY_EOF

echo "Deployment info saved to .deployment-info"
