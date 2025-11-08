# Shadow Deployment Strategy

## Overview
Shadow deployment (also known as Dark Launch or Dark Deployment) is a pattern where a new version runs in parallel with the production version, receiving a copy of live traffic without affecting real users. This allows teams to test the new version with production-like traffic and identify issues before any users are impacted.

## Architecture

```
                        ┌─────────────────────────┐
                        │    User Requests        │
                        └────────────┬────────────┘
                                     │
                        ┌────────────▼────────────┐
                        │   Traffic Duplicator    │
                        │  (Service Mesh/Proxy)   │
                        └────────┬────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
          ┌─────────▼──────────┐   ┌─────────▼──────────┐
          │  Production Deploy │   │   Shadow Deploy    │
          │   (User-Facing)    │   │  (Testing Only)    │
          │                    │   │                    │
          │  Version: 1.0      │   │  Version: 2.0      │
          │  3 Pods            │   │  3 Pods            │
          │                    │   │                    │
          │  Returns response  │   │  Response ignored  │
          │  to user ✓         │   │  (logging only)    │
          └────────────────────┘   └────────────────────┘
                   │                        │
                   │                        │
          User sees this response    Logged for comparison
                                     (errors don't affect users)
```

## Key Characteristics

### Traffic Flow
- **Production**: Receives all user requests, returns responses to users
- **Shadow**: Receives **duplicate** of all requests via mirroring
- **User Impact**: **ZERO** - Shadow responses are discarded, only logged

### Response Handling
- Production responses → Sent to users
- Shadow responses → Logged for analysis, then discarded
- Shadow errors → No user impact (invisible failures)

## Benefits
- ✅ **Zero User Impact**: Shadow errors don't affect production
- ✅ **Production Traffic**: Test with real user patterns and data
- ✅ **Performance Testing**: Measure response times under real load
- ✅ **Error Detection**: Find bugs before users see them
- ✅ **Capacity Planning**: Validate resource requirements
- ✅ **Database Testing**: Test queries with production-like data (read-only)

## Drawbacks
- ❌ **Resource Intensive**: Doubles infrastructure (both versions run at same scale)
- ❌ **Side Effects**: Careful with writes, emails, notifications (use mocks)
- ❌ **Cost**: 2x compute resources during testing period
- ❌ **Complexity**: Requires service mesh or custom proxy setup
- ❌ **Data Consistency**: Shadow can't modify production database

## Use Cases

### Ideal For:
- Testing performance improvements
- Validating bug fixes under production load
- Stress testing new features
- Comparing algorithm changes (A vs B performance)
- Validating infrastructure changes
- Testing third-party integrations (in read-only mode)

### Not Ideal For:
- Features requiring database writes
- Email/notification sending features (unless mocked)
- Payment processing (unless in test mode)
- Features with external side effects

## Implementation Methods

### Method 1: Service Mesh (Recommended for Production)
Using Istio, Linkerd, or Consul Connect:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: aceest-fitness-mirror
spec:
  hosts:
  - aceest-fitness
  http:
  - route:
    - destination:
        host: aceest-fitness-production
      weight: 100
    mirror:
      host: aceest-fitness-shadow
    mirrorPercentage:
      value: 100.0  # Mirror 100% of traffic
```

### Method 2: NGINX Mirroring
```nginx
location / {
    proxy_pass http://production-backend;
    mirror /mirror;
    mirror_request_body on;
}

location /mirror {
    internal;
    proxy_pass http://shadow-backend$request_uri;
}
```

### Method 3: Application-Level (Our Demo)
Manually duplicate requests for testing purposes.

## Deployment Process

### 1. Deploy Production Version
```bash
kubectl apply -f deployment-production.yaml
kubectl apply -f service.yaml
```

### 2. Deploy Shadow Version
```bash
kubectl apply -f deployment-shadow.yaml
```

### 3. Configure Traffic Mirroring
In production, configure service mesh:
```bash
# With Istio
kubectl apply -f istio-mirror.yaml
```

For our demo:
```powershell
# Test traffic mirroring manually
.\shadow.ps1 test -Requests 20
```

### 4. Monitor Shadow Logs
```bash
# Watch shadow logs for errors
kubectl logs -n aceest-fitness -l version=shadow -f

# Compare with production
kubectl logs -n aceest-fitness -l version=production -f
```

### 5. Analyze Metrics
Compare:
- Error rates (shadow vs production)
- Response times (latency comparison)
- Resource usage (CPU/memory)
- Database query performance

### 6. Promote or Rollback
If shadow performs well:
```bash
# Promote shadow to production
kubectl set image deployment/aceest-fitness-production \
  aceest-fitness=suryachaturvedula/aceest-fitness:v2.0
