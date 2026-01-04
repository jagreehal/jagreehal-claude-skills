---
name: performance-testing
description: "Load testing, chaos engineering, and performance validation. Prove your system works under pressure with k6, trace correlation, and progressive load profiles."
version: 1.0.0
libraries: ["k6"]
---

# Performance Testing

## Core Principle

Unit tests verify correctness. Integration tests verify the stack works. **Load tests reveal bottlenecks that only appear under pressure.**

```
Single Request: 135ms ✓
Under 1000 concurrent: 2550ms ✗

The bottleneck was invisible until you added load.
```

## Required Behaviors

### 1. Progressive Load Profiles

Don't jump to stress testing. Use progressive profiles:

#### Smoke Test: Does It Work?

```javascript
// load-tests/smoke.js
export const options = {
  vus: 1,
  duration: '1m',
  thresholds: {
    http_req_failed: ['rate<0.01'],
  },
};
```

One user, one minute. If this fails, you have a functional bug, not a performance problem.

#### Load Test: Expected Traffic

```javascript
// load-tests/load.js
export const options = {
  stages: [
    { duration: '2m', target: 50 },   // Ramp up to 50 users
    { duration: '5m', target: 50 },   // Stay at 50 users
    { duration: '2m', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.01'],
  },
};
```

This simulates your expected production traffic.

#### Stress Test: Find the Breaking Point

```javascript
// load-tests/stress.js
export const options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 200 },
    { duration: '5m', target: 200 },
    { duration: '2m', target: 300 },  // Where does it break?
    { duration: '5m', target: 300 },
    { duration: '2m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'],  // Relaxed threshold
  },
};
```

Keep pushing until something breaks. Note what failed first.

#### Soak Test: Memory Leaks and Degradation

```javascript
// load-tests/soak.js
export const options = {
  stages: [
    { duration: '5m', target: 50 },
    { duration: '4h', target: 50 },   // Hold for 4 hours
    { duration: '5m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
  },
};
```

Run for hours at moderate load. Watch for:
- Memory usage creeping up
- Response times gradually increasing
- Connection leaks
- File handle exhaustion

#### Spike Test: Sudden Bursts

```javascript
// load-tests/spike.js
export const options = {
  stages: [
    { duration: '10s', target: 10 },   // Warm up
    { duration: '1m', target: 10 },    // Baseline
    { duration: '10s', target: 500 },   // SPIKE!
    { duration: '3m', target: 500 },    // Hold the spike
    { duration: '10s', target: 10 },   // Scale back down
    { duration: '3m', target: 10 },    // Recovery period
    { duration: '5s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<3000'],  // Allow slower during spike
    http_req_failed: ['rate<0.05'],      // Allow up to 5% errors
  },
};
```

Spike tests reveal:
- Does your autoscaler react fast enough?
- Does your load balancer drop connections?
- Do database connection pools handle sudden demand?
- Does the system recover after the spike?

### 2. Connect Load Tests to Traces

Pass trace context from k6 to correlate with OpenTelemetry:

```javascript
// load-tests/orders-with-tracing.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { randomUUID } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';

export default function () {
  const traceId = randomUUID().replace(/-/g, '');
  const spanId = randomUUID().replace(/-/g, '').slice(0, 16);

  const response = http.post(`${BASE_URL}/api/orders`, payload, {
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': API_KEY,
      // W3C Trace Context header
      'traceparent': `00-${traceId}-${spanId}-01`,
      // Custom header for correlation
      'x-load-test-id': __ENV.TEST_RUN_ID || 'local',
    },
  });

  check(response, {
    'status is 201': (r) => r.status === 201,
  });

  sleep(1);  // Simulate user think time - prevents accidental DDoS
}
```

**Always include `sleep()`** - Without it, a single VU generates hundreds of requests per second, accidentally DDoS-ing your local machine. The sleep simulates realistic user behavior.

Now you can find your load test requests in Jaeger/Honeycomb:

