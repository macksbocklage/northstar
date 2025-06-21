# north star – PRD (Product Requirements Doc)

**goal**: create a minimalist ios app that helps users define 3 identity-level goals and align daily actions to them. designed for high-agency users who crave clarity, not dopamine loops.

---

## 0. TECH + SETUP

* **platform**: ios (swift + swiftui)
* **persistence**: coredata or cloudkit (later: icloud sync)
* **user onboarding**: local-first, no auth needed initially
* **design**: apple-style minimalist, glass ui vibes

---

## 1. ONBOARDING FLOW

**objective**: guide user to define their 3 pillars on first open

### steps:

1. welcome screen – app name + tagline
2. brief explanation of pillars (tooltip style)
3. user defines 3 *pillars* – short text inputs (identity-level goals)
4. optional sub-goal entry for each pillar (nested structure ui)
5. route to home screen (daily priorities)

---

## 2. CORE DATA MODEL

### entities:

* **Pillar**

  * `title`: string
  * `description`: optional string
  * `createdAt`: datetime

* **SubGoal**

  * `title`: string
  * `pillarId`: relation
  * `createdAt`: datetime

* **Task** (a daily action)

  * `title`: string
  * `date`: date
  * `pillarId`: optional relation
  * `subGoalId`: optional relation
  * `isCompleted`: bool

* **StreakTracker**

  * `pillarId`: relation
  * `currentStreak`: int
  * `lastCompletedDate`: date

---

## 3. HOME SCREEN (DAILY VIEW)

**default view: today’s priorities**

### components:

* **top bar**: date + optional mode switcher (for future feature)
* **daily top 3** task entry

  * input 3 priority actions (autocomplete for previous tasks)
  * optional: connect each to a pillar + sub-goal
* **completion toggle**: tap to mark complete
* **visual streaks** (colored dot per pillar if that day has task linked to it)
* **history access** (nav to past days)

---

## 4. PILLAR MANAGEMENT VIEW

**view + edit all 3 pillars**

### features:

* list of 3 pillars (always visible)
* tap into pillar → see:

  * description
  * all sub-goals
  * all past linked tasks (chronological)
* add / edit / remove sub-goals
* show streak (visual, not numeric-heavy)

---

## 5. HISTORY LOG

**view past daily top 3 entries**

* chronological list of past days
* each entry shows:

  * date
  * 3 tasks
  * which pillar (icon or label)
  * completion status
* swipe gestures to navigate day by day

---

## 6. STREAK ENGINE

**calculate streaks per pillar**

* for each day, check: was a task completed that links to this pillar?
* if yes, increment streak
* if not, reset streak
* visual: simple colored flame / line next to pillar title

---

## 7. ROADMAP FEATURES (DON’T BUILD YET)

* [ ] **mode selector**: user chooses between:

  * daily top 3
  * “one thing” mode
  * “kill list” mode
* [ ] **AI subtask suggestions**:

  * on entering sub-goals or tasks, suggest subtasks from LLM
* [ ] **drift detection**:

  * check if no task linked to a pillar in X days → notify
* [ ] **iCloud sync + backup**
* [ ] **timeline view**:

  * graph or timeline showing evolution of each pillar’s sub-goals + tasks
* [ ] **journaling field**:

  * optional daily reflection tied to priority list

---

## 8. UX PRINCIPLES

* frictionless input (keyboard always ready)
* no gamification, no badges
* everything maps to identity, not productivity
* user sees only what matters today

---

## 9. FUTURE EXPANSION (v2+ ideas)

* accountability partner sharing (see each other’s top 3)
* screen time lockout if top 3 not entered
* 7-day review summary: which pillar you moved most
* natural language input for task → auto-tag pillar