```

If shadow has issues:
```bash
# Simply delete shadow (no user impact)
kubectl delete deployment aceest-fitness-shadow
```

## Usage

### Deploy Shadow Setup
```bash
cd k8s/shadow
kubectl apply -f deployment-production.yaml
kubectl apply -f deployment-shadow.yaml
kubectl apply -f service.yaml
```

### Test Traffic Mirroring

#### PowerShell (Windows)
```powershell
# Check status
.\shadow.ps1 status

# Test with 10 mirrored requests
.\shadow.ps1 test

# Test with custom number of requests
.\shadow.ps1 test -Requests 50
```

### Monitor Deployments
```bash
# Watch production pods
kubectl get pods -n aceest-fitness -l version=production -w

# Watch shadow pods
kubectl get pods -n aceest-fitness -l version=shadow -w

# Compare logs
kubectl logs -n aceest-fitness -l version=production --tail=50
kubectl logs -n aceest-fitness -l version=shadow --tail=50
```

### Metrics Comparison
```bash
# Get resource usage
kubectl top pods -n aceest-fitness -l version=production
kubectl top pods -n aceest-fitness -l version=shadow

# Check error rates in logs
kubectl logs -n aceest-fitness -l version=shadow | grep -i error
```

## Monitoring Checklist

During shadow testing, monitor:

- [ ] **Error Rates**: Shadow should match or improve on production
- [ ] **Response Times**: Compare p50, p95, p99 latencies
- [ ] **Resource Usage**: CPU and memory consumption
- [ ] **Database Performance**: Query execution times
- [ ] **External API Calls**: Third-party service response times
- [ ] **Log Patterns**: Look for unexpected warnings/errors
- [ ] **Edge Cases**: Unusual user behavior handling

## Best Practices

1. **Start Small**: Mirror 10% of traffic initially, then increase
2. **Read-Only**: Shadow should only perform reads, not writes
3. **Mock Side Effects**: Mock emails, payments, notifications
4. **Time-Boxed**: Run shadow for limited period (hours/days, not weeks)
5. **Automated Comparison**: Use tools to diff logs/metrics
6. **Alert on Differences**: Set up alerts for error rate spikes
7. **Resource Limits**: Set proper limits to prevent shadow from affecting production
8. **Data Privacy**: Ensure shadow respects same privacy rules

## Advanced: Selective Mirroring

Mirror only specific traffic patterns:

```yaml
# Istio example: Mirror only POST requests
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: aceest-fitness-selective-mirror
spec:
  hosts:
  - aceest-fitness
  http:
  - match:
    - method:
        exact: POST
    route:
    - destination:
        host: aceest-fitness-production
    mirror:
      host: aceest-fitness-shadow
```

## Comparison with Other Strategies

| Feature | Shadow | Canary | Blue-Green |
|---------|--------|--------|------------|
| User Impact | None (0%) | Gradual (10→100%) | Instant switch |
| Resource Usage | 2x (100% + 100%) | ~1.1x (varies) | 2x during switch |
| Risk | Zero | Low (gradual) | Medium (instant) |
| Rollback | Not needed | Scale down | Switch back |
| Use Case | Testing only | Gradual rollout | Zero-downtime deploy |

## Kubernetes Resources

- **Production Deployment**: `aceest-fitness-production` (3 replicas, user-facing)
- **Shadow Deployment**: `aceest-fitness-shadow` (3 replicas, testing only)
- **Production Service**: `aceest-fitness-shadow-prod` (LoadBalancer, port 30110)
- **Shadow Service**: `aceest-fitness-shadow-internal` (ClusterIP, internal only)

## Environment Variables

Each deployment has unique environment variables:
- Production: `DEPLOYMENT_VERSION=PRODUCTION-v1.0`, `VERSION_TRACK=[PROD] Production`
- Shadow: `DEPLOYMENT_VERSION=SHADOW-v2.0`, `VERSION_TRACK=[SHADOW] Testing`

## Cleanup

After testing is complete:

```bash
# Remove shadow deployment (production unaffected)
kubectl delete deployment aceest-fitness-shadow -n aceest-fitness
kubectl delete service aceest-fitness-shadow-internal -n aceest-fitness

# Production continues running normally
```

## Real-World Tools

For production shadow deployments, consider:
- **Istio**: Service mesh with built-in traffic mirroring
- **Linkerd**: Lightweight service mesh
- **NGINX**: Reverse proxy with mirror module
- **Envoy**: Modern proxy with shadowing capabilities
- **Diffy** (Twitter): Automated difference detection
- **Scientist** (GitHub): Ruby library for shadow experiments
