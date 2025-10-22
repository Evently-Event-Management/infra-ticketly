# Order Stress Test

## What This Test Does

This test validates the **order service's behavior under sustained high load** where multiple users continuously attempt to book seats.

### Test Characteristics
- **Duration:** ~16 minutes total
- **Load Pattern:** Ramps up → sustains load → increases → sustains → ramps down
- **Expected Responses:**
  - ✅ **201** - Successful booking (seat was available)
  - ✅ **400** - Seat already locked/booked (expected behavior)
  - ❌ **5xx** - Server errors (should be minimal)

### Load Profile
```
Stage 1 (2min):  Ramp 0 → 50 VUs    (warm up)
Stage 2 (5min):  Hold at 50 VUs     (baseline load)
Stage 3 (2min):  Ramp 50 → 75 VUs   (increase load)
Stage 4 (5min):  Hold at 75 VUs     (peak load)
Stage 5 (2min):  Ramp 75 → 0 VUs    (cool down)
```

## Expected Results

### ✅ Good Performance
```
Total requests:       ~4,000-8,000 (depending on response times)
Successful bookings:  Varies (seats available)
Seat locked (400):    Majority of requests
Expected rate:        >95% (201 or 400 responses)
Server errors (5xx):  <10 total
Response time p95:    <3000ms
```

### What This Validates
- ✅ **System stability** under sustained load
- ✅ **Proper error handling** (400 responses for locked seats)
- ✅ **No cascading failures** (minimal 5xx errors)
- ✅ **Consistent performance** across load levels

## Running the Test

```bash
# Production environment (default: 50 VUs base load)
./run-order-stress-test.sh prod

# Development environment
./run-order-stress-test.sh dev

# Custom VU count (100 VUs base, 150 VUs peak)
ORDER_STRESS_VUS=100 ./run-order-stress-test.sh prod

# Cloud execution
./run-order-stress-test.sh --cloud prod
```

## Configuration

Edit `src/config.js` to configure:

```javascript
order: {
  baseUrl: 'http://localhost:8084/api/order',
  eventId: 'your-event-id',
  sessionId: 'your-session-id',
  organizationId: 'your-org-id',
  seatIds: [
    '79cd17f8-e160-4e8b-9c8a-aefb59ee287a', // Seat 1A
    '70910468-5a2d-4b0b-88d9-1427ae167237', // Seat 2A
    // ... add more seats for variety
  ]
}
```

## Viewing Results

### Console Output
```
✓ BOOKING SUCCESS - VU 12 booked seat 3 - Order: abc-123
✓ EXPECTED - VU 45 seat 7 already locked (400)
✗ SERVER ERROR - VU 67 got 500: Internal server error
```

### Metrics
```
successful_bookings:   142    # 201 responses
seat_already_locked:   3,847  # 400 responses  
order_expected rate:   99.5%  # (201 + 400) / total
server_errors_5xx:     3      # Should be minimal
http_req_duration p95: 980ms  # Response times
```

### HTML Report
Saved to: `output/order_stress_{env}_{timestamp}.html`

## Troubleshooting

### ❌ High 5xx Error Rate (>1%)
**Problem:** Many server errors under load  
**Cause:** Service overload or bugs  
**Fix:** Scale service, optimize code, increase timeouts

### ❌ Expected Rate <95%
**Problem:** Too many unexpected responses (409, 423, timeouts)  
**Cause:** Lock contention or slow processing  
**Fix:** Review locking strategy, optimize database queries

### ❌ Slow Response Times (p95 >3000ms)
**Problem:** Poor performance under load  
**Cause:** Slow queries, insufficient resources  
**Fix:** Add indexes, scale horizontally, increase connection pools

## Comparison with Race Test

| Aspect | **Stress Test** | **Race Test** |
|--------|----------------|---------------|
| Purpose | Sustained load behavior | Race condition validation |
| Duration | 16 minutes | ~30 seconds |
| Load | Ramping, varied | Burst, simultaneous |
| Success criteria | 201 OR 400 = good | Only 1 booking per seat |
| Focus | Stability | Correctness |

## Notes

- Test creates **real bookings** - use test data
- 201 and 400 are both considered successful (expected behavior)
- Random seat selection to distribute load
- No artificial delays between requests (pure stress)
