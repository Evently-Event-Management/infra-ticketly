# Token Auto-Refresh Implementation

## Problem
During long-running load tests (stress, soak, etc.), JWT tokens were expiring mid-test, causing authentication failures:
```
Bearer error="invalid_token", error_description="Jwt expired at 2025-10-21T21:24:57Z"
```

## Solution
Implemented automatic token refresh logic that:
1. **Tracks token expiration time** - Stores `expires_at` timestamp with 30-second buffer
2. **Checks token validity** - Validates before each request iteration
3. **Refreshes automatically** - Obtains new token when current one expires
4. **Per-VU caching** - Each Virtual User maintains its own token cache

## Changes Made

### 1. `src/lib/auth.js`
- Modified `getAuthToken()` to return token metadata:
  ```javascript
  {
    access_token: string,
    expires_in: number,
    expires_at: number  // Calculated with 30s buffer
  }
  ```
- Added `getValidToken()` function to check and refresh expired tokens

### 2. `query-test.js`
- Added `tokenCache` object to store per-VU token data
- Modified `setup()` to return `tokenData` instead of just token string
- Updated default function to:
  - Initialize token cache for each VU
  - Check and refresh token before each iteration
  - Extract `access_token` for use in requests

### 3. `order-test.js`
- Applied same token refresh logic as query-test.js

### 4. `src/lib/workflows.js`
- Enhanced error logging to show response status, body preview, and headers
- Helps diagnose token expiration and other API issues

## How It Works

```javascript
// Setup phase (once)
tokenData = getAuthToken()  // Get initial token

// Each iteration (per VU)
tokenCache[vuId] = getValidToken(tokenCache[vuId])  // Refresh if needed
authToken = tokenCache[vuId].access_token           // Use fresh token
```

## Benefits

✅ **No more mid-test token expiration** - Tokens refresh automatically  
✅ **Long-running tests supported** - Soak tests can run for hours  
✅ **Minimal overhead** - Only refreshes when needed (not on every request)  
✅ **Better error visibility** - Detailed logging for troubleshooting  
✅ **Per-VU independence** - Each Virtual User manages its own token  

## Token Expiration Handling

- **Default token lifetime**: Typically 5-15 minutes (configured in Keycloak)
- **Refresh buffer**: 30 seconds before actual expiration
- **Check frequency**: Before each VU iteration
- **Refresh overhead**: ~100-200ms per token refresh

## Testing

Run stress or soak tests to verify token refresh:
```bash
# Stress test (should exceed token lifetime)
./run-query-tests.sh stress prod

# Soak test (10+ minutes)
./run-query-tests.sh soak prod
```

Look for log messages:
```
Token expired or missing, refreshing...
Successfully obtained token, expires in 300 seconds
```

## Notes

- Token refresh is transparent to the test scenarios
- No changes needed to individual test scenarios
- Works with all test types (smoke, load, stress, soak, spike, etc.)
- Compatible with both query and order service tests
