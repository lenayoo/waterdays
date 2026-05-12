# Water Days – REFACTOR.md

Read AGENTS.md first.

IMPORTANT:
Do NOT redesign the entire app.
Keep the current Water Days identity and overall direction.

The current version already has a good emotional tone and simplicity.
This update should feel like a refined Version 2, not a completely different app.

Maintain:

* existing layout philosophy
* current emotional feeling
* simple and calm UI
* current branding direction

Focus on improving usability and adding small but meaningful features.

Avoid:

* dramatic redesigns
* dashboard-style UI
* overcomplicated layouts
* excessive animations
* AI-generated looking design

---

# RELEASE GOAL

This release focuses on:

1. Stability improvements
2. Better daily tracking experience
3. Monthly consistency visualization
4. Android widget support
5. Smart reminder notifications

---

# 1. BUG FIX — DAILY RESET

Current issue:
Water count does not reliably reset when the day changes.

Requirements:

* Use local system time.
* Automatically reset daily water count to 0 when the date changes.
* Must work even if:

  * app is closed
  * app is in background
  * device restarts
* Prevent duplicate resets.
* Keep previous daily records saved correctly.

Do not break existing history data.

---

# 2. CALENDAR FEATURE

Add a lightweight monthly calendar feature.

Requirements:

* Support:

  * English
  * Japanese
  * Korean

* Calendar should match the current Water Days design style.

* Keep the UI:

  * compact
  * soft
  * minimal
  * easy to understand

Daily status indicators:

* Blue dot:
  user achieved daily water goal

* Red dot:
  user did not achieve daily water goal

The calendar should help users visually understand consistency at a glance.

Avoid:

* large heavy calendar UI
* complicated interactions
* excessive text

---

# 3. MONTHLY RECORD BUTTON

Add a small monthly record button at the top-right corner.

Requirements:

* small and subtle
* should not dominate the screen
* clean icon preferred
* should naturally fit into the existing layout

Pressing the button opens the monthly calendar/history screen.

---

# 4. ANDROID WIDGET SUPPORT

Add Android home widget support.

Widget should display:

* today's water amount
* goal progress
* quick add action

Design direction:

* simple
* clean
* readable
* similar feeling to iOS widget

Do not overcrowd the widget UI.

---

# 5. SMART PUSH NOTIFICATION

Add a reminder notification system.

Timing:

* Send notification 4 hours before the next day begins
* Use local system time

Example:
If the daily reset happens at 00:00,
send reminder around 20:00.

Only send notification if:

* user has NOT achieved today's goal

Notification tone should feel:

* warm
* gentle
* encouraging
* human

Avoid:

* pressure
* guilt
* robotic language

Example direction:

"You're doing great today 💧"

"You've had XX cups today."
"Only XX more cups left to reach your goal."

"Small progress still counts 🌱"

Support:

* English
* Japanese
* Korean

---

# IMPORTANT

This is NOT a full redesign.

This release should feel like:

* cleaner
* more stable
* slightly more polished
* more complete

while still feeling like the original Water Days app.

Prioritize:

* emotional simplicity
* calm UX
* lightweight feeling
* consistency
* stability
