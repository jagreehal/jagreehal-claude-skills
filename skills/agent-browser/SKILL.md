---
name: agent-browser
description: "Browser automation for web testing, form filling, screenshots, and data extraction. Ref-based workflow with best practices for reliable automation."
version: 1.1.0
---

# Browser Automation with agent-browser

Automate browser interactions using a ref-based workflow. Navigate, snapshot, interact, repeat.

## Installation

```shell
npm install -g agent-browser
agent-browser install              # Download Chromium
agent-browser install --with-deps  # Linux: install system deps
```

## Quick Start

```shell
agent-browser open <url>          # Navigate to page
agent-browser snapshot -i         # Get interactive elements with refs
agent-browser click @e1           # Click element by ref
agent-browser fill @e2 "text"     # Fill input by ref
agent-browser close               # Close browser
```

## Core Workflow

1. **Navigate**: `agent-browser open <url>`
2. **Snapshot**: `agent-browser snapshot -i` (returns elements with refs like `@e1`, `@e2`)
3. **Interact**: Use refs from the snapshot
4. **Re-snapshot**: After navigation or significant DOM changes

---

## Command Reference

### Navigation

```shell
agent-browser open <url>          # Navigate to URL
agent-browser back                # Go back
agent-browser forward             # Go forward
agent-browser reload              # Reload page
agent-browser close               # Close browser
```

### Snapshot (Page Analysis)

```shell
agent-browser snapshot            # Full accessibility tree
agent-browser snapshot -i         # Interactive elements only (recommended)
agent-browser snapshot -c         # Compact output
agent-browser snapshot -d 3       # Limit depth to 3
agent-browser snapshot -s "#main" # Scope to selector (large pages)
```

### Interactions (Use @refs)

```shell
agent-browser click @e1           # Click
agent-browser dblclick @e1        # Double-click
agent-browser fill @e2 "text"     # Clear and type
agent-browser type @e2 "text"     # Type without clearing
agent-browser press Enter         # Press key
agent-browser press Control+a     # Key combination
agent-browser hover @e1           # Hover
agent-browser check @e1           # Check checkbox
agent-browser uncheck @e1         # Uncheck checkbox
agent-browser select @e1 "value"  # Select dropdown option
agent-browser scroll down 500     # Scroll page
agent-browser scrollintoview @e1  # Scroll element into view
agent-browser drag @e1 @e2        # Drag from source to target
agent-browser upload @e1 file.pdf # Upload file to input
```

### Get Information

```shell
agent-browser get text @e1        # Get element text
agent-browser get value @e1       # Get input value
agent-browser get html @e1        # Get element HTML
agent-browser get attr @e1 href   # Get attribute value
agent-browser get title           # Get page title
agent-browser get url             # Get current URL
```

### State Checking (Assertions)

```shell
agent-browser is visible @e1      # Check if visible
agent-browser is enabled @e1      # Check if enabled
agent-browser is checked @e1      # Check if checked
```

### Screenshots

```shell
agent-browser screenshot          # Screenshot to stdout
agent-browser screenshot path.png # Save to file
agent-browser screenshot --full   # Full page screenshot
```

### Wait

```shell
agent-browser wait @e1            # Wait for element
agent-browser wait 2000           # Wait milliseconds (avoid)
agent-browser wait --text "Done"  # Wait for text to appear
agent-browser wait --load networkidle  # Wait for network idle
```

### Semantic Locators (Alternative to Refs)

```shell
agent-browser find role button click --name "Submit"
agent-browser find text "Sign In" click
agent-browser find label "Email" fill "user@test.com"
```

### Sessions (Parallel Browsers)

```shell
agent-browser --session test1 open site-a.com
agent-browser --session test2 open site-b.com
agent-browser session list
```

### State Management

```shell
agent-browser state save auth.json   # Save auth/cookies
agent-browser state load auth.json   # Restore state
```

### Debugging

```shell
agent-browser open example.com --headed  # Show browser window
agent-browser console                    # View console messages
agent-browser errors                     # View page errors
```

### Viewport & Emulation

```shell
agent-browser set viewport 1920 1080     # Set viewport size
agent-browser set device "iPhone 14"     # Emulate device
agent-browser set media dark             # Emulate dark mode
agent-browser set geo 37.7749 -122.4194  # Set geolocation
agent-browser set offline on             # Enable offline mode
agent-browser set offline off            # Disable offline mode
```

### Storage & Cookies

```shell
agent-browser cookies                    # List all cookies
agent-browser cookies set name value     # Set cookie
agent-browser cookies clear              # Clear all cookies
agent-browser storage local              # List localStorage
agent-browser storage local get key      # Get localStorage item
agent-browser storage local set key val  # Set localStorage item
agent-browser storage session            # List sessionStorage
```

### Network Interception

```shell
agent-browser network requests           # List network requests
agent-browser network route "**/api/*"   # Intercept matching URLs
agent-browser network route "**/api/*" --abort        # Block requests
agent-browser network route "**/api/*" --body '{"mock":true}'  # Mock response
```

### Headers & Auth

```shell
agent-browser open api.example.com --headers '{"Authorization": "Bearer token"}'
agent-browser set headers '{"X-Custom": "value"}'
```

### JSON Output

```shell
agent-browser snapshot -i --json    # Machine-readable output
agent-browser get text @e1 --json   # For programmatic parsing
```

---

## Best Practices

### Snapshots

- MUST: Re-snapshot after any navigation or DOM mutation
- MUST: Use `snapshot -i` (interactive only) to reduce noise
- MUST: Re-snapshot after clicks that trigger page changes
- NEVER: Cache refs across page navigations—refs are invalidated
- NEVER: Assume refs persist after form submissions or route changes

