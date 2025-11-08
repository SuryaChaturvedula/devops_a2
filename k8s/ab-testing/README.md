# A/B Testing Deployment Strategy

## Overview
A/B testing (also known as split testing) is a method of comparing two versions of an application to determine which performs better. Traffic is split between version A (control) and version B (experiment), and user behavior metrics are collected to make data-driven decisions about which version to deploy.

## Architecture

```
                    ┌─────────────────────────┐
                    │     User Requests       │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   Traffic Router        │
                    │  (Ingress/Service)      │
                    │                         │
                    │  Split Logic:           │
                    │  - Cookie-based         │
                    │  - Header-based         │
                    │  - User ID hash         │
                    │  - Random (50/50)       │
                    └────────┬────────────────┘
                             │
            ┌────────────────┴────────────────┐
            │                                 │
   ┌────────▼─────────┐           ┌─────────▼────────┐
   │   Version A      │           │   Version B      │
   │   (Control)      │           │   (Experiment)   │
   │                  │           │                  │
   │   Current UX     │           │   New Feature    │
   │   3 Pods (50%)   │           │   3 Pods (50%)   │
   │                  │           │                  │
   │   Track:         │           │   Track:         │
   │   - Conversions  │           │   - Conversions  │
   │   - Engagement   │           │   - Engagement   │
   │   - Errors       │           │   - Errors       │
   └──────────────────┘           └──────────────────┘
```

## Key Characteristics

### User Assignment
- **Sticky Sessions**: Users stay on same version (cookie/session affinity)
- **Random Split**: New users randomly assigned to A or B
- **Hash-Based**: User ID hashed to determine A or B (consistent)
- **Segment-Based**: Premium users → B, Free users → A

### Metrics Collection
Both versions track:
- Conversion rates
- User engagement
- Click-through rates
- Time on site
- Error rates
- Performance metrics

## Benefits
- ✅ **Data-Driven Decisions**: Make choices based on real user behavior
- ✅ **Risk Reduction**: Only expose percentage of users to new version
- ✅ **Statistical Validation**: Prove which version performs better
- ✅ **Feature Validation**: Test new features before full rollout
- ✅ **User Segmentation**: Test different experiences for different user groups
- ✅ **Gradual Rollout**: Start small (10/90), increase confidence (50/50)

## Drawbacks
- ❌ **Complexity**: Requires metrics collection and analysis
- ❌ **Sample Size**: Need enough users for statistical significance
- ❌ **Time**: May need days/weeks to collect sufficient data
- ❌ **Consistency**: Users might see inconsistent experience if switching
- ❌ **Infrastructure**: Running two versions simultaneously

## Use Cases

### Ideal For:
- Testing new UI/UX changes
- Comparing different algorithms (recommendations, search)
- Validating pricing changes
- Testing new features before GA (General Availability)
- Optimizing conversion funnels
- Comparing performance optimizations

### Examples:
- **E-commerce**: Test checkout flow A vs B, measure conversion
- **Content**: Test headline variants, measure click-through
- **Pricing**: Test $9.99 vs $10.99, measure revenue
- **Features**: Test new recommendation algorithm, measure engagement

## Traffic Routing Methods

### Method 1: Session Affinity (Simple - Our Implementation)
Kubernetes Service with `ClientIP` affinity:
- First request randomly routed to A or B
- Subsequent requests from same IP go to same version
- Good for: Simple A/B tests, IP-based consistency

### Method 2: Cookie-Based Routing (Recommended)
Ingress controller sets cookie:
```
Set-Cookie: version=A; Max-Age=604800
```
- User assigned to A or B on first visit
- Cookie persists across sessions (7 days)
- Good for: Long-term experiments, mobile apps

### Method 3: Header-Based Routing
Explicitly route using custom header:
```
X-Version: B
```
- Developers can force specific version
- QA testing specific variants
- Good for: Testing, internal users

### Method 4: User ID Hash
Application-level routing:
```python
if hash(user_id) % 2 == 0:
    version = "A"
else:
    version = "B"
```
- Consistent assignment per user
- Works across devices
- Good for: Logged-in users, mobile apps

## Deployment Process

### 1. Deploy Both Versions
```bash
kubectl apply -f deployment-version-a.yaml
kubectl apply -f deployment-version-b.yaml
kubectl apply -f service.yaml
```

### 2. Set Traffic Split

#### Equal Split (50/50)
```powershell
.\ab-testing.ps1 split -PercentageB 50
```

#### Gradual Rollout
```powershell
# Start conservative (10% B)
.\ab-testing.ps1 split -PercentageB 10

# After 24 hours, if metrics look good, increase
.\ab-testing.ps1 split -PercentageB 30

# After more validation
.\ab-testing.ps1 split -PercentageB 50
```

### 3. Monitor Metrics

Track key metrics for both versions:

```bash
# Monitor error rates
kubectl logs -n aceest-fitness -l version=a | grep -i error | wc -l
kubectl logs -n aceest-fitness -l version=b | grep -i error | wc -l

# Monitor resource usage
kubectl top pods -n aceest-fitness -l version=a
kubectl top pods -n aceest-fitness -l version=b
```

### 4. Analyze Results

Compare metrics between A and B:

| Metric | Version A | Version B | Winner |
|--------|-----------|-----------|--------|
| Conversion Rate | 3.2% | 4.1% | B ✓ |
| Avg Session Time | 5.3 min | 6.1 min | B ✓ |
| Error Rate | 0.2% | 0.15% | B ✓ |
| Page Load Time | 1.2s | 1.1s | B ✓ |

### 5. Decision

If Version B wins:
```bash
# Scale B to 100%
.\ab-testing.ps1 split -PercentageB 100

# Or update production deployment
kubectl set image deployment/aceest-fitness-production \
  aceest-fitness=suryachaturvedula/aceest-fitness:version-b
```

