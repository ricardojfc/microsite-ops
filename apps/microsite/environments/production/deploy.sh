#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Deployment script for isolated environments (production)
# Usage: ./deploy.sh
# -----------------------------------------------------------------------------
set -euo pipefail

# Some color configuration
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check we are in the right path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}============ DEPLOY CONTROL - MICROSITE PROD ============${NC}\n"

# 1. Sync with local repo
echo -e "${YELLOW}[1/4] Downloading changes approved by the CAB from GitHub...${NC}"
# Trying to update Ops local repo
if git fetch origin main && git checkout main && git pull origin main; then
    echo -e "${GREEN}✓ Ops repository updated from the main branch.${NC}"
else
    echo -e "${RED}✗ Error updating from GitHub. Please check GitHub conectivity.${NC}"
    exit 1
fi

# 2. Cluster security control (Kubernetes context)
echo -e "\n${YELLOW}[2/4] Checking target cluster...${NC}"
CURRENT_CONTEXT=$(kubectl config current-context)
NS=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
if [ -z $NS ]
then
    CURRENT_NS="default"
else
    CURRENT_NS=$NS
fi

echo -e "You are connected to the cluster:  ${RED}${CURRENT_CONTEXT}${NC}"
echo -e "Namespace: ${RED}${CURRENT_NS}${NC}"
echo -e "--------------------------------------------------------"
read -p "¿Is this the right production environment? (y/n): " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo -e "${RED}❌ Operation aborted by user.${NC}"
    exit 1
fi

# 3. Dry-Run 
echo -e "\n${YELLOW}[3/4] Simulating cluster changes (Dry-Run)...${NC}"
echo -e "${BLUE}Checking for deployment files on: ${SCRIPT_DIR}${NC}"

# Validating the yamls files edited with the CI/CD exists
if [ ! -f "app-deployment.yaml" ] || [ ! -f "static-deployment.yaml" ]; then
    echo -e "${RED}✗ Error: Couldn't find app-deployment.yaml or static-deployment.yaml on this directory.${NC}"
    exit 1
fi

# Dry-run to check the cluste local API
kubectl apply -f app-deployment.yaml -f static-deployment.yaml --dry-run=client

echo -e "${GREEN}✓ Simulation ended without any syntax error..${NC}"

# 4. Final confirmation and real deployment
echo -e "\n${RED}⚠️ ¡ATENTION! You are about to moddify production resources.${NC}"
read -p "Are you soure you want to proceed? (y/n): " confirm_final
if [[ ! "$confirm_final" =~ ^[yY]$ ]]; then
    echo -e "${RED}❌ Deployment canceled. No cluster modification was done.${NC}"
    exit 1
fi

echo -e "\n${YELLOW}[4/4] Applying manifests...${NC}"
kubectl apply -f app-deployment.yaml -f static-deployment.yaml

# 5. Last real-time verification
echo -e "\n${GREEN}✓ Manifest applied into the cluster.${NC}"
echo -e "${BLUE}Monitoring pod update (Press Ctrl+C to exit)...${NC}"
echo -e "--------------------------------------------------------"

# Check the new containers start with the new image
kubectl rollout status deployment/app --timeout=60s || echo -e "${YELLOW}⚠️ Rollout is taking more than expected. Verify with 'kubectl get pods'.${NC}"

echo -e "\n${GREEN}🎉 Deployment process ended.${NC}"