### Selectors

- SHOULD: Prefer `@refs` from snapshot over semantic locators
- MUST: Fall back to semantic locators when refs are unstable (dynamic content)
- NEVER: Use brittle CSS selectors or XPath directly
- SHOULD: Use `find role` + `--name` for buttons/links when refs fail

### Waits

- MUST: Wait for `networkidle` after form submissions
- MUST: Use `wait --text "..."` or `wait @ref` for dynamic content
- NEVER: Use fixed `wait 2000`—flaky and slow
- SHOULD: Set reasonable timeouts; fail fast on missing elements

### Forms

- MUST: Use `fill` (clears first) for inputs, not `type`
- MUST: Verify submission with `wait --text` or `wait --url`
- SHOULD: Snapshot after each step in multi-page flows
- MUST: Handle validation errors—check for error text after submit

### State & Auth

- MUST: Save auth state after login for reuse (`state save`)
- MUST: Load state before navigating to authenticated pages
- NEVER: Commit auth state files to version control
- SHOULD: Use separate state files per environment (dev/staging/prod)

### Screenshots

- MUST: Use `screenshot --full` for pages with scroll
- SHOULD: Take screenshots before and after critical actions
- MUST: Use explicit file paths in CI/CD pipelines

### Sessions

- SHOULD: Use named sessions for parallel browser testing
- MUST: Close sessions explicitly when done
- NEVER: Mix refs across different sessions

### Error Handling

- MUST: Check `errors` output when interactions fail silently
- SHOULD: Use `console` to debug JavaScript issues
- MUST: Re-snapshot and retry once before failing
- SHOULD: Use `--headed` mode when debugging complex flows

### Performance

- MUST: Close browser when done (`close`)
- SHOULD: Reuse sessions for multiple tests on same domain
- NEVER: Open new browser for each small interaction
- SHOULD: Use `snapshot -c` (compact) for large pages
- SHOULD: Use `snapshot -s "#scope"` to limit snapshot to relevant DOM

### Assertions

- MUST: Use `is visible` before interacting with dynamic elements
- MUST: Use `is enabled` before clicking buttons that may be disabled
- SHOULD: Combine `is visible` + `wait` for elements that appear async

### Responsive Testing

- MUST: Set viewport before navigation, not after
- SHOULD: Use device presets for consistent mobile testing
- MUST: Re-snapshot after viewport changes—layout affects refs

### Network & Mocking

- SHOULD: Use `network route --abort` to test offline behavior
- SHOULD: Use `network route --body` to mock API responses in tests
- MUST: Set up routes before navigating to the page
- NEVER: Leave network intercepts active across unrelated tests

### Storage

- SHOULD: Use `cookies clear` between test scenarios
- MUST: Check `storage local` when debugging auth issues
- SHOULD: Use storage commands to set up test preconditions

---

## Examples

### Form Submission

```shell
agent-browser open https://example.com/form
agent-browser snapshot -i
# Output: textbox "Email" [ref=e1], textbox "Password" [ref=e2], button "Submit" [ref=e3]

agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3
agent-browser wait --load networkidle
agent-browser snapshot -i  # Verify result
```

### Login with State Persistence

```shell
# First time: login and save
agent-browser open https://app.example.com/login
agent-browser snapshot -i
agent-browser fill @e1 "username"
agent-browser fill @e2 "password"
agent-browser click @e3
agent-browser wait --url "**/dashboard"
agent-browser state save auth.json

# Later: load state and skip login
agent-browser state load auth.json
agent-browser open https://app.example.com/dashboard
# Already authenticated
```

### Multi-Step Wizard

```shell
agent-browser open https://example.com/wizard

# Step 1
agent-browser snapshot -i
agent-browser fill @e1 "John Doe"
agent-browser click @e2  # Next button
agent-browser wait --text "Step 2"

# Step 2 - MUST re-snapshot after navigation
agent-browser snapshot -i
agent-browser select @e1 "Option B"
agent-browser click @e2  # Next button
agent-browser wait --text "Step 3"

# Step 3
agent-browser snapshot -i
agent-browser check @e1  # Terms checkbox
agent-browser click @e2  # Submit
agent-browser wait --text "Success"
```

### Screenshot Comparison

```shell
agent-browser open https://example.com
agent-browser screenshot before.png --full
# ... make changes ...
agent-browser screenshot after.png --full
```

### Responsive Testing

```shell
# Test mobile viewport
agent-browser set device "iPhone 14"
agent-browser open https://example.com
agent-browser snapshot -i
agent-browser screenshot mobile.png --full

# Test desktop
agent-browser set viewport 1920 1080
agent-browser reload
agent-browser snapshot -i  # Re-snapshot after viewport change
agent-browser screenshot desktop.png --full
```

### API Mocking

```shell
# Set up mock before navigation
agent-browser network route "**/api/users" --body '[{"id":1,"name":"Test User"}]'
agent-browser open https://example.com/dashboard
agent-browser snapshot -i
# Page shows mocked data

# Test error handling
agent-browser network route "**/api/users" --abort
agent-browser reload
agent-browser wait --text "Failed to load"
```

### File Upload

```shell
agent-browser open https://example.com/upload
agent-browser snapshot -i
# Output: file input [ref=e1], button "Upload" [ref=e2]

agent-browser upload @e1 /path/to/document.pdf
agent-browser click @e2
agent-browser wait --text "Upload complete"
```

---

## Integration

| Skill | Relationship |
|-------|--------------|
| `testing-strategy` | E2E test patterns |
| `react-development` | Testing React UIs |
| `storybook-journeys` | Visual testing workflows |
