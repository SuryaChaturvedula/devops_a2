# Rolling Update Deployment Strategy

## Overview

**Rolling Update** is Kubernetes' default and native deployment strategy that gradually replaces old pods with new ones. It provides zero-downtime deployments by ensuring a minimum number of pods are always available while incrementally updating the application.

This strategy is built into Kubernetes and doesn't require custom service switching or replica management - just update the deployment and Kubernetes handles the rest!

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Rolling Update Process                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Initial State (v1.0):                                           │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐                    │
│  │ v1 │ │ v1 │ │ v1 │ │ v1 │ │ v1 │ │ v1 │  (6 pods)          │
│  └────┘ └────┘ └────┘ └────┘ └────┘ └────┘                    │
│                                                                   │
│  Step 1: Create surge pods (maxSurge=2)                         │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐      │
│  │ v1 │ │ v1 │ │ v1 │ │ v1 │ │ v1 │ │ v1 │ │ v2 │ │ v2 │      │
│  └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘      │
│                                      (8 pods total - 2 surge)    │
│                                                                   │
│  Step 2: Terminate old pods (maxUnavailable=1)                  │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐              │
│  │ v1 │ │ v1 │ │ v1 │ │ v1 │ │ v1 │ │ v2 │ │ v2 │              │
│  └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘              │
│                                      (7 pods)                    │
│                                                                   │
│  Step 3: Continue cycling...                                    │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐      │
│  │ v1 │ │ v1 │ │ v1 │ │ v2 │ │ v2 │ │ v2 │ │ v2 │ │ v2 │      │
│  └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘      │
│                                                                   │
│  Final State (v2.0):                                             │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐                    │
│  │ v2 │ │ v2 │ │ v2 │ │ v2 │ │ v2 │ │ v2 │  (6 pods)          │
│  └────┘ └────┘ └────┘ └────┘ └────┘ └────┘                    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Key Configuration Parameters

### maxUnavailable
- **Definition**: Maximum number of pods that can be unavailable during the update
- **Value**: `1` (conservative - only 1 pod down at a time)
- **Effect**: Slower rollout but higher availability (83% minimum capacity)
- **Alternatives**: 
  - `0`: No pods unavailable (requires maxSurge > 0)
  - `2`: Faster rollout, lower temporary capacity (67% minimum)
  - `25%`: Percentage-based (dynamic based on replica count)

### maxSurge
- **Definition**: Maximum number of extra pods that can be created during update
- **Value**: `2` (can temporarily have 8 pods instead of 6)
- **Effect**: Faster rollout with temporary resource overhead (133% peak capacity)
- **Alternatives**:
  - `1`: Slower rollout, less resource usage
  - `3`: Very fast rollout, higher resource usage
  - `50%`: Percentage-based (dynamic based on replica count)

### Calculation Examples
With 6 replicas:
- **maxUnavailable=1, maxSurge=2**: Min 5 pods, Max 8 pods
- **maxUnavailable=0, maxSurge=1**: Min 6 pods, Max 7 pods (zero downtime)
- **maxUnavailable=2, maxSurge=0**: Min 4 pods, Max 6 pods (no extra resources)

## Deployment

### Initial Deployment
```powershell
# Deploy the rolling update deployment
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Wait for deployment to be ready
kubectl rollout status deployment/aceest-fitness-rolling -n aceest-fitness
```

### Update to New Version
```powershell
# Method 1: Using management script (recommended)
.\rolling-update.ps1 update suryachaturvedula/aceest-fitness:v2.0

# Method 2: Direct kubectl command
kubectl set image deployment/aceest-fitness-rolling -n aceest-fitness aceest-fitness=suryachaturvedula/aceest-fitness:v2.0 --record

# Watch the rollout progress
kubectl rollout status deployment/aceest-fitness-rolling -n aceest-fitness
```

### Monitor Rollout
```powershell
# Check current status
.\rolling-update.ps1 status

# Watch pods changing in real-time
kubectl get pods -n aceest-fitness -l deployment=rolling -w

# See ReplicaSets (old and new versions)
kubectl get rs -n aceest-fitness -l deployment=rolling
```

### Pause/Resume Rollout
```powershell
# Pause rollout (useful for manual validation)
.\rolling-update.ps1 pause

# Validate the new pods
kubectl get pods -n aceest-fitness -l deployment=rolling
# Test new version...

# Resume rollout
.\rolling-update.ps1 resume
```

### Rollback
```powershell
# Automatic rollback to previous version
.\rolling-update.ps1 rollback

# Or rollback to specific revision
kubectl rollout undo deployment/aceest-fitness-rolling -n aceest-fitness --to-revision=2
```