If Version A wins:
```bash
# Keep A, scale down B
.\ab-testing.ps1 split -PercentageB 0
kubectl delete deployment aceest-fitness-version-b
```

## Usage

### Deploy A/B Testing Setup
```bash
cd k8s/ab-testing
kubectl apply -f deployment-version-a.yaml
kubectl apply -f deployment-version-b.yaml
kubectl apply -f service.yaml
```

### Manage Traffic Split

#### PowerShell (Windows)
```powershell
# Check current status
.\ab-testing.ps1 status

# Set 50/50 split
.\ab-testing.ps1 split -PercentageB 50

# Set 70% A, 30% B
.\ab-testing.ps1 split -PercentageB 30

# Test both versions
.\ab-testing.ps1 test
```

### Advanced: Ingress-Based Routing (Requires NGINX Ingress)

Enable NGINX Ingress Controller:
```bash
minikube addons enable ingress
```

Deploy ingress configuration:
```bash
kubectl apply -f ingress.yaml
```

Test with headers:
```bash
# Force Version A
curl -H "X-Version: A" http://aceest-fitness.local

# Force Version B
curl -H "X-Version: B" http://aceest-fitness.local
```

Test with cookies:
```bash
# Force Version A
curl -b "version=A" http://aceest-fitness.local

# Force Version B
curl -b "version=B" http://aceest-fitness.local
```

## Statistical Significance

Before making decisions, ensure statistical significance:

### Sample Size Formula
```
n = (Z^2 * p * (1-p)) / E^2

Where:
  n = sample size needed
  Z = confidence level (1.96 for 95%)
  p = estimated proportion (0.5 for worst case)
  E = margin of error (0.05 for 5%)

Example: n = (1.96^2 * 0.5 * 0.5) / 0.05^2 = 384 users per variant
```

### Tools for Analysis
- **Google Analytics**: Track goals per variant
- **Optimizely**: Full-service A/B testing platform
- **VWO**: Visual Website Optimizer
- **Custom**: Prometheus + Grafana for metrics

## Best Practices

1. **Single Variable**: Test one change at a time (UI vs algorithm, not both)
2. **Sufficient Sample**: Wait for statistical significance
3. **Equal Exposure**: Ensure both variants get traffic from same time periods
4. **Consistent Assignment**: Keep users on same variant throughout test
5. **Pre-Define Metrics**: Decide success criteria before testing
6. **Set Duration**: Run for at least 1-2 weeks for behavioral patterns
7. **Segment Analysis**: Check if results differ by user segment
8. **Document Everything**: Track what was tested and why

## Monitoring Checklist

During A/B test, monitor:

- [ ] **Conversion Rates**: Primary success metric
- [ ] **Secondary Metrics**: Engagement, retention, revenue
- [ ] **Error Rates**: Ensure B doesn't have more errors
- [ ] **Performance**: Response times for both variants
- [ ] **User Feedback**: Support tickets, complaints
- [ ] **Sample Size**: Ensure enough data collected
- [ ] **Statistical Significance**: Use proper testing methods
- [ ] **Segment Performance**: Check different user groups

## Kubernetes Resources

- **Version A Deployment**: `aceest-fitness-version-a` (3 pods, control group)
- **Version B Deployment**: `aceest-fitness-version-b` (3 pods, test group)
- **Version A Service**: `aceest-fitness-ab-version-a` (ClusterIP)
- **Version B Service**: `aceest-fitness-ab-version-b` (ClusterIP)
- **Load Balancer Service**: `aceest-fitness-ab` (LoadBalancer, port 30120, ClientIP affinity)

## Environment Variables

Each deployment has unique environment variables:
- Version A: `DEPLOYMENT_VERSION=VERSION-A (Control)`, `FEATURE_FLAG_NEW_UI=false`
- Version B: `DEPLOYMENT_VERSION=VERSION-B (Experiment)`, `FEATURE_FLAG_NEW_UI=true`

## Comparison with Other Strategies

| Feature | A/B Testing | Canary | Blue-Green |
|---------|-------------|--------|------------|
| Purpose | Experiment/Compare | Gradual Rollout | Zero-downtime Deploy |
| User Assignment | Random/Sticky | Random | All users |
| Traffic Split | 50/50 typical | 10→100% gradual | 0% or 100% |
| Duration | Days/Weeks | Hours/Days | Minutes |
| Metrics Focus | Business metrics | Error rates | Deployment success |
| Rollback | Choose winner | Scale down canary | Switch back |

## Advanced: Feature Flags

For more control, use feature flags in code:

```python
def get_recommendations(user_id):
    # Check which variant user is assigned to
    variant = get_user_variant(user_id)  # Returns 'A' or 'B'
    
    if variant == 'B':
        # New recommendation algorithm
        return new_recommendation_engine(user_id)
    else:
        # Original algorithm
        return original_recommendation_engine(user_id)
```

## Real-World Tools

For production A/B testing, consider:
- **LaunchDarkly**: Feature flag management
- **Split.io**: Feature delivery platform
- **Optimizely**: Experimentation platform
- **Google Optimize**: Free A/B testing (with Analytics)
- **Istio**: Service mesh with traffic splitting
- **Flagger**: Progressive delivery for Kubernetes

## Cleanup

After test completes and winner is chosen:

```bash
# If B wins, remove A
kubectl delete deployment aceest-fitness-version-a -n aceest-fitness
kubectl delete service aceest-fitness-ab-version-a -n aceest-fitness

# Update production to use B version

# If A wins, remove B
kubectl delete deployment aceest-fitness-version-b -n aceest-fitness
kubectl delete service aceest-fitness-ab-version-b -n aceest-fitness
```
