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

#### All Services
- **CPU threshold**: 70% → **75%** (more tolerant for idle loads)
- **Memory threshold**: 85% → **90%** (prevents premature scaling)
- **Scale-down stabilization**: 60s → **300s** (5 minutes to avoid flapping)
- **Scale-down policy**: 50% reduction → **100%** (can scale down completely in one cycle)

#### Service-Specific Optimizations

**event-command-service & event-query-service**:
```yaml
metrics:
  - cpu: 75% utilization
  - memory: 90% utilization
behavior:
  scaleUp:
    stabilizationWindowSeconds: 30
    policies:
      - 50% increase per 30s OR
      - 1 pod per 30s (whichever is higher)
  scaleDown:
    stabilizationWindowSeconds: 300
    policies:
      - 100% reduction per 60s (can remove all pods if needed)
```

**order-service**:
```yaml
metrics:
  - cpu: 75% utilization
  - memory: 85% utilization (Go service, more efficient)
behavior:
  scaleUp:
    stabilizationWindowSeconds: 30
    policies:
      - 100% increase per 30s OR
      - 2 pods per 30s (aggressive for traffic spikes)
  scaleDown:
    stabilizationWindowSeconds: 300
    policies:
      - 100% reduction per 60s
```

**scheduler-service**:
```yaml
metrics:
  - cpu: 75% utilization
  - memory: 85% utilization
behavior:
  scaleUp:
    stabilizationWindowSeconds: 60 (slower, less traffic)
    policies:
      - 1 pod per 60s
  scaleDown:
    stabilizationWindowSeconds: 300
    policies:
      - 100% reduction per 60s
```

## Results

### After Optimization
| Service | Before | After | CPU | Memory |
|---------|--------|-------|-----|--------|
| event-command | 3 pods | **1 pod** | 4% | 79% |
| event-query | 2 pods | **1 pod** | 4% | 56% |
| order-service | 1 pod | **1 pod** | 1% | 5% |
| scheduler | 1 pod | **1 pod** | 2% | 7% |

### Resource Savings
- **Before**: 7 total pods
- **After**: 4 total pods
- **Reduction**: 43% fewer pods during idle periods

### Current Resource Usage (Idle State)
```
event-command-service: 13m CPU, 754Mi memory
event-query-service:   13m CPU, 479Mi memory
order-service:         2m CPU,  12Mi memory
scheduler-service:     2m CPU,  9Mi memory
```

## Behavior Under Load

### Scale-Up Triggers
- **event-command/event-query**: Will scale at 75% CPU or 90% memory
  - Can add 1 pod every 30 seconds
  - Max 3-4 pods total

- **order-service**: Will scale at 75% CPU or 85% memory
  - Can add 2 pods every 30 seconds (aggressive)
  - Max 6 pods total

- **scheduler-service**: Will scale at 75% CPU or 85% memory
  - Can add 1 pod every 60 seconds (conservative)
  - Max 2 pods total

### Scale-Down Behavior
- **Stabilization window**: 5 minutes (300s)
  - Ensures sustained low usage before scaling down
  - Prevents flapping during intermittent traffic
- **Scale-down rate**: Can remove 100% of excess pods every 60s
  - Once stabilization window passes, rapid scale-down to minReplicas

## Best Practices Applied

1. ✅ **Memory metrics added**: Prevents CPU-only scaling misses
2. ✅ **Higher thresholds**: 75-90% allows better resource utilization
3. ✅ **Long stabilization**: 5-minute window prevents scaling thrash
4. ✅ **Aggressive scale-down**: Removes unnecessary pods quickly after stabilization
5. ✅ **Service-specific tuning**: Different behaviors for different workload types
6. ✅ **minReplicas=1**: All services can scale to zero extra pods during idle

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
2. **Idle test**: Wait 5+ minutes to verify scale-down
3. **Spike test**: Sudden traffic burst to verify rapid response
4. **Sustained load**: Verify stabilization doesn't cause flapping
