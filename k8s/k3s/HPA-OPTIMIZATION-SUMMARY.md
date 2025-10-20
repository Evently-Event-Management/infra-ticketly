# HPA Optimization Summary

## Problem Analysis

### Initial State
- **event-command-service**: 3 pods (scaled up)
- **event-query-service**: 2 pods (scaled up)
- **order-service**: 1 pod (correct)
- **scheduler-service**: 1 pod (correct)

### Root Cause
The HPA was configured with **memory utilization threshold of 85%**, which was too aggressive for idle workloads:

1. **event-command-service**: Memory usage was 90% of the **request** (950Mi), causing scale-up
   - Actual usage: ~1020Mi / 950Mi request = 107% → triggered scale-up
   - 3 pods reduced load to ~750Mi average per pod

2. **event-query-service**: Memory usage was 56% of request (850Mi)
   - Actual usage: ~479Mi / 850Mi = 56%
   - Scaled to 2 pods unnecessarily

## Solution Implemented

### HPA Configuration Changes

#### Service-Specific Optimizations

**event-command-service (Spring MVC)**:
```yaml
metrics:
  - cpu: 70% utilization
  - memory: 80% utilization
behavior:
  scaleUp:
    stabilizationWindowSeconds: 60
    policies:
      - 100% increase per 60s OR
      - 1 pod per 60s (whichever is higher)
  scaleDown:
    stabilizationWindowSeconds: 300
    policies:
      - 50% reduction per 120s
```

**event-query-service (Spring WebFlux)**:
```yaml
metrics:
  - cpu: 65% utilization
  - memory: 75% utilization
behavior:
  scaleUp:
    stabilizationWindowSeconds: 30
    policies:
      - 150% increase per 30s OR
      - 2 pods per 30s (whichever is higher)
  scaleDown:
    stabilizationWindowSeconds: 240
    policies:
      - 33% reduction per 60s
```

**order-service (Go)**:
```yaml
metrics:
  - cpu: 60% utilization
  - memory: 70% utilization
behavior:
  scaleUp:
    stabilizationWindowSeconds: 0
    policies:
      - 300% increase per 15s OR
      - 4 pods per 15s (whichever is higher)
  scaleDown:
    stabilizationWindowSeconds: 120
    policies:
      - 50% reduction per 60s
```

**scheduler-service (Go with background jobs)**:
```yaml
metrics:
  - cpu: 70% utilization
  - memory: 70% utilization
behavior:
  scaleUp:
    stabilizationWindowSeconds: 90
    policies:
      - 1 pod per 90s
  scaleDown:
    stabilizationWindowSeconds: 360
    policies:
      - 100% reduction per 90s
```

## Results

### After Optimization
| Service | Before | After | CPU | Memory |
|---------|--------|-------|-----|--------|
| event-command | 3 pods | **1 pod** | 1.6% | 54.1% |
| event-query | 2 pods | **1 pod** | 2% | 52.2% |
| order-service | 1 pod | **1 pod** | 0.8% | 6.2% |
| scheduler | 1 pod | **1 pod** | 1.2% | 7.8% |

### Resource Savings
- **Before**: 7 total pods
- **After**: 4 total pods
- **Reduction**: 43% fewer pods during idle periods

### Current Resource Usage (Idle State)
```
event-command-service: 4m CPU, 622Mi memory (54% of 1150Mi request)
event-query-service:   7m CPU, 444Mi memory (52% of 850Mi request)
order-service:         1m CPU, 16Mi memory (6% of 256Mi request)
scheduler-service:     1m CPU, 10Mi memory (8% of 128Mi request)
```

## Behavior Under Load

### Scale-Up Triggers
- **event-command-service (Spring MVC)**: Will scale at 70% CPU or 80% memory
  - Can add 1 pod every 60 seconds (100% increase)
  - Max 3 pods total (event creator traffic)

- **event-query-service (Spring WebFlux)**: Will scale at 65% CPU or 75% memory
  - Can add 2 pods every 30 seconds (150% increase)
  - Max 5 pods total (buyer traffic)

- **order-service (Go)**: Will scale at 60% CPU or 70% memory
  - Can add 4 pods every 15 seconds (300% increase) - immediate response
  - Max 8 pods total (purchase spikes)

- **scheduler-service (Go background)**: Will scale at 70% CPU or 70% memory
  - Can add 1 pod every 90 seconds (conservative)
  - Max 3 pods total (notification processing)

### Scale-Down Behavior
- **Stabilization windows vary by service** (60s-360s)
  - Ensures sustained low usage before scaling down
  - Prevents flapping during intermittent traffic
- **Scale-down rates**: 33%-100% reduction per 60-120s
  - Once stabilization window passes, rapid scale-down to minReplicas

## Best Practices Applied

1. ✅ **Technology-aware scaling**: Different thresholds for Spring vs Go services
2. ✅ **Workload-specific tuning**: Command (creator) vs Query (buyer) vs Order (purchases) vs Scheduler (background)
3. ✅ **Memory utilization metrics**: Prevents CPU-only scaling misses
4. ✅ **Service-specific stabilization windows**: 0s-360s based on service needs
5. ✅ **Aggressive scale-up for critical services**: Order service scales immediately (0s window)
6. ✅ **Conservative scale-down**: Prevents flapping while allowing rapid cleanup
7. ✅ **Resource-efficient thresholds**: 60-80% utilization allows better resource utilization
8. ✅ **minReplicas=1**: All services can scale to minimum during idle periods

## Monitoring Recommendations

```bash
# Watch HPA status
kubectl get hpa -n ticketly --watch

# Monitor pod resource usage
kubectl top pods -n ticketly

# Check scaling events
kubectl get events -n ticketly --sort-by='.lastTimestamp' | grep -i scale

# View HPA details
kubectl describe hpa <service-name> -n ticketly
```

## Future Optimizations

Consider implementing:
1. **KEDA (Kubernetes Event-Driven Autoscaling)** for event-based scaling (Kafka lag, SQS queue depth)
2. **Vertical Pod Autoscaler (VPA)** to right-size resource requests/limits
3. **PodDisruptionBudgets** to ensure availability during scale-down
4. **Custom metrics** (request rate, queue depth) for more accurate scaling

## Testing Plan

1. **Load test**: Generate traffic to verify scale-up behavior
   - Event creation traffic → command-service should scale to 3 pods
   - Event browsing traffic → query-service should scale to 5 pods
   - Purchase spikes → order-service should scale to 8 pods immediately
2. **Idle test**: Wait 2-6 minutes to verify scale-down (service-specific windows)
3. **Spike test**: Sudden traffic burst to verify rapid response (order-service: 0s window)
4. **Sustained load**: Verify stabilization doesn't cause flapping
5. **Background job test**: Scheduler service notification batch processing

## Key Improvements

- **Order service**: Zero stabilization window for instant scale-up during purchase spikes
- **Query service**: More aggressive scaling (150% increase) for buyer traffic
- **Command service**: Conservative scaling for event creator traffic
- **Scheduler service**: Extended stabilization windows for background job stability
- **Resource efficiency**: Lower utilization thresholds (60-80%) for better resource usage
