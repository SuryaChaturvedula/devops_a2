#!/bin/bash
# Blue-Green Deployment Script for ACEest Fitness
# This script manages switching traffic between blue and green deployments

NAMESPACE="aceest-fitness"
SERVICE="aceest-fitness-bluegreen"

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Blue-Green Deployment Manager${NC}"
echo -e "${YELLOW}========================================${NC}"

# Function to get current deployment
get_current_deployment() {
    kubectl get service $SERVICE -n $NAMESPACE -o jsonpath='{.spec.selector.deployment}'
}

# Function to switch to blue
switch_to_blue() {
    echo -e "${BLUE}Switching traffic to BLUE deployment...${NC}"
    kubectl patch service $SERVICE -n $NAMESPACE -p '{"spec":{"selector":{"deployment":"blue"}}}'
    echo -e "${BLUE}✓ Traffic now routed to BLUE${NC}"
}

# Function to switch to green
switch_to_green() {
    echo -e "${GREEN}Switching traffic to GREEN deployment...${NC}"
    kubectl patch service $SERVICE -n $NAMESPACE -p '{"spec":{"selector":{"deployment":"green"}}}'
    echo -e "${GREEN}✓ Traffic now routed to GREEN${NC}"
}

# Function to show status
show_status() {
    CURRENT=$(get_current_deployment)
    echo ""
    echo -e "${YELLOW}Current Status:${NC}"
    echo "  Active Deployment: $CURRENT"
    echo ""
    echo "Blue Deployment:"
    kubectl get deployment aceest-fitness-blue -n $NAMESPACE 2>/dev/null || echo "  Not deployed"
    echo ""
    echo "Green Deployment:"
    kubectl get deployment aceest-fitness-green -n $NAMESPACE 2>/dev/null || echo "  Not deployed"
    echo ""
    echo "Service:"
    kubectl get service $SERVICE -n $NAMESPACE 2>/dev/null || echo "  Not found"
}

# Main menu
case "$1" in
    blue)
        switch_to_blue
        ;;
    green)
        switch_to_green
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {blue|green|status}"
        echo ""
        echo "Commands:"
        echo "  blue   - Switch traffic to blue deployment"
        echo "  green  - Switch traffic to green deployment"
        echo "  status - Show current deployment status"
        exit 1
        ;;
esac

echo ""
show_status
