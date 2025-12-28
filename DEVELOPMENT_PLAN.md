# Stride Development Plan

> A deeply personal iOS task management app that facilitates meaningful action by removing friction between thought and completion.

---

## Table of Contents

1. [Phase 0: Project Setup & Architecture](#phase-0-project-setup--architecture-week-1)
2. [Phase 1: Data Foundation](#phase-1-data-foundation-weeks-2-3)
3. [Phase 2: Core Capture Experience](#phase-2-core-capture-experience-weeks-4-5)
4. [Phase 3: Card-Based UI & "Now" View](#phase-3-card-based-ui--now-view-weeks-6-8)
5. [Phase 4: Defer Intelligence & Focus Time](#phase-4-defer-intelligence--focus-time-weeks-9-10)
6. [Phase 5: Smart Scheduling & Calendar Integration](#phase-5-smart-scheduling--calendar-integration-weeks-11-12)
7. [Phase 6: Waiting & Aspirational Spaces](#phase-6-waiting--aspirational-spaces-weeks-13-14)
8. [Phase 7: Completion Experience & Retrospectives](#phase-7-completion-experience--retrospectives-weeks-15-16)
9. [Phase 8: Scope Creep Detection & Polish](#phase-8-scope-creep-detection--polish-weeks-17-18)
10. [Phase 9: Learning System & Personalization](#phase-9-learning-system--personalization-weeks-19-20)
11. [Phase 10: Testing, Refinement & Launch Prep](#phase-10-testing-refinement--launch-prep-weeks-21-24)

---

## Phase 0: Project Setup & Architecture (Week 1)

### 0.1 Development Environment
- Set up Xcode project with SwiftUI (primary) + UIKit (where needed for complex animations)
- Configure Swift Package Manager for dependencies
- Set up Git repository with branching strategy (main, develop, feature branches)
- Configure CI/CD (GitHub Actions or Fastlane)

### 0.2 Architecture Decisions
- **Pattern**: MVVM + Coordinators for navigation
- **Data Layer**: SwiftData (iOS 17+) or Core Data with CloudKit sync
- **Dependency Injection**: Use Swift's native approach or Swinject
- **Async**: Swift Concurrency (async/await, Actors)

### 0.3 Core Dependencies to Evaluate

| Need | Options |
|------|---------|
| AI/NLP | OpenAI API, Claude API, or on-device with Core ML |
| Voice | Apple Speech framework |
| Calendar | EventKit |
| Animations | SwiftUI + Custom physics engine |
| Haptics | Core Haptics |

### 0.4 Deliverables
- [ ] Xcode project initialized with folder structure
- [ ] SPM configured with initial dependencies
- [ ] Git repo with .gitignore and branch protection
- [ ] CI/CD pipeline running
- [ ] Architecture decision records (ADRs) documented

---

## Phase 1: Data Foundation (Weeks 2-3)

### 1.1 Core Data Models

```swift
// Task - Primary entity
Task {
    id: UUID
    rawInput: String          // Original brain dump preserved
    title: String             // Cleaned/parsed title
    notes: String
    energyLevel: EnergyLevel  // .low, .medium, .high
    estimatedMinutes: Int
    status: TaskStatus        // .active, .waiting, .deferred, .completed
    taskType: TaskType        // .obligation, .aspirational
    deferCount: Int
    completedAt: Date?
    createdAt: Date
    subtasks: [Subtask]
    dependencies: [TaskDependency]
    deferEvents: [DeferEvent]
}

// Subtask - Atomic action items
Subtask {
    id: UUID
    title: String
    isCompleted: Bool
    order: Int
    parentTask: Task
}

// TaskDependency - Blocker relationships
TaskDependency {
    blocker: Task
    blocked: Task
    type: DependencyType      // .hardBlock, .softBlock, .waiting
}

// DeferEvent - Learning from avoidance
DeferEvent {
    task: Task
    reason: DeferReason       // .blocked, .noEnergy, .wrongTime, .unsure, .notImportant
    timestamp: Date
    proposedTime: Date?
}

// UserPattern - Learned behavior model
UserPattern {
    dayOfWeek: Int
    hourOfDay: Int
    avgEnergyLevel: Float
    taskCompletionRate: Float
    preferredTaskTypes: [String]
}
```

### 1.2 Dependency Graph System
- Build a directed acyclic graph (DAG) for task dependencies
- Implement topological sorting for determining "next actionable" tasks
- Create blocking/unblocking cascade logic
- Cycle detection to prevent invalid dependencies

### 1.3 Local Persistence
- SwiftData schema with migrations strategy
- CloudKit sync for multi-device (optional in Phase 1)
- Offline-first architecture

### 1.4 Deliverables
- [ ] All SwiftData models implemented
- [ ] Dependency graph engine with unit tests
- [ ] CRUD operations for all entities
- [ ] Migration strategy documented
- [ ] Sample data seeding for development

---

## Phase 2: Core Capture Experience (Weeks 4-5)

### 2.1 Text Input
- Full-screen minimal capture UI
- Store raw input verbatim before any processing
- Quick-add from anywhere (widget, share extension)
- Keyboard-first experience with smart suggestions

### 2.2 Voice Input
- Apple Speech framework integration
- Real-time transcription display
- "Thinking..." state while processing
- Error handling for recognition failures

### 2.3 Basic AI Integration (v1)

**API Integration:**
- Connect to OpenAI/Claude API for task parsing
- Implement retry logic and error handling
- Cache responses for similar inputs

**Prompt Engineering:**
```
Given this brain dump: "{raw_input}"

Extract:
1. Primary task (one sentence)
2. Subtasks in order of execution
3. Dependencies/blockers mentioned
4. Estimated time (minutes)
5. Energy level (low/medium/high)
6. Context tags (phone, computer, errand, etc.)

Return as JSON.
```

**User Control:**
- User can accept, edit, or reject AI suggestions
- Manual override for all AI-generated fields
- Store AI outputs for pattern learning

### 2.4 Deliverables
- [ ] Capture screen UI implemented
- [ ] Text input with raw storage
- [ ] Voice transcription working
- [ ] AI service integrated
- [ ] Edit/accept flow for AI suggestions
- [ ] Share extension configured

---

## Phase 3: Card-Based UI & "Now" View (Weeks 6-8)

### 3.1 Task Card Component

**Visual Design:**
- Color-coded left border (green/yellow/red for energy)
- Title + first subtask preview
- Progress ring for multi-step tasks
- Context icons (📞 calls, ⏰ time-sensitive, ⏳ waiting)

**Size Variations:**
- Large: High do-ability score, immediate action
- Medium: Standard presentation
- Small: Lower priority, collapsed view

### 3.2 "Now" View Algorithm (v1)

```swift
func calculateDoabilityScore(task: Task) -> Float {
    var score: Float = 0
    
    // Recency boost (newer = higher)
    score += recencyBoost(task.createdAt)
    
    // Energy matching
    if currentEnergyLevel() == task.energyLevel {
        score += 20
    }
    
    // Quick win bonus (< 5 min tasks)
    if task.estimatedMinutes < 5 {
        score += 15
    }
    
    // Dependency-free bonus
    if task.dependencies.isEmpty {
        score += 25
    }
    
    // Deadline proximity boost
    if let deadline = task.deadline {
        score += deadlineProximityBoost(deadline)
    }
    
    // Defer penalty (increases with defer count)
    score -= Float(task.deferCount) * 5
    
    // Exclude waiting tasks
    if task.status == .waiting {
        return -1000
    }
    
    return score
}

// Return top 3-5 by score
func getNowTasks() -> [Task] {
    return allActiveTasks
        .map { ($0, calculateDoabilityScore($0)) }
        .sorted { $0.1 > $1.1 }
        .prefix(5)
        .map { $0.0 }
}
```

### 3.3 Gestures & Interactions
- Swipe right → Complete (with haptic + animation)
- Swipe left → Defer (show reason picker)
- Tap → Expand to full breakdown view
- Long press → Quick actions menu (edit, delete, waiting, etc.)

### 3.4 Animation Foundation
- Physics-based spring animations (SwiftUI `.spring()`)
- Card entrance/exit choreography with staggered delays
- Completion celebration (glow effect, particle burst)
- Smooth reordering when list changes

### 3.5 Deliverables
- [ ] TaskCard component with all variants
- [ ] "Now" view with algorithm
- [ ] Swipe gestures implemented
- [ ] Full task breakdown view
- [ ] Basic animations working
- [ ] Haptic feedback integrated

---

## Phase 4: Defer Intelligence & Focus Time (Weeks 9-10)

### 4.1 Defer Flow

**Quick Reason Selection:**
- 🚫 Blocked - Something is preventing this
- 😴 No energy - Not in the right state
- ⏰ Wrong time - Bad timing
- 🤔 Unsure how to start - Need clarity
- 🤷 Not important right now - Deprioritize

**Defer Actions:**
- Quick time picker for "remind me later"
- Snooze presets (1 hour, tonight, tomorrow, next week)
- Track all defer events with timestamp and reason

### 4.2 Pattern Detection

```swift
struct PatternInsight {
    let taskType: String
    let avgDeferCount: Float
    let bestTimeOfDay: Int
    let worstTimeOfDay: Int
    let commonBlockers: [String]
}

func analyzePatterns(for tasks: [Task]) -> [PatternInsight] {
    // Group by task characteristics
    // Analyze completion vs defer patterns
    // Identify time-of-day correlations
    // Surface blockers that repeat
}
```

**Pattern Examples:**
- "User rarely completes phone calls after 6pm"
- "Shopping tasks usually complete within 24 hours"
- "Work tasks deferred on weekends"

### 4.3 Focus Time Intervention

**Trigger Conditions:**
- Task deferred 5+ times
- High-priority task stuck for 7+ days
- Multiple tasks blocked by same item

**Intervention Flow:**
1. Modal appears: "You've pushed this 6 times. Let's figure out why."
2. AI-powered micro-breakdown: "What's the smallest first step?"
3. Show downstream impact: "This is blocking X and Y"
4. Calendar scan: "You have 20 free minutes Thursday at 2pm"
5. User can: Commit to time slot, break down further, or mark as "not doing"

### 4.4 Deliverables
- [ ] Defer flow with reason picker
- [ ] DeferEvent persistence and tracking
- [ ] Pattern detection algorithms
- [ ] Focus Time modal UI
- [ ] AI micro-breakdown integration
- [ ] Downstream impact visualization

---

## Phase 5: Smart Scheduling & Calendar Integration (Weeks 11-12)

### 5.1 EventKit Integration
- Request calendar read access (graceful degradation if denied)
- Parse existing events for free/busy patterns
- Identify recurring availability windows
- Respect calendar privacy (no event content storage)

### 5.2 Context-Aware Notifications

**Time-Based Triggers:**
- Gap detection: "You have 5 minutes before your next meeting—quick win?"
- Pattern matching: "Sunday morning is usually your admin time. 3 tasks ready."

**Energy-Based Triggers (Learned):**
- Morning (high energy detected): Suggest high-energy tasks
- Post-lunch (low energy detected): Suggest low-energy tasks
- Evening (variable): Match to learned patterns

**Notification Principles:**
- **No location-based prompts** per PRD
- Respect Do Not Disturb
- Limit to 3-5 notifications per day maximum
- Allow snooze without opening app

### 5.3 Flexible Recurring Tasks

```swift
struct RecurringRule {
    let frequency: Int           // e.g., 3 times
    let period: Period          // .week, .month
    let windowStart: Date
    let windowEnd: Date
    let preferredDays: [Int]?   // Optional day preferences
}

// Example: "Exercise: 3x per week, Mon-Sun, prefer mornings"
```

**Negotiation Logic:**
- System suggests optimal times based on history
- Visual indicator of "window closing" as deadline approaches
- Rollover handling (missed vs completed)

### 5.4 Deliverables
- [ ] EventKit integration with permission handling
- [ ] Free/busy analysis
- [ ] Notification scheduling system
- [ ] Recurring task model and UI
- [ ] Window visualization
- [ ] Notification preferences screen

---

## Phase 6: Waiting & Aspirational Spaces (Weeks 13-14)

### 6.1 "Ball in Their Court" System

**Waiting State:**
- Mark task as waiting with:
  - Contact name (who you're waiting on)
  - Expected response time (auto-suggest based on context)
  - Follow-up message template
  - Original request summary

**Follow-up Logic:**
```swift
struct WaitingConfig {
    static let businessFollowUp = 2...3  // days
    static let personalFollowUp = 5...7  // days
    static let urgentFollowUp = 1        // day
}
```

**Auto-Surface:**
- When follow-up window opens, task appears in "Now" view
- One-tap "send follow-up" with pre-drafted message
- Track follow-up count

### 6.2 Aspirational Task Space

**Separate Treatment:**
- Distinct tab/section for desire-driven goals
- Different visual treatment (softer colors, no urgency indicators)
- Never appears in main "Now" view unless surplus detected

**Onboarding Probes:**
- "When would you love this done?"
- "Why does it matter to you?"
- "What changes when this is complete?"

**Surfacing Logic:**
```swift
func shouldSurfaceAspirational() -> Bool {
    let recentCompletions = getCompletionsLast24Hours()
    let pendingObligations = getPendingObligations()
    let currentEnergy = estimateCurrentEnergy()
    
    return recentCompletions >= 5 
        && pendingObligations.count < 3
        && currentEnergy == .high
}
```

**Design Principles:**
- Never creates notifications
- No guilt-inducing language
- Optional and exploratory feel
- Celebrates when touched, doesn't nag when ignored

### 6.3 Deliverables
- [x] Waiting status UI and flow
- [x] Follow-up reminder system
- [x] Message template generation
- [x] Aspirational task section
- [x] Onboarding probes flow
- [x] Surplus detection algorithm

---

## Phase 7: Completion Experience & Retrospectives (Weeks 15-16)

### 7.1 Completion Moments

**Micro-Completion (Subtask):**
- Haptic tick (light impact)
- Subtle checkmark animation
- Progress ring updates

**Task Completion:**
- Haptic success pattern
- Celebratory animation (glow, particle burst, card exit)
- "Nice!" toast with task summary
- Progress streak update

**Cascade Visualization:**
- When completing a blocker, show newly unblocked tasks
- Animation: blocked tasks "flow in" from edges
- Message: "Completing this unblocked 3 more tasks!"

**Streak Tracking:**
```swift
struct StreakData {
    let tasksToday: Int
    let tasksBestToday: Int
    let currentDayStreak: Int
    let longestDayStreak: Int
    let weeklyAverage: Float
}
```

### 7.2 Sound Design

**Audio Principles:**
- Subtle, satisfying, non-cartoonish
- Different tones for different completion types
- Respect system silent mode
- User can customize or disable

**Sound Mapping:**
- Subtask: Soft click
- Task complete: Gentle chime
- Streak milestone: Layered tone
- Focus time complete: Achievement flourish

### 7.3 Weekly Retrospective

**Trigger:**
- Sunday evening prompt (time configurable)
- Also accessible on-demand

**Content:**
- Tasks completed this week (grouped by type)
- Defer patterns analysis
- Time invested by category (estimated)
- Patterns discovered
- Cascade effects achieved
- Encouragement based on progress

**UI:**
- Full-screen immersive experience
- Animated data visualizations
- Shareable summary card (optional)

### 7.4 Deliverables
- [x] Completion animation system
- [x] Haptic feedback patterns
- [x] Sound design integration
- [x] Cascade visualization
- [x] Streak tracking UI
- [x] Weekly retrospective screen
- [x] Retrospective scheduling

---

## Phase 8: Scope Creep Detection & Polish (Weeks 17-18)

### 8.1 Scope Creep Detection

**Monitoring Points:**
- Task edit session starts → snapshot current state
- Detect during edit:
  - Subtasks added (count increase)
  - Time estimate increased
  - New dependencies added
  - Description significantly expanded

**Threshold Logic:**
```swift
func detectScopeCreep(original: Task, edited: Task) -> ScopeCreepResult? {
    let subtaskDelta = edited.subtasks.count - original.subtasks.count
    let timeDelta = edited.estimatedMinutes - original.estimatedMinutes
    
    if subtaskDelta >= 2 || timeDelta >= 15 {
        return ScopeCreepResult(
            addedMinutes: timeDelta,
            addedSubtasks: subtaskDelta,
            suggestion: .split
        )
    }
    return nil
}
```

**Intervention UI:**
- Task card visually "expands" as warning (subtle animation)
- Modal interrupt: "This now adds 30 minutes. Want to keep focused, split, or replace?"
- Options:
  - **Keep**: Accept expanded scope
  - **Split**: Create new task with additions
  - **Revert**: Undo expansion

### 8.2 Haptic Refinement

**Core Haptics Mapping:**
| Action | Haptic Pattern |
|--------|----------------|
| Swipe gesture | Light impact |
| Scroll snap | Soft impact |
| Defer tap | Medium impact |
| Card expand | Selection change |
| Complete task | Success notification |
| Error/warning | Error notification |
| Focus time start | Heavy impact |

### 8.3 Animation Polish

**Audit Checklist:**
- [ ] All view transitions at 60fps
- [ ] No animation jank on older devices
- [ ] Consistent spring parameters across app
- [ ] Loading states have skeleton/shimmer
- [ ] Empty states have subtle motion
- [ ] Card reordering is smooth
- [ ] Keyboard appearance/dismissal is smooth

**Micro-Animations:**
- Typing indicators in capture
- AI "thinking" animation
- Card shuffle on algorithm update
- Progress ring fill animation
- Icon state transitions

### 8.4 Deliverables
- [ ] Scope creep detection system
- [ ] Expansion warning UI
- [ ] Split task flow
- [ ] Haptic feedback audit complete
- [ ] Animation performance audit
- [ ] 60fps verification on target devices

---

## Phase 9: Learning System & Personalization (Weeks 19-20)

### 9.1 Persistent Learning Model

**On-Device ML Approach:**
- Use Create ML for model training
- Core ML for inference
- Weekly model retraining (background, on-device)

**Features Tracked:**
```swift
struct UserBehaviorFeatures {
    let hourOfDay: Int
    let dayOfWeek: Int
    let taskEnergyLevel: EnergyLevel
    let taskType: TaskType
    let estimatedMinutes: Int
    let deferCountBefore: Int
    let wasCompleted: Bool
    let timeToComplete: TimeInterval?
}
```

**Model Outputs:**
- Completion probability for task at given time
- Optimal time slots for task types
- Energy level prediction by time
- Defer likelihood prediction

### 9.2 Context Engine

**Inputs:**
- Current time and day
- Recent task completions (last 2 hours)
- Calendar state (free, busy, just finished meeting)
- Historical patterns
- Current defer streak

**Outputs:**
- Estimated energy level (0-100)
- Task prioritization weights
- Notification timing decisions
- "Now" view composition

**Engine Architecture:**
```swift
actor ContextEngine {
    func getCurrentContext() async -> UserContext
    func predictEnergy(at time: Date) async -> Float
    func rankTasks(_ tasks: [Task]) async -> [RankedTask]
    func shouldNotify(for task: Task) async -> Bool
}
```

### 9.3 Personal Context Learning

**Context Examples:**
- "You usually order contacts from 1-800 Contacts"
- "Prescription renewals for you take ~48 hours"
- "You prefer to do errands on Saturday mornings"

**Learning Approach:**
- Extract entities from completed tasks
- Build personal knowledge graph
- Auto-apply learned context to similar new tasks
- User can view and edit learned context

### 9.4 Deliverables
- [ ] Behavior feature collection
- [ ] Create ML model definition
- [ ] On-device training pipeline
- [ ] Context engine implementation
- [ ] Personal context storage
- [ ] Context learning UI (view/edit)
- [ ] A/B testing framework

---

## Phase 10: Testing, Refinement & Launch Prep (Weeks 21-24)

### 10.1 Testing Strategy

**Unit Tests:**
- Dependency graph operations
- Scoring algorithm edge cases
- Pattern detection accuracy
- Data model validations
- Context engine logic

**Integration Tests:**
- AI service integration
- Calendar sync
- Notification delivery
- CloudKit sync

**UI Tests:**
- Capture flow end-to-end
- Gesture recognition
- Animation completion
- Accessibility compliance

**Performance Tests:**
- Large task lists (500+ items)
- Complex dependency graphs
- Animation frame rates
- Memory usage over time
- Battery consumption

### 10.2 Beta Program

**TestFlight Setup:**
- Internal testing group (team)
- External beta group (50-100 users)
- Staged rollout

**Feedback Collection:**
- In-app feedback button
- Crash reporting (integrate Sentry or similar)
- Analytics events for feature usage
- Optional session recording

**Metrics to Track:**
- Task completion rate
- Defer patterns
- Feature adoption
- Session duration
- Retention (D1, D7, D30)
- AI suggestion acceptance rate

### 10.3 Launch Preparation

**App Store Assets:**
- App icon (all sizes)
- Screenshots (6.5", 5.5", iPad)
- App preview video (30 seconds)
- Feature graphic

**Content:**
- App Store description (short + long)
- Keywords optimization
- Privacy policy
- Terms of service
- Support URL and FAQ

**Onboarding:**
- First-run experience (3-5 screens)
- Permission requests with context
- Sample task to learn gestures
- AI feature opt-in

### 10.4 Deliverables
- [ ] Test suite with >80% coverage
- [ ] Performance benchmarks documented
- [ ] Beta program launched
- [ ] Feedback incorporated
- [ ] App Store assets complete
- [ ] Legal documents ready
- [ ] Onboarding flow polished
- [ ] Launch checklist complete

---

## Technical Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                             │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────────┐ │
│  │   Now   │  │ Capture │  │ Waiting │  │   Aspirational  │ │
│  │  View   │  │  View   │  │  View   │  │      View       │ │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────────┬────────┘ │
└───────┼────────────┼────────────┼────────────────┼──────────┘
        │            │            │                │
┌───────┴────────────┴────────────┴────────────────┴──────────┐
│                     ViewModel Layer                         │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────────┐   │
│  │ TaskListVM  │  │  CaptureVM   │  │ RetrospectiveVM   │   │
│  └──────┬──────┘  └──────┬───────┘  └─────────┬─────────┘   │
└─────────┼────────────────┼────────────────────┼─────────────┘
          │                │                    │
┌─────────┴────────────────┴────────────────────┴─────────────┐
│                     Service Layer                           │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌──────────┐  │
│  │ AI Service │ │ Scheduling │ │  Pattern   │ │ Calendar │  │
│  │  (OpenAI)  │ │   Engine   │ │  Learner   │ │ Service  │  │
│  └─────┬──────┘ └─────┬──────┘ └─────┬──────┘ └────┬─────┘  │
└────────┼──────────────┼──────────────┼─────────────┼────────┘
         │              │              │             │
┌────────┴──────────────┴──────────────┴─────────────┴────────┐
│                      Data Layer                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │    SwiftData    │  │ Dependency Graph │  │  CloudKit   │  │
│  │   (Local DB)    │  │     Engine       │  │   (Sync)    │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## MVP Definition

**Target: Week 8** — First usable version for internal testing

| Feature | MVP | Full |
|---------|-----|------|
| Text capture with raw storage | ✅ | ✅ |
| Basic AI parsing & subtasks | ✅ | ✅ |
| Card-based task list | ✅ | ✅ |
| Swipe to complete/defer | ✅ | ✅ |
| "Now" view (simple algorithm) | ✅ | ✅ |
| Basic animations & haptics | ✅ | ✅ |
| Voice capture | ❌ | ✅ |
| Calendar integration | ❌ | ✅ |
| Focus Time intervention | ❌ | ✅ |
| Pattern learning | ❌ | ✅ |
| Aspirational space | ❌ | ✅ |
| Weekly retrospective | ❌ | ✅ |
| Scope creep detection | ❌ | ✅ |

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| AI latency hurts UX | High | Optimistic UI updates; background processing; cache common patterns |
| Over-reliance on AI API | High | Build fallback manual mode; explore on-device models |
| Animation performance | Medium | Profile early; use Metal-backed animations if needed |
| Scope creep (meta) | Medium | Strict phase gates; MVP-first mentality |
| Privacy concerns | High | On-device processing where possible; clear data policies |
| Calendar permission denied | Low | Graceful degradation; manual time entry fallback |

---

## Success Metrics

### Engagement
- Daily active users (DAU)
- Tasks created per user per day
- Task completion rate (>60% target)
- Session duration

### Quality
- AI suggestion acceptance rate (>70% target)
- Defer-to-complete ratio
- App Store rating (>4.5 target)
- Crash-free sessions (>99.5%)

### Retention
- D1: 60%
- D7: 40%
- D30: 25%

---

## Team Roles

| Role | Responsibility | Phase Focus |
|------|----------------|-------------|
| iOS Lead | Architecture, SwiftUI, performance | 0, 1, 3, 8 |
| iOS Dev | Feature implementation, UI components | 2-7 |
| Backend/AI | Prompt engineering, API integration, ML | 2, 4, 9 |
| Designer | Motion design, visual polish, UX | 3, 7, 8 |
| QA | Testing strategy, beta management | 10 |

---

*Last Updated: December 2024*

