# Blue-Green Deployment Strategy

## Overview
Blue-Green deployment is a release strategy that reduces downtime and risk by running two identical production environments called Blue and Green. Only one environment serves production traffic at any time, while the other is idle or used for testing the new version.

## Architecture

```
┌─────────────────────────────────────────────────┐
│           Load Balancer Service                 │
│         (aceest-fitness-bluegreen)              │
│                                                 │
│  Selector: deployment: blue  (switchable)       │
└────────────────┬────────────────────────────────┘
                 │
      ┌──────────┴──────────┐
      │                     │
      ▼                     ▼
┌──────────────┐      ┌──────────────┐
│ BLUE Deploy  │      │ GREEN Deploy │
│ (Active)     │      │ (Inactive)   │
│              │      │              │
│ 3 Pods       │      │ 3 Pods       │
│ Version: 1.0 │      │ Version: 2.0 │
└──────────────┘      └──────────────┘
```

## Benefits
- ✅ **Zero Downtime**: Instant switch between versions
- ✅ **Easy Rollback**: Switch back to previous version immediately
- ✅ **Testing**: Test new version in production environment before switching
- ✅ **Risk Reduction**: Both environments are identical

## Drawbacks
- ❌ **Resource Intensive**: Requires 2x infrastructure (both environments running)
- ❌ **Database Compatibility**: Database changes must be backward compatible
- ❌ **Cost**: Higher cloud/infrastructure costs

## Deployment Process

### 1. Initial Setup (Blue is Active)
```bash
# Deploy Blue environment (current version)
kubectl apply -f deployment-blue.yaml

# Deploy Green environment (new version - not receiving traffic yet)
kubectl apply -f deployment-green.yaml

# Deploy service pointing to Blue
kubectl apply -f service.yaml
```

### 2. Verify Green Deployment
```bash
# Check Green pods are ready
kubectl get pods -n aceest-fitness -l deployment=green

# Test Green deployment internally
kubectl port-forward -n aceest-fitness deployment/aceest-fitness-green 8080:5000
# Access http://localhost:8080 to verify
```

### 3. Switch Traffic to Green
```bash
# Using PowerShell script
./switch.ps1 green

# Or manually
kubectl patch service aceest-fitness-bluegreen -n aceest-fitness \
  -p '{"spec":{"selector":{"deployment":"green"}}}'
```

### 4. Monitor and Verify
```bash
# Check service is routing to Green
kubectl describe service aceest-fitness-bluegreen -n aceest-fitness

# Monitor logs
kubectl logs -n aceest-fitness -l deployment=green --tail=50 -f
```

### 5. Rollback (if needed)
```bash
# Switch back to Blue instantly
./switch.ps1 blue
```

## Usage

### Deploy Both Environments
```bash
kubectl apply -f k8s/blue-green/
```

### Switch to Blue
```powershell
# PowerShell
.\k8s\blue-green\switch.ps1 blue
```

### Switch to Green
```powershell
# PowerShell
.\k8s\blue-green\switch.ps1 green
```

### Check Status
```powershell
# PowerShell
.\k8s\blue-green\switch.ps1 status
```

## Best Practices

1. **Version Management**: Use different image tags for blue and green
2. **Health Checks**: Ensure robust liveness/readiness probes
3. **Monitoring**: Monitor both environments during switch
4. **Testing**: Thoroughly test green before switching traffic
5. **Database**: Ensure schema changes are backward compatible
6. **Cleanup**: Keep inactive environment for quick rollback (at least 24-48 hours)

## Kubernetes Resources

- **Blue Deployment**: `aceest-fitness-blue` (3 replicas)
- **Green Deployment**: `aceest-fitness-green` (3 replicas)
- **Service**: `aceest-fitness-bluegreen` (switches via selector)

## Environment Variables

Each deployment has unique environment variables for identification:
- Blue: `DEPLOYMENT_VERSION=BLUE`, `VERSION_COLOR=🔵 BLUE`
- Green: `DEPLOYMENT_VERSION=GREEN`, `VERSION_COLOR=🟢 GREEN`
