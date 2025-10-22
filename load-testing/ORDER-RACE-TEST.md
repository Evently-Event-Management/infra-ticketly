# Order Race Condition Test

## Overview

This test validates the order service's ability to handle **race conditions** when multiple users attempt to book the same seat simultaneously. It's designed to verify proper locking mechanisms, idempotency, and conflict resolution.

## Test Design

### Concept
For each seat configured in `src/config.js`:
- **100 Virtual Users (VUs)** simultaneously attempt to book the **same seat**
- **Only 1 booking should succeed** (first-come, first-served)
- **99 bookings should fail** (seat already taken)

### Example Execution
If you have 4 seats configured (`seat-A1`, `seat-A2`, `seat-A3`, `seat-A4`):

```
Round 1: 100 VUs → seat-A1
  ✓ 1 success (VU #23 wins the race)
  ✗ 99 failures (seat already booked)

Round 2: 100 VUs → seat-A2  
  ✓ 1 success (VU #87 wins the race)
  ✗ 99 failures (seat already booked)

Round 3: 100 VUs → seat-A3
  ✓ 1 success (VU #5 wins the race)
  ✗ 99 failures (seat already booked)

Round 4: 100 VUs → seat-A4
  ✓ 1 success (VU #61 wins the race)
  ✗ 99 failures (seat already booked)

Total: 4 successful bookings, 396 failed bookings
```

## Configuration

### Seats to Test
Edit `src/config.js`:

```javascript
order: {
  baseUrl: 'http://localhost:8084/api/order',
  eventId: 'your-event-id',
  sessionId: 'your-session-id',
  organizationId: 'your-org-id',
  seatIds: [
    'seat-A1',  // Round 1
    'seat-A2',  // Round 2
    'seat-A3',  // Round 3
    'seat-A4',  // Round 4
  ]
}
```

### VUs per Seat
Default: 100 VUs per seat

Customize via environment variable:
```bash
ORDER_VUS=50 ./run-order-race-test.sh prod
```

## Running the Test

### Basic Usage
```bash
# Local environment
./run-order-race-test.sh local

# Dev environment
./run-order-race-test.sh dev

# Production environment
./run-order-race-test.sh prod
```

### Custom VU Count
```bash
# 50 VUs per seat
ORDER_VUS=50 ./run-order-race-test.sh prod

# 200 VUs per seat (extreme contention)
ORDER_VUS=200 ./run-order-race-test.sh prod
```

### Cloud Execution
```bash
# Run in k6 Cloud (Mumbai region)
./run-order-race-test.sh --cloud prod
```

### Legacy Script
The old `run-order-tests.sh` still works but uses the new logic:
```bash
./run-order-tests.sh prod
```

## Understanding Results

### Success Metrics

**✓ Ideal Results:**
```
successful_bookings: 4        (equals number of seats)
failed_bookings: 396          (4 seats × 99 failures each)
order_success rate: 1.0%      (4 successes / 400 total attempts)
```

### Viewing Results

1. **Console Output**
   ```
   ✓ SUCCESS - VU 23 booked seat seat-A1
   ✗ FAILED - VU 45 could not book seat seat-A1 (status: 409)
   ```

2. **HTML Report**
   - Saved to `output/order_race_all_seats_{env}_{timestamp}.html`
   - View success/failure rates
   - Analyze response times
   - Check for errors

3. **k6 Metrics**
   ```
   successful_bookings............: 4
   failed_bookings................: 396
   order_success..................: 1.0%
   http_req_duration (p95)........: 450ms
   ```

## What This Validates

### ✅ Race Condition Handling
- **Pessimistic Locking**: Database locks prevent double-booking
- **Optimistic Locking**: Version checks catch concurrent updates
- **Distributed Locks**: Redis/similar prevents race across instances

### ✅ Idempotency
- Multiple identical requests don't create duplicate bookings
- Retry-safe operations

### ✅ Conflict Resolution
- Clear "seat already booked" responses (typically HTTP 409)
- Proper error messages for failed bookings

### ✅ Performance Under Contention
- System maintains response times under heavy load
- No deadlocks or timeouts
- Graceful degradation

## Expected HTTP Responses

