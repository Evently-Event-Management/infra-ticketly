# Order Race Condition Test

## What This Test Does

This test simulates a **real-world race condition** where multiple users try to book the same seat at the exact same time (like a concert going on sale).

### Test Execution
1. **Spawn 100 Virtual Users (VUs)**
2. **All 100 VUs compete for Seat 1** → Only 1 succeeds, 99 fail
3. **All 100 VUs compete for Seat 2** → Only 1 succeeds, 99 fail
4. **All 100 VUs compete for Seat 3** → Only 1 succeeds, 99 fail
5. **Continues for all seats** configured in `src/config.js`

### Example with 16 Seats
```
🚀 Spawned 100 VUs

Seat 1:  100 requests → ✓ 1 success, ✗ 99 failures
Seat 2:  100 requests → ✓ 1 success, ✗ 99 failures
Seat 3:  100 requests → ✓ 1 success, ✗ 99 failures
...
Seat 16: 100 requests → ✓ 1 success, ✗ 99 failures

Total: 1600 requests
       16 successes (1 per seat)
       1584 failures (99 per seat)
```

## Expected Results

### ✅ Perfect Results
```
Total requests:     1600 (100 VUs × 16 seats)
Successful bookings: 16  (exactly 1 per seat)
Failed bookings:     1584 (exactly 99 per seat)
Success rate:        1.00%
Server errors (5xx): 0
Response time p95:   < 2000ms
```

### What This Validates
- ✅ **No double-booking**: Only 1 VU can book each seat
- ✅ **Proper locking**: Database/Redis locks prevent race conditions
- ✅ **Correct errors**: Failed bookings return 400/409/423 status
- ✅ **Performance**: System handles high contention gracefully


## Running the Test

```bash
# Production environment
./run-order-race-test.sh prod

# Development environment
./run-order-race-test.sh dev

# Custom VU count (default is 100)
ORDER_VUS=200 ./run-order-race-test.sh prod
```


## Viewing Results

### Console Output
```
✓ SUCCESS - VU 34 booked seat 1 (79cd17f8-...) - Order: 41fe88ca-...
✗ FAILED - VU 1 seat 1 (79cd17f8-...) - Status 400: Seat validation failed
✗ FAILED - VU 2 seat 1 (79cd17f8-...) - Status 400: Seat validation failed
...
```

### Final Summary
```
========================================
Order Race Test Results Summary
========================================
Total VUs: 100
Total seats tested: 16
Total requests: 1600
----------------------------------------
Expected successes: 16 (1 per seat)
Expected failures: 1584 (99 per seat)
========================================
```

### Metrics
```
successful_bookings: 16
failed_bookings: 1584
order_success: 1.00%
seat_locked_400: 1584
http_req_duration (p95): 1.38s
```

### HTML Report
Saved to: `output/order_race_all_seats_{env}_{timestamp}.html`


## Configuration

Edit `src/config.js` to configure seats:

```javascript
order: {
  baseUrl: 'http://localhost:8084/api/order',
  eventId: 'your-event-id',
  sessionId: 'your-session-id',
  organizationId: 'your-org-id',
  seatIds: [
    '79cd17f8-e160-4e8b-9c8a-aefb59ee287a', // Seat 1A
    '70910468-5a2d-4b0b-88d9-1427ae167237', // Seat 2A
    'af24bb02-ad5a-4fda-9810-aa54bf86c840', // Seat 3A
    // ... add more seats
  ]
}
```

**Note:** Test is dynamic - it automatically uses `seatIds.length` to determine total iterations.

## Troubleshooting

### ❌ Multiple Successes per Seat
**Problem:** More than 1 booking succeeds per seat  
**Cause:** Race condition bug - locking not working properly  
**Fix:** Check database locks, add unique constraints, implement proper locking

### ❌ All Bookings Fail
**Problem:** 0 successes  
**Cause:** Configuration or permission issues  
**Fix:** Verify event/session/seat IDs, check user permissions

### ❌ High 5xx Errors
**Problem:** Many server errors  
**Cause:** Server overload or application bugs  
**Fix:** Scale service, optimize queries, check logs

### ❌ Slow Response Times
**Problem:** p95 > 2000ms  
**Cause:** Lock contention or slow queries  
**Fix:** Add database indexes, optimize queries, consider caching
