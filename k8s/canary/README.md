# Canary Deployment Strategy

## Overview
Canary deployment is a pattern for rolling out releases to a subset of users or servers. The idea is to first deploy the change to a small subset of servers, test it, and then roll it out to the rest of the servers. This reduces the risk of introducing a new version that negatively impacts the entire infrastructure.

## Architecture

```
                    ┌─────────────────────────────┐
                    │   Load Balancer Service     │
                    │  (aceest-fitness-canary)    │
                    │                             │
                    │  Selector: app=aceest-fitness│
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │   Traffic Distribution      │
                    │   Based on Pod Count        │
                    └──────────────┬──────────────┘
                                   │
            ┌──────────────────────┴──────────────────────┐
            │                                             │
            ▼                                             ▼
    ┌───────────────┐                            ┌───────────────┐
    │ Stable Deploy │                            │ Canary Deploy │
    │ Version: 1.0  │                            │ Version: 2.0  │
    │               │                            │               │
    │ Replicas: 9   │ ◄─── 90% Traffic          │ Replicas: 1   │ ◄─── 10% Traffic
    │ (90%)         │                            │ (10%)         │
    └───────────────┘                            └───────────────┘
```

## Traffic Distribution Phases

### Phase 1: Initial Canary (10%)
- **Stable**: 9 pods (90% traffic)
- **Canary**: 1 pod (10% traffic)
- **Purpose**: Initial testing with minimal user impact

### Phase 2: Increased Confidence (30%)
- **Stable**: 7 pods (70% traffic)
- **Canary**: 3 pods (30% traffic)
- **Purpose**: Increased exposure after monitoring confirms success

### Phase 3: Equal Distribution (50%)
- **Stable**: 5 pods (50% traffic)
- **Canary**: 5 pods (50% traffic)
- **Purpose**: Major validation before full rollout

### Phase 4: Full Rollout (100%)
- **Stable**: 0 pods (0% traffic)
- **Canary**: 10 pods (100% traffic)
- **Purpose**: Complete migration to new version

## Benefits
- ✅ **Gradual Rollout**: Minimize blast radius of issues
- ✅ **Real Production Testing**: Test with real users and traffic
- ✅ **Easy Rollback**: Quickly revert by scaling down canary
- ✅ **Metrics-Driven**: Monitor metrics at each phase before proceeding
- ✅ **Risk Reduction**: Catch issues before full deployment

## Drawbacks
- ❌ **Complexity**: Requires monitoring and gradual scaling
- ❌ **Extended Rollout**: Takes longer than instant deployment
- ❌ **Mixed Versions**: Both versions run simultaneously during rollout
- ❌ **Stateful Apps**: Challenging with applications requiring data consistency

## Deployment Process

### 1. Initial Setup
```bash
# Deploy stable version (current production)
kubectl apply -f deployment-stable.yaml

# Deploy canary version (new version - minimal traffic)
kubectl apply -f deployment-canary.yaml

# Deploy service (selects both stable and canary)
kubectl apply -f service.yaml
```

### 2. Phase 1: 10% Canary
```powershell
# Start with 10% traffic to canary
.\canary.ps1 10

# Monitor metrics, error rates, performance
kubectl logs -n aceest-fitness -l version=canary --tail=50 -f
```

### 3. Phase 2: 30% Canary (if Phase 1 successful)
```powershell
# Increase to 30%
.\canary.ps1 30

# Continue monitoring
# Check error rates, response times, user feedback
```

### 4. Phase 3: 50% Canary (if Phase 2 successful)
```powershell
# Equal distribution
.\canary.ps1 50

# Major validation checkpoint
# Compare metrics between stable and canary
```

### 5. Phase 4: 100% Canary (Full Rollout)
```powershell
# Complete migration
.\canary.ps1 100

# Canary is now the production version
# Update stable deployment to match canary version
```

### Rollback (if issues detected)
```powershell
# Instantly rollback to stable
.\canary.ps1 rollback
```

## Usage