## Management Script Usage

### Available Commands
```powershell
# Show deployment status and configuration
.\rolling-update.ps1 status

# Update to new image version
.\rolling-update.ps1 update suryachaturvedula/aceest-fitness:v2.0

# Rollback to previous version
.\rolling-update.ps1 rollback

# Pause ongoing rollout
.\rolling-update.ps1 pause

# Resume paused rollout
.\rolling-update.ps1 resume

# View rollout history
.\rolling-update.ps1 history

# Restart all pods (rolling restart)
.\rolling-update.ps1 restart
```

## Rollout History

### View History
```powershell
# See all revisions
.\rolling-update.ps1 history

# See specific revision details
kubectl rollout history deployment/aceest-fitness-rolling -n aceest-fitness --revision=3
```

### Rollback to Specific Revision
```powershell
kubectl rollout undo deployment/aceest-fitness-rolling -n aceest-fitness --to-revision=2
```

## Health Checks During Rollout

### Readiness Probes
- **Purpose**: Determines when new pods are ready to receive traffic
- **Configuration**: HTTP check on `/health` endpoint
- **Parameters**:
  - Initial delay: 5 seconds
  - Period: 5 seconds
  - Failure threshold: 2 (fails after 2 consecutive failures)
  - Success threshold: 1 (ready after 1 success)

### Liveness Probes
- **Purpose**: Detects and restarts unhealthy pods
- **Configuration**: HTTP check on `/health` endpoint
- **Parameters**:
  - Initial delay: 10 seconds
  - Period: 10 seconds
  - Failure threshold: 3 (kills pod after 3 failures)

**Impact**: New pods only receive traffic when readiness probe succeeds, ensuring smooth transitions.

## Advantages

✅ **Native Kubernetes Integration**
- Built-in feature - no external tools needed
- Works with standard kubectl commands
- Integrates with Kubernetes dashboard and monitoring

✅ **Zero-Downtime Updates**
- Always maintains minimum replica count
- Gradual replacement ensures availability
- Automatic health check integration

✅ **Resource Efficient**
- Configurable resource overhead (maxSurge)
- Balanced approach between speed and resources
- Can operate within existing resource limits

✅ **Easy Rollback**
- Automatic revision history tracking
- One-command rollback to previous version
- Can rollback to any previous revision

✅ **Fine-Grained Control**
- Pause/resume during rollout
- Configurable speed via maxUnavailable/maxSurge
- Can monitor and validate at each step

✅ **Automatic Failure Handling**
- Stops rollout if new pods fail health checks
- Maintains old version if update fails
- Configurable failure detection thresholds

## Disadvantages

❌ **Mixed Version Traffic**
- Old and new versions run simultaneously
- May cause inconsistent behavior
- Requires backward compatibility

❌ **Resource Overhead During Update**
- Temporarily uses more resources (maxSurge)
- May exceed resource quotas
- Requires capacity planning

❌ **Slower Than Instant Switching**
- Takes time to roll through all pods
- Not suitable for immediate updates
- Gradual process can't be "instant"

❌ **No Traffic Control**
- Can't test new version with 10% traffic first
- All pods receive equal traffic share
- No canary-style gradual exposure

❌ **Database Migration Challenges**
- Both versions must support same schema
- May need multi-phase deployments
- Complex for breaking changes

## When to Use Rolling Update

### ✅ Ideal For:
- **Standard application updates**: Version upgrades, bug fixes, feature additions
- **Backward-compatible changes**: New version works with old data/APIs
- **Production environments**: Need high availability during updates
- **Resource-constrained clusters**: Limited capacity for multiple versions
- **Frequent deployments**: Regular CI/CD pipeline updates
- **Microservices**: Independent service updates

### ❌ Avoid When:
- **Breaking changes**: Incompatible API or schema changes
- **Testing new features**: Want to validate with small traffic first (use Canary)
- **A/B testing**: Need to compare versions with metrics (use A/B Testing)
- **Instant switchover needed**: Critical updates requiring immediate change (use Blue-Green)
- **Risk-free production testing**: Zero user impact testing (use Shadow)

## Comparison with Other Strategies