```
service.name = "orders-api"
duration > 1s
attributes.x-load-test-id = "stress-test-2024-01-15"
```

### 3. Analyze Traces Under Load

Common bottlenecks revealed by load + traces:

| Symptom in Traces | Root Cause | Fix |
|-------------------|------------|-----|
| Long waits before DB query starts | Connection pool exhausted | Increase pool size or reduce query time |
| External API calls taking 10x longer | Rate limiting kicked in | Add caching, request batching |
| Same DB query repeated N times | N+1 query pattern | Use eager loading / joins |
| Memory spans getting longer over time | Memory leak / GC pressure | Profile memory, fix leaks |
| Timeouts only under load | Resource contention | Add connection limits, queuing |

### 4. Set SLOs and Thresholds

Don't just measure—set expectations. k6 thresholds fail your test if SLOs aren't met:

```javascript
export const options = {
  thresholds: {
    // Response time SLOs
    http_req_duration: [
      'p(50)<200',   // Median under 200ms
      'p(95)<500',   // 95th percentile under 500ms
      'p(99)<1000',  // 99th percentile under 1s
    ],

    // Availability SLO
    http_req_failed: ['rate<0.001'],  // 99.9% success rate

    // Custom metrics
    'order_created': ['count>100'],   // At least 100 orders created

    // Per-endpoint thresholds
    'http_req_duration{endpoint:create_order}': ['p(95)<800'],
    'http_req_duration{endpoint:get_order}': ['p(95)<200'],
  },
};
```

### 5. Chaos Engineering

Prove your [resilience patterns](/skills/resilience) actually work by injecting failures.

#### Simple Chaos: Latency Injection

```typescript
// src/test-utils/chaos.ts
export function withLatency<T>(
  fn: () => Promise<T>,
  options: { minMs: number; maxMs: number }
): () => Promise<T> {
  return async () => {
    const delay = Math.random() * (options.maxMs - options.minMs) + options.minMs;
    await new Promise((resolve) => setTimeout(resolve, delay));
    return fn();
  };
}

export function withFailureRate<T>(
  fn: () => Promise<T>,
  failureRate: number,  // 0.0 to 1.0
  error: Error = new Error('Injected failure')
): () => Promise<T> {
  return async () => {
    if (Math.random() < failureRate) {
      throw error;
    }
    return fn();
  };
}
```

Use in integration tests:

```typescript
// src/orders/create-order.chaos.test.ts
import { withLatency } from '../test-utils/chaos';
import { createOrder } from './create-order';

it('completes within SLO when payment provider is slow', async () => {
  const slowPaymentProvider = {
    charge: withLatency(
      () => Promise.resolve({ transactionId: 'tx-123' }),
      { minMs: 1500, maxMs: 2000 }  // 1.5-2s latency
    ),
  };

  const start = Date.now();
  const result = await createOrder(
    { customerId: 'cust-1', items: [...] },
    { db: mockDb, paymentProvider: slowPaymentProvider }
  );
  const duration = Date.now() - start;

  expect(result.ok).toBe(true);
  expect(duration).toBeLessThan(5000);  // Still under 5s SLO
});
```

#### Network-Level Chaos with Toxiproxy

