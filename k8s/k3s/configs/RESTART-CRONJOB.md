# Microservices Daily Restart CronJob

This directory contains Kubernetes resources for automatically restarting all Ticketly microservices daily at midnight Sri Lanka time.

## Components

### 1. RBAC Configuration (`restart-cronjob-rbac.yaml`)

Creates the necessary permissions for the CronJob to restart deployments:

- **ServiceAccount**: `deployment-restarter`
- **Role**: `deployment-restarter-role` - Grants permissions to:
  - Get, list, and patch deployments
  - Get and list pods (for verification)
- **RoleBinding**: Binds the role to the service account

### 2. CronJob (`microservices-restart-cronjob.yaml`)

Scheduled job that performs rolling restarts of all microservices:

- **Schedule**: `30 18 * * *` (18:30 UTC = 00:00 Sri Lanka Time UTC+5:30)
- **Timezone**: Asia/Colombo
- **Deployments Restarted**:
  - event-command-service
  - event-query-service
  - order-service
  - scheduler-service

## Deployment

### Apply RBAC first:
```bash
kubectl apply -f k8s/k3s/configs/restart-cronjob-rbac.yaml
```

### Apply CronJob:
```bash
kubectl apply -f k8s/k3s/configs/microservices-restart-cronjob.yaml
```

### Or apply both:
```bash
kubectl apply -f k8s/k3s/configs/restart-cronjob-rbac.yaml
kubectl apply -f k8s/k3s/configs/microservices-restart-cronjob.yaml
```

## Verification

### Check if CronJob is created:
```bash
kubectl get cronjob microservices-daily-restart -n ticketly
```

### View CronJob details:
```bash
kubectl describe cronjob microservices-daily-restart -n ticketly
```

### Check recent job runs:
```bash
kubectl get jobs -n ticketly -l app=microservices-restart
```

### View logs of the most recent job:
```bash
# Get the most recent job
JOB_NAME=$(kubectl get jobs -n ticketly -l app=microservices-restart --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')

# View logs
kubectl logs -n ticketly job/$JOB_NAME
```

### Check ServiceAccount and RBAC:
```bash
kubectl get sa deployment-restarter -n ticketly
kubectl get role deployment-restarter-role -n ticketly
kubectl get rolebinding deployment-restarter-rolebinding -n ticketly
```

## Manual Trigger

To manually trigger a restart without waiting for the scheduled time:

```bash
kubectl create job --from=cronjob/microservices-daily-restart manual-restart-$(date +%s) -n ticketly
```

## Monitoring

### Watch the restart process:
```bash
# Get the job that's currently running
kubectl get jobs -n ticketly -l app=microservices-restart -w

# Follow logs in real-time
kubectl logs -n ticketly -l job-type=scheduled-maintenance -f
```

### Check deployment status after restart:
```bash
kubectl get deployments -n ticketly
kubectl get pods -n ticketly
```

## Configuration

### Modify Schedule

To change the restart time, edit the `schedule` field in `microservices-restart-cronjob.yaml`:

```yaml
spec:
  # Format: "minute hour day month weekday"
  schedule: "30 18 * * *"  # 00:00 Sri Lanka Time
  timeZone: "Asia/Colombo"
```

Common schedules:
- `0 0 * * *` - Midnight UTC
- `30 18 * * *` - Midnight Sri Lanka Time (00:00 IST)
- `0 2 * * *` - 2:00 AM UTC
- `0 0 * * 0` - Midnight every Sunday

### Add/Remove Deployments

Edit the `DEPLOYMENTS` array in the CronJob container command:

```bash
DEPLOYMENTS=(
  "event-command-service"
  "event-query-service"
  "order-service"
  "scheduler-service"
  # Add more deployments here
)
```

### Adjust Timeout

Change the rollout status timeout (default: 5 minutes):

```bash
kubectl rollout status deployment/"$deployment" -n ticketly --timeout=5m
```

## Troubleshooting

### CronJob not running:

1. Check if CronJob is suspended:
   ```bash
   kubectl get cronjob microservices-daily-restart -n ticketly -o jsonpath='{.spec.suspend}'
   ```

2. Resume if suspended:
   ```bash
   kubectl patch cronjob microservices-daily-restart -n ticketly -p '{"spec":{"suspend":false}}'
   ```

### Job failing:

1. Check job status:
   ```bash
   kubectl describe job <job-name> -n ticketly
   ```

2. Check pod logs:
   ```bash
   kubectl logs -n ticketly -l job-name=<job-name>
   ```

3. Check RBAC permissions:
   ```bash
   kubectl auth can-i get deployments --as=system:serviceaccount:ticketly:deployment-restarter -n ticketly
   kubectl auth can-i patch deployments --as=system:serviceaccount:ticketly:deployment-restarter -n ticketly
   ```

### Rollout stuck:

If a deployment rollout gets stuck:

```bash
# Check rollout status
kubectl rollout status deployment/<deployment-name> -n ticketly

# Check for issues
kubectl describe deployment/<deployment-name> -n ticketly

# Manually undo if needed
kubectl rollout undo deployment/<deployment-name> -n ticketly
```

## Cleanup

To remove the CronJob and RBAC:

```bash
kubectl delete cronjob microservices-daily-restart -n ticketly
kubectl delete rolebinding deployment-restarter-rolebinding -n ticketly
kubectl delete role deployment-restarter-role -n ticketly
kubectl delete serviceaccount deployment-restarter -n ticketly
```

## Important Notes

1. **Zero Downtime**: Rolling restarts ensure pods are replaced gradually with zero downtime
2. **HPA Compatibility**: Works with HorizontalPodAutoscaler; HPA continues managing replicas
3. **Concurrency**: Only one restart job runs at a time (`concurrencyPolicy: Forbid`)
4. **History**: Keeps last 3 successful and 1 failed job for debugging
5. **Timeout**: Job fails if it takes longer than 10 minutes
6. **Retry**: Failed jobs retry up to 2 times before giving up

## Benefits

- **Memory Leak Prevention**: Regular restarts help clear memory leaks in long-running processes
- **Cache Refresh**: Clears stale caches and refreshes connections
- **Configuration Updates**: Ensures environment changes are picked up
- **Consistent State**: All services start fresh daily at a predictable time
- **Zero Downtime**: Rolling restarts maintain service availability
