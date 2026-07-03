# Security Scanner UI Redesign — AI Prompt

Copy and paste this into ChatGPT, Claude, or Gemini to generate a redesigned security guard UI.

---

```
You are a senior UI/UX designer specializing in mobile gate control and kiosk interfaces.
Design a complete UI redesign for the **security guard's mobile app** in a QR-based gate pass system called Quickpass.

## Context

A security guard stands at a company gate with a mobile phone. Employees approach and
hold up a QR code (blue for exit, green for entry) on their own phones. The guard scans it
to let them through. The guard may process 100+ people in a shift. Speed and accuracy are critical.

## Core Requirements

1. **Scanner is the default screen** — guard lives in the scanner, 90% of their time
2. **One-handed operation** — guard holds phone in one hand, other hand may hold a gate remote
3. **Auto-advance on success** — valid scan auto-dismisses after 1.5 seconds, no extra tap
4. **Error requires tap** — invalid scans stay on screen until guard taps "Try Again"
5. **Employee photo on result** — guard needs to match face to person before unlocking
6. **Audio feedback** — success chime, error buzz (guard can keep eyes on gate)
7. **Fast torch toggle** — large button in thumb zone (bottom-right) for glossy phone screens
8. **Gate status bar** — thin persistent top bar showing: OUT today / IN today / Currently inside
9. **Manual entry fallback** — long-press scan area to type employee ID (damaged QR fallback)
10. **Quick access to scan history** — accessible from scanner without leaving the flow
11. **No back button** — guard doesn't navigate away from scanner accidentally
12. **Role-based theme** — security screens should feel like a gate terminal (dark, high-contrast, big text), NOT like the employee app

## Visual Direction

- **Color palette:**
  - Background: very dark navy/slate (`#0B1121` or similar)
  - Surface: slightly lighter (`#1A2332`)
  - Accent for valid: bright green (`#22C55E`)
  - Accent for invalid: bright red (`#EF4444`)
  - Primary accent: bright blue (`#3B82F6`)
  - Text: white with high contrast
  - Subdued text: gray-blue (`#94A3B8`)
- **Typography:** Large, bold, legible from arm's length (18-24px body, 32-48px for status)
- **Scan frame:** Distinctive scanning area with animated corner brackets (not a generic square)
- **Icons:** Bold, filled style (not outlined), minimum 28px
- **Overall feel:** Industrial, authoritative, no-nonsense — think aviation dashboard or gate terminal

## Screens to Design (in order of importance)

### Screen 1: Scanner (Primary)
- Full-screen camera preview
- Scan frame overlay with animated corners
- Thin status bar at top (OUT: 47 | IN: 32 | Inside: 15)
- Large torch button bottom-right (thumb zone)
- Menu icon top-left (opens drawer with History, Logout)
- Manual entry trigger (long-press hint subtly shown)
- "Position QR in frame" instruction text
- OUT (blue) and IN (green) indicator showing which QR types are accepted

### Screen 2: Valid Scan Result (auto-dismiss)
- Large green checkmark
- Employee photo prominently displayed (circular, ~80px)
- Employee name (bold, large)
- Employee ID
- "EXIT" or "ENTRY" badge
- Time stamped
- Auto-dismisses in 1.5 seconds with progress ring
- Success chime

### Screen 3: Invalid Scan Result (requires tap)
- Large red X
- Reason for failure (e.g. "QR code expired", "Already scanned", "Invalid signature")
- Employee info shown if available (so guard can tell them why)
- "Try Again" button (large, easy to tap)
- Error buzz

### Screen 4: Scan History
- Simple list of today's scans
- Each row: photo thumbnail + employee name + time + OUT/IN badge + valid/invalid icon
- Searchable by employee name
- Pull down to refresh
- "Today" heading with timestamp

### Screen 5: Manual Entry (overlay)
- Keypad/dial pad for typing employee ID
- Large numeric buttons (like a phone dialer)
- Employee name appears as digits are typed (auto-suggest)
- "Scan" button to trigger validation

## What to Output

Generate 5 UI screens in a cohesive design:

1. Main scanner view (idle state)
2. Scanner with valid scan result overlay (success state)
3. Scanner with invalid scan result overlay (error state)
4. Scan history screen
5. Manual entry overlay

For each screen, describe:
- Layout and spacing (8px grid)
- Color usage
- Typography sizes and weights
- Touch targets (minimum 48px)
- Animation/micro-interaction notes
- Accessibility considerations (contrast, touch size, labels)

Make it feel like a purpose-built gate control terminal, not a generic mobile app.
```