### Deploy Canary Setup
```bash
cd k8s/canary
kubectl apply -f deployment-stable.yaml
kubectl apply -f deployment-canary.yaml
kubectl apply -f service.yaml
```

### Manage Traffic Distribution

#### PowerShell (Windows)
```powershell
# Check current status
.\canary.ps1 status

# Set 10% canary
.\canary.ps1 10

# Set 30% canary
.\canary.ps1 30

# Set 50% canary
.\canary.ps1 50

# Full rollout (100%)
.\canary.ps1 100

# Rollback to stable
.\canary.ps1 rollback
```

#### Bash (Linux/Mac)
```bash
# Check current status
./canary.sh status

# Set traffic percentages
./canary.sh 10
./canary.sh 30
./canary.sh 50
./canary.sh 100

# Rollback
./canary.sh rollback
```

### Manual Scaling (Alternative)
```bash
# 10% canary (9 stable, 1 canary)
kubectl scale deployment aceest-fitness-stable -n aceest-fitness --replicas=9
kubectl scale deployment aceest-fitness-canary -n aceest-fitness --replicas=1

# 30% canary (7 stable, 3 canary)
kubectl scale deployment aceest-fitness-stable -n aceest-fitness --replicas=7
kubectl scale deployment aceest-fitness-canary -n aceest-fitness --replicas=3

# 50% canary (5 stable, 5 canary)
kubectl scale deployment aceest-fitness-stable -n aceest-fitness --replicas=5
kubectl scale deployment aceest-fitness-canary -n aceest-fitness --replicas=5

# 100% canary (0 stable, 10 canary)
kubectl scale deployment aceest-fitness-stable -n aceest-fitness --replicas=0
kubectl scale deployment aceest-fitness-canary -n aceest-fitness --replicas=10
```

## Monitoring Checklist

At each phase, verify:
- [ ] **Error Rates**: Compare error rates between stable and canary
- [ ] **Response Times**: Check latency metrics
- [ ] **Resource Usage**: Monitor CPU/memory consumption
- [ ] **Health Checks**: Ensure all health probes passing
- [ ] **User Feedback**: Monitor user complaints or issues
- [ ] **Business Metrics**: Track conversion rates, user engagement

## Best Practices

1. **Start Small**: Always begin with 10% or less
2. **Monitor Actively**: Watch metrics closely at each phase
3. **Automate Checks**: Use monitoring tools to auto-detect issues
4. **Set Thresholds**: Define success criteria (error rate < X%, latency < Y ms)
5. **Gradual Progression**: Don't skip phases - validate at each step
6. **Quick Rollback**: Keep rollback procedure ready
7. **Document Results**: Track metrics at each phase for future reference
8. **Time Windows**: Deploy during low-traffic periods initially

## Kubernetes Resources

- **Stable Deployment**: `aceest-fitness-stable` (9→7→5→0 replicas)
- **Canary Deployment**: `aceest-fitness-canary` (1→3→5→10 replicas)
- **Service**: `aceest-fitness-canary` (selects both via `app=aceest-fitness`)

## Environment Variables

Each deployment has unique environment variables:
- Stable: `DEPLOYMENT_VERSION=STABLE-v1.0`, `VERSION_TRACK=🟦 STABLE`
- Canary: `DEPLOYMENT_VERSION=CANARY-v2.0`, `VERSION_TRACK=🟨 CANARY`

## Advanced: Metrics-Based Automation

For production, consider integrating with Prometheus/Grafana:

```yaml
# Example: Automated canary with Flagger
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: aceest-fitness
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: aceest-fitness
  progressDeadlineSeconds: 60
  service:
    port: 80
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
    - name: request-duration
      thresholdRange:
        max: 500
```

## Traffic Distribution Formula

```
Total Pods = 10 (constant)
Canary Percentage = X%
Canary Pods = round(10 * X / 100)
Stable Pods = 10 - Canary Pods

Traffic to Canary ≈ Canary Pods / Total Pods
```

Note: Kubernetes load balancing is approximate - actual distribution may vary slightly based on connection timing and pod readiness.
