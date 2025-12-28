# Stride AI Agent Guidelines

> This document serves as the central orchestration file for AI agents working on the Stride codebase. It maps task types to specialized agent roles and ensures consistent, high-quality contributions.

---

## Overview

Stride is a deeply personal iOS task management app built with SwiftUI. When working on this codebase, AI agents should follow the guidelines in this file and defer to the appropriate role-specific agent file based on the task at hand.

---

## Agent Role Mapping

| Task Type | Agent File | Primary Responsibilities |
|-----------|------------|-------------------------|
| Architecture & System Design | [`agents/iOS_Lead.md`](agents/iOS_Lead.md) | Project structure, design patterns, performance, code review |
| Feature Implementation | [`agents/iOS_Dev.md`](agents/iOS_Dev.md) | UI components, view models, feature code, SwiftUI views |
| AI/ML & Backend | [`agents/Backend_AI.md`](agents/Backend_AI.md) | Prompt engineering, API integration, Core ML, data pipelines |
| Design & Motion | [`agents/Designer.md`](agents/Designer.md) | Animations, haptics, visual polish, UX patterns |
| Testing & Quality | [`agents/QA.md`](agents/QA.md) | Test strategy, test implementation, beta management |

---

## Task Routing Rules

Before starting any task, determine which agent role applies:

### Route to `iOS_Lead.md` when:
- Setting up project structure or folder organization
- Making architectural decisions (MVVM, navigation, DI)
- Designing new systems or engines (dependency graph, context engine)
- Reviewing or refactoring existing code
- Addressing performance issues
- Establishing coding conventions or patterns
- Working on Phase 0 or Phase 1 tasks
- Making decisions about third-party dependencies

### Route to `iOS_Dev.md` when:
- Building new UI screens or views
- Implementing SwiftUI components
- Writing view models
- Adding gestures or interactions
- Integrating with existing services
- Implementing feature logic
- Working on Phases 2-7 feature tasks

### Route to `Backend_AI.md` when:
- Designing or modifying AI prompts
- Integrating with OpenAI/Claude APIs
- Building the pattern learning system
- Working with Core ML models
- Implementing the context engine
- Processing natural language input
- Working on Phase 2 AI tasks or Phase 9

### Route to `Designer.md` when:
- Creating or refining animations
- Implementing haptic feedback
- Polishing visual appearance
- Designing micro-interactions
- Working on completion celebrations
- Ensuring 60fps performance for animations
- Working on Phase 7 or Phase 8 polish tasks

### Route to `QA.md` when:
- Writing unit tests
- Writing UI tests
- Setting up test infrastructure
- Managing beta releases
- Analyzing crash reports
- Performance testing
- Working on Phase 10 tasks

---

## Multi-Role Tasks

Some tasks span multiple roles. In these cases:

1. **Identify the primary role** - Which agent's expertise is most critical?
2. **Consult secondary roles** - Read relevant sections from other agent files
3. **Follow the primary role's patterns** - Use their conventions as the baseline
4. **Incorporate secondary concerns** - Layer in requirements from other roles

### Examples:

| Task | Primary | Secondary |
|------|---------|-----------|
| "Build the capture screen with AI parsing" | iOS_Dev | Backend_AI |
| "Add completion animation with sound" | Designer | iOS_Dev |
| "Optimize dependency graph performance" | iOS_Lead | QA |
| "Test the AI suggestion flow" | QA | Backend_AI |

---

## Universal Guidelines

All agents must follow these guidelines regardless of role:

### Code Style
```swift
// Use Swift conventions
// - camelCase for variables and functions
// - PascalCase for types
// - Clear, descriptive naming
// - Prefer composition over inheritance
```

### SwiftUI Patterns
```swift
// Views should be small and focused
struct TaskCard: View {
    let task: Task
    
    var body: some View {
        // Prefer extracted subviews for complexity
        VStack {
            TaskHeader(task: task)
            TaskContent(task: task)
        }
    }
}
```

### Documentation
- Document public interfaces
- Explain "why" not "what" in comments
- Keep README sections updated

### Git Practices
- Feature branches from `develop`
- Descriptive commit messages
- Small, focused commits

---

## Project Context

### Key Files to Understand

| File/Folder | Purpose |
|-------------|---------|
| `DEVELOPMENT_PLAN.md` | Full phased development roadmap |
| `Stride/Models/` | SwiftData models (Task, Subtask, etc.) |
| `Stride/Views/` | SwiftUI view components |
| `Stride/ViewModels/` | Observable view models |
| `Stride/Services/` | Business logic and API clients |
| `Stride/Engines/` | Core systems (DependencyGraph, Context, Scheduling) |

### Architecture Overview

```
UI Layer (SwiftUI Views)
    ↓
ViewModel Layer (@Observable classes)
    ↓
Service Layer (Actors, async/await)
    ↓
Data Layer (SwiftData, CloudKit)
```

### Key Design Principles

1. **Capture reality** - Preserve user's original input
2. **Remove friction** - Minimize steps to action
3. **Learn and adapt** - Use patterns to improve
4. **Feel alive** - Motion and animation matter
5. **Root for you** - Encouraging, not nagging

---

## Before Starting Work

1. **Read this file** - Understand the routing rules
2. **Read the appropriate agent file** - Get role-specific guidance
3. **Review `DEVELOPMENT_PLAN.md`** - Understand the current phase
4. **Explore existing code** - Match patterns already established
5. **Ask clarifying questions** - Don't assume; verify intent

---

## Agent Communication

When tasks require handoff between roles:

1. **Document decisions** - Leave clear comments explaining architectural choices
2. **Create interfaces first** - Define protocols before implementations
3. **Write tests** - QA agent should be able to verify your work
4. **Update documentation** - Keep DEVELOPMENT_PLAN.md current

---

## Quality Checklist

Before completing any task, verify:

- [ ] Code compiles without warnings
- [ ] Code follows project conventions
- [ ] New code has appropriate tests (or test plan)
- [ ] UI changes work on all supported device sizes
- [ ] Animations run at 60fps
- [ ] Accessibility is maintained
- [ ] No regression in existing functionality
- [ ] Documentation updated if needed

---

*For role-specific guidance, see the agent files in the `agents/` directory.*