### Successful Booking (1 per seat)
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "order_id": "ord-123abc",
  "seat_id": "seat-A1",
  "status": "confirmed"
}
```

### Failed Booking (99 per seat)
```http
HTTP/1.1 409 Conflict
Content-Type: application/json

{
  "error": "SeatAlreadyBooked",
  "message": "Seat seat-A1 is no longer available",
  "seat_id": "seat-A1"
}
```

Or:
```http
HTTP/1.1 423 Locked
Content-Type: application/json

{
  "error": "SeatLocked",
  "message": "Seat is currently being processed"
}
```

## Troubleshooting

### Issue: Multiple Successes per Seat
**Problem:** More than 1 VU successfully books the same seat  
**Cause:** Race condition in locking mechanism  
**Fix:** 
- Review database transaction isolation level
- Implement row-level locks (`SELECT ... FOR UPDATE`)
- Add unique constraints on seat bookings
- Implement distributed locking (Redis)

### Issue: All Bookings Fail
**Problem:** No VU can book any seat  
**Cause:** Authentication, permission, or data issues  
**Fix:**
- Verify event/session/seat IDs in `src/config.js`
- Check user has permission to create orders
- Ensure seats exist and are available
- Review error messages in console/report

### Issue: High Error Rate
**Problem:** Many requests result in 500 errors  
**Cause:** Server overload or bugs under contention  
**Fix:**
- Scale order service instances
- Optimize database queries
- Add connection pooling
- Review application logs

### Issue: Slow Response Times
**Problem:** p95 > 2000ms under contention  
**Cause:** Lock contention, slow queries  
**Fix:**
- Optimize seat availability queries
- Use database indexes
- Consider read replicas
- Implement caching for seat status

## Performance Baselines

### Good Performance
```
✓ successful_bookings = number of seats
✓ http_req_duration (p95) < 1000ms
✓ http_req_failed rate ≈ 99%
✓ order_success rate ≈ 1%
✓ No 500 errors
```

### Acceptable Performance
```
✓ successful_bookings = number of seats
⚠ http_req_duration (p95) < 2000ms
✓ http_req_failed rate ≈ 99%
✓ order_success rate ≈ 1%
⚠ Minimal 500 errors (<1%)
```

### Poor Performance (Needs Investigation)
```
✗ Multiple successes per seat (race condition!)
✗ http_req_duration (p95) > 2000ms
✗ High 500 error rate
✗ Timeouts or connection errors
```

## Test Strategy

### Development
```bash
# Quick validation with fewer VUs
ORDER_VUS=20 ./run-order-race-test.sh dev
```

### Staging
```bash
# Standard race condition test
./run-order-race-test.sh dev
```

### Production
```bash
# Full contention test
./run-order-race-test.sh prod

# Extreme contention
ORDER_VUS=200 ./run-order-race-test.sh prod
```

## Architecture Recommendations

### Database Layer
```sql
-- Ensure unique constraint
ALTER TABLE seat_bookings 
ADD CONSTRAINT unique_seat_per_session 
UNIQUE (session_id, seat_id);

-- Use row-level locking
BEGIN TRANSACTION;
SELECT * FROM seats 
WHERE seat_id = 'seat-A1' 
  AND status = 'available' 
FOR UPDATE;
-- Book the seat
UPDATE seats SET status = 'booked' WHERE seat_id = 'seat-A1';
COMMIT;
```

### Application Layer
```javascript
// Idempotency key
headers: {
  'Idempotency-Key': generateUUID()
}

// Retry logic
maxRetries: 3,
retryOn: [409, 423, 503]
```

### Distributed Systems
- **Redis Lock**: Prevent race across multiple service instances
- **Optimistic Locking**: Use version numbers on seat records
- **Event Sourcing**: Append-only event log for bookings

## Monitoring

Watch these metrics during test:
- Database connection pool utilization
- Lock wait time
- Transaction rollback rate
- Error rate by status code
- Response time percentiles

## Related Tests

- `run-query-tests.sh` - Query service load testing
- `run-order-tests.sh` - Legacy order test (now uses race logic)
- Individual scenario tests in `src/scenarios/`

## Notes

- Test creates **real bookings** in the system
- Clean up test data after execution
- Don't run against production with real seats
- Use dedicated test event/session for race tests