| Feature | Rolling Update | Blue-Green | Canary | Shadow | A/B Testing |
|---------|---------------|------------|---------|---------|-------------|
| **Downtime** | None | None | None | None | None |
| **Resource Usage** | Medium (1.33x peak) | High (2x) | Low (1.1x) | High (2x) | Medium (varies) |
| **Rollback Speed** | Medium | Instant | Instant | N/A | Instant |
| **Traffic Control** | None | Instant switch | Gradual % | Mirroring | Split testing |
| **Complexity** | Low (native) | Medium | Medium | High | High |
| **Risk Level** | Low-Medium | Low | Very Low | None | Low |
| **Use Case** | Standard updates | Critical releases | Risk reduction | Production testing | Feature validation |
| **Mixed Versions** | Yes (temporary) | No | Yes (controlled) | Yes (shadowed) | Yes (persistent) |
| **Kubernetes Native** | ✅ Yes | ❌ No | ❌ No | ❌ No | ❌ No |

## Best Practices

### 1. Configure Health Checks
```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 2
  successThreshold: 1
```

### 2. Set Appropriate Resource Limits
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

### 3. Use --record Flag for History
```powershell
kubectl set image deployment/aceest-fitness-rolling aceest-fitness=myimage:v2 --record
```

### 4. Test Updates in Staging First
- Deploy to staging environment
- Validate functionality
- Monitor for issues
- Then deploy to production

### 5. Monitor During Rollout
```powershell
# Watch pod status
kubectl get pods -n aceest-fitness -l deployment=rolling -w

# Check events
kubectl get events -n aceest-fitness --sort-by='.lastTimestamp'

# Monitor logs
kubectl logs -n aceest-fitness -l deployment=rolling --tail=50 -f
```

### 6. Set minReadySeconds for Stability
```yaml
spec:
  minReadySeconds: 10  # Wait 10s after ready before next pod
```

### 7. Use PodDisruptionBudget
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: aceest-fitness-pdb
spec:
  minAvailable: 4  # At least 4 pods must stay running
  selector:
    matchLabels:
      app: aceest-fitness
```

## Troubleshooting

### Rollout Stuck
```powershell
# Check rollout status
kubectl rollout status deployment/aceest-fitness-rolling -n aceest-fitness

# Describe deployment for events
kubectl describe deployment aceest-fitness-rolling -n aceest-fitness

# Check if pods are ready
kubectl get pods -n aceest-fitness -l deployment=rolling

# Common causes:
# - Failed readiness probes
# - Insufficient resources
# - Image pull errors
```

### Failed Health Checks
```powershell
# Check pod logs
kubectl logs -n aceest-fitness <pod-name>

# Describe pod for events
kubectl describe pod -n aceest-fitness <pod-name>

# Test health endpoint manually
kubectl exec -n aceest-fitness <pod-name> -- curl localhost:5000/health
```

### Rollback After Partial Update
```powershell
# Immediate rollback
kubectl rollout undo deployment/aceest-fitness-rolling -n aceest-fitness

# Or use script
.\rolling-update.ps1 rollback
```

## Metrics to Monitor

### During Rollout
- Pod readiness percentage
- HTTP error rates (4xx, 5xx)
- Response time (p50, p95, p99)
- Resource utilization (CPU, memory)
- Number of ready replicas

### Post-Rollout
- Application errors in logs
- Business metrics (transactions, signups, etc.)
- User-reported issues
- Performance degradation

## Advanced Techniques

### Progressive Rollout with Pausing
```powershell
# Start update
kubectl set image deployment/aceest-fitness-rolling aceest-fitness=myimage:v2 --record

# Immediately pause
kubectl rollout pause deployment/aceest-fitness-rolling -n aceest-fitness

# Validate first few pods
# ... run tests ...

# Resume if healthy
kubectl rollout resume deployment/aceest-fitness-rolling -n aceest-fitness
```

### Custom Update Strategy
```yaml
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0     # Zero downtime - no pods down
      maxSurge: 1           # Conservative - one at a time
  minReadySeconds: 30       # Wait 30s between pod updates
```

## Service Accessibility

The rolling update deployment is accessible via:

- **LoadBalancer Service**: `aceest-fitness-rolling` on NodePort 30130
- **Access URL**: `http://<minikube-ip>:30130`
- **Health Check**: `http://<minikube-ip>:30130/health`

```powershell
# Get Minikube IP
minikube ip

# Test service
curl http://$(minikube ip):30130/health
```

## Conclusion

Rolling Update is the **default and most commonly used** deployment strategy in Kubernetes. It provides:

- ✅ Zero-downtime deployments
- ✅ Automatic rollback on failures
- ✅ Native Kubernetes integration
- ✅ Good balance of speed and safety
- ✅ Low operational complexity

While it doesn't offer the traffic control of Canary or the instant switchover of Blue-Green, it's the **go-to choice for most production deployments** due to its simplicity, reliability, and native support in Kubernetes.

**Use Rolling Update when**: You want a simple, reliable, production-ready deployment strategy that works out-of-the-box with Kubernetes!
