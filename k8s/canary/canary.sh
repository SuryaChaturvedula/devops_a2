#!/bin/bash
# Canary Deployment Script
# Manages gradual traffic shift from stable to canary version

NAMESPACE="aceest-fitness"
STABLE_DEPLOYMENT="aceest-fitness-stable"
CANARY_DEPLOYMENT="aceest-fitness-canary"

# Colors
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Canary Deployment Manager${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Function to calculate replicas
calculate_replicas() {
    local percentage=$1
    local total=10
    local canary=$(( total * percentage / 100 ))
    local stable=$(( total - canary ))
    echo "$stable $canary"
}

# Function to set traffic split
set_traffic_split() {
    local percentage=$1
    read stable canary <<< $(calculate_replicas $percentage)
    
    echo -e "${CYAN}Setting traffic split: ${percentage}% to Canary, $((100-percentage))% to Stable${NC}"
    echo -e "  ${BLUE}Stable pods: $stable${NC}"
    echo -e "  ${YELLOW}Canary pods: $canary${NC}"
    echo ""
    
    kubectl scale deployment $STABLE_DEPLOYMENT -n $NAMESPACE --replicas=$stable
    kubectl scale deployment $CANARY_DEPLOYMENT -n $NAMESPACE --replicas=$canary
    
    echo -e "${GREEN}✓ Traffic split updated!${NC}"
    echo ""
    echo -e "${YELLOW}Waiting for deployments to be ready...${NC}"
    kubectl rollout status deployment/$STABLE_DEPLOYMENT -n $NAMESPACE --timeout=60s
    kubectl rollout status deployment/$CANARY_DEPLOYMENT -n $NAMESPACE --timeout=60s
}

# Function to rollback
rollback() {
    echo -e "${RED}Rolling back to 100% stable version...${NC}"
    set_traffic_split 0
    echo ""
    echo -e "${GREEN}✓ Rollback complete - all traffic on stable version${NC}"
}

# Function to show status
show_status() {
    echo -e "${YELLOW}Current Status:${NC}"
    echo ""
    
    stable_replicas=$(kubectl get deployment $STABLE_DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.replicas}' 2>/dev/null)
    canary_replicas=$(kubectl get deployment $CANARY_DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.replicas}' 2>/dev/null)
    
    if [ ! -z "$stable_replicas" ] && [ ! -z "$canary_replicas" ]; then
        total=$((stable_replicas + canary_replicas))
        if [ $total -gt 0 ]; then
            canary_percent=$((canary_replicas * 100 / total))
            stable_percent=$((100 - canary_percent))
            echo -e "${CYAN}Traffic Distribution:${NC}"
            echo -e "  ${BLUE}🟦 Stable: ${stable_percent}% ($stable_replicas pods)${NC}"
            echo -e "  ${YELLOW}🟨 Canary: ${canary_percent}% ($canary_replicas pods)${NC}"
            echo ""
        fi
    fi
    
    echo -e "${BLUE}Stable Deployment:${NC}"
    kubectl get deployment $STABLE_DEPLOYMENT -n $NAMESPACE 2>/dev/null || echo "  Not deployed"
    echo ""
    
    echo -e "${YELLOW}Canary Deployment:${NC}"
    kubectl get deployment $CANARY_DEPLOYMENT -n $NAMESPACE 2>/dev/null || echo "  Not deployed"
    echo ""
    
    echo -e "${CYAN}Pods:${NC}"
    kubectl get pods -n $NAMESPACE -l app=aceest-fitness --show-labels 2>/dev/null
}

# Main logic
case "$1" in
    10)
        echo -e "${YELLOW}📊 Phase 1: Initial Canary Release (10%)${NC}"
        set_traffic_split 10
        ;;
    30)
        echo -e "${YELLOW}📊 Phase 2: Increase Canary Traffic (30%)${NC}"
        set_traffic_split 30
        ;;
    50)
        echo -e "${YELLOW}📊 Phase 3: Equal Split (50%)${NC}"
        set_traffic_split 50
        ;;
    100)
        echo -e "${YELLOW}📊 Phase 4: Full Canary Rollout (100%)${NC}"
        set_traffic_split 100
        echo ""
        echo -e "${GREEN}🎉 Canary is now the new stable version!${NC}"
        echo -e "${NC}   You can now update the stable deployment to this version${NC}"
        ;;
    rollback)
        rollback
        ;;
    status)
        show_status
        exit 0
        ;;
    *)
        echo "Usage: $0 {10|30|50|100|rollback|status}"
        echo ""
        echo "Commands:"
        echo "  10       - Set 10% traffic to canary"
        echo "  30       - Set 30% traffic to canary"
        echo "  50       - Set 50% traffic to canary"
        echo "  100      - Set 100% traffic to canary (full rollout)"
        echo "  rollback - Rollback to 100% stable"
        echo "  status   - Show current deployment status"
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}========================================${NC}"
show_status