For more realistic chaos, use [Toxiproxy](https://github.com/Shopify/toxiproxy):

```yaml
# docker-compose.chaos.yml
services:
  toxiproxy:
    image: ghcr.io/shopify/toxiproxy
    ports:
      - "8474:8474"   # API
      - "5433:5433"   # Proxied postgres

  postgres:
    image: postgres:16
    # Toxiproxy sits between app and postgres
```

```typescript
// Configure toxic before load test
import Toxiproxy from 'toxiproxy-node-client';

const toxiproxy = new Toxiproxy('http://localhost:8474');

// Add 500ms latency to database
await toxiproxy.createToxic('postgres', {
  name: 'latency',
  type: 'latency',
  attributes: { latency: 500, jitter: 100 },
});

// Run load test
// Then check: Did connection pool handle the latency?
// Did timeouts fire correctly?
// Did the circuit breaker trip?
```

#### Chaos Scenarios to Test

| Scenario | What You're Testing | Inject |
|----------|---------------------|--------|
| Slow database | Connection pool, timeouts | 500ms+ latency |
| Database down | Circuit breaker, error handling | 100% failure rate |
| Slow external API | Timeout configuration | 2-5s latency |
| External API rate limiting | Retry with backoff | 429 responses |
| Network partition | Graceful degradation | Drop packets |
| High memory pressure | GC behavior, OOM handling | Memory limits |

### 6. CI/CD Integration

Run load tests in CI to catch performance regressions:

```yaml
# .github/workflows/performance.yml
name: Performance Tests

on:
  push:
    branches: [main]
  schedule:
    - cron: '0 2 * * *'  # Nightly

jobs:
  load-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Start services
        run: docker-compose up -d

      - name: Run load tests
        uses: grafana/k6-action@v0.3.1
        with:
          filename: load-tests/load.js
          flags: --out json=results.json
        env:
          BASE_URL: http://localhost:3000

      - name: Upload results
        uses: actions/upload-artifact@v4
        with:
          name: k6-results
          path: results.json
```

## Load Profiles at a Glance

| Profile | Goal | VU Pattern | Success Metric |
|---------|------|------------|----------------|
| **Smoke** | Correctness | Constant (1 VU) | 0% errors |
| **Load** | Normal capacity | Ramp to target | `http_req_duration` p95 < 500ms |
| **Stress** | Find breaking point | Continuous ramp | Identify first failures |
| **Soak** | Endurance | Steady for hours | Constant memory, no degradation |
| **Spike** | Burst handling | Sudden jump | Recovery within SLO |

## k6 Quick Reference

```bash
# Run load test
k6 run load-tests/load.js

# Run with custom config
k6 run --vus 50 --duration 5m load-tests/orders-api.js

# Run with environment variables
k6 run -e BASE_URL=https://staging.example.com load-tests/orders-api.js

# Output to JSON for analysis
k6 run --out json=results.json load-tests/load.js

# Output to InfluxDB for dashboards
k6 run --out influxdb=http://localhost:8086/k6 load-tests/load.js
```

## The Testing Pyramid Complete

```
       △
      /│\     Chaos Tests ("Does it survive failures?")
     / │ \    Load Tests ("Does it scale?")
    /--+--\
   /   │   \  Integration Tests ("Does the stack work?")
  /----+----\
       │    Unit Tests ("Does the logic work?")
```

Each layer catches different bugs. Each layer requires the one below to pass first.

## The Rules

1. **Test progressively** - Smoke → Load → Stress → Soak
2. **Set thresholds** - Tests should fail if SLOs aren't met
3. **Connect to traces** - Load + OpenTelemetry = finding real bottlenecks
4. **Run in CI** - Catch performance regressions before production
5. **Inject chaos** - Prove your resilience patterns actually work
6. **Use sleep() in k6** - Simulate realistic user think time, prevent accidental DDoS

## Common Pitfalls

### Forgetting sleep() in k6

Without `sleep()`, a single VU generates hundreds of requests per second—accidentally DDoS-ing your local machine. Always include think time:

```javascript
export default function () {
  const response = http.get(`${BASE_URL}/api/users/1`);
  check(response, { 'status is 200': (r) => r.status === 200 });
  
  sleep(1);  // Simulate user reading the page
}
```

### Testing Without Trace Correlation

You find a slow trace in Jaeger, but can't find the corresponding detailed logs. Always pass trace context from load tests:

```javascript
headers: {
  'traceparent': `00-${traceId}-${spanId}-01`,
  'x-load-test-id': __ENV.TEST_RUN_ID,
}
```

### Not Setting Realistic Thresholds

If thresholds are too strict, tests fail on normal variance. If too loose, they miss real problems. Start with your SLOs and adjust based on actual production metrics.

