#!/bin/bash

# Script para configurar branch protection rules via GitHub API
# Uso: ./setup-branch-protection.sh OWNER REPO [TOKEN]
# Si no se proporciona TOKEN, se usa la variable de entorno GITHUB_TOKEN

OWNER=$1
REPO=$2
TOKEN=${3:-$GITHUB_TOKEN}

if [ -z "$OWNER" ] || [ -z "$REPO" ] || [ -z "$TOKEN" ]; then
    echo "Error: Faltan parámetros requeridos"
    echo "Uso: ./setup-branch-protection.sh OWNER REPO [TOKEN]"
    echo "     Si no se proporciona TOKEN, se usa la variable de entorno GITHUB_TOKEN"
    echo "Ejemplo: ./setup-branch-protection.sh myorg myrepo"
    exit 1
fi

if [ ${#TOKEN} -lt 20 ]; then
    echo "Error: El token parece inválido (muy corto)"
    exit 1
fi

API_URL="https://api.github.com/repos/$OWNER/$REPO/branches"

echo "Configurando protecciones para $OWNER/$REPO..."

# Protección para dev
echo "Configurando dev..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "$API_URL/dev/protection" \
  -d '{
    "required_status_checks": {
      "strict": true,
      "contexts": ["ci-tests", "build"]
    },
    "enforce_admins": false,
    "required_pull_request_reviews": null,
    "restrictions": null,
    "allow_force_pushes": false,
    "allow_deletions": false
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 204 ]; then
  echo "✓ dev configurado: Solo requiere status checks"
else
  echo "✗ Error al configurar dev (HTTP $HTTP_CODE)"
  echo "$RESPONSE" | head -n-1
  exit 1
fi

# Protección para stg
echo ""
echo "Configurando stg..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "$API_URL/stg/protection" \
  -d '{
    "required_status_checks": {
      "strict": true,
      "contexts": ["ci-tests", "build"]
    },
    "enforce_admins": false,
    "required_pull_request_reviews": {
      "dismiss_stale_reviews": true,
      "require_code_owner_reviews": false,
      "required_approving_review_count": 1
    },
    "restrictions": null,
    "allow_force_pushes": false,
    "allow_deletions": false
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 204 ]; then
  echo "✓ stg configurado: Requiere 1 aprobación"
else
  echo "✗ Error al configurar stg (HTTP $HTTP_CODE)"
  echo "$RESPONSE" | head -n-1
  exit 1
fi

# Protección para main
echo ""
echo "Configurando main..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "$API_URL/main/protection" \
  -d '{
    "required_status_checks": {
      "strict": true,
      "contexts": ["ci-tests", "build", "security-scan"]
    },
    "enforce_admins": true,
    "required_pull_request_reviews": {
      "dismiss_stale_reviews": true,
      "require_code_owner_reviews": true,
      "required_approving_review_count": 2,
      "require_last_push_approval": true
    },
    "restrictions": null,
    "allow_force_pushes": false,
    "allow_deletions": false
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 204 ]; then
  echo "✓ main configurado: Requiere 2 aprobaciones"
  echo ""
  echo "✅ Todas las protecciones configuradas correctamente"
else
  echo "✗ Error al configurar main (HTTP $HTTP_CODE)"
  echo "$RESPONSE" | head -n-1
  exit 1
fi