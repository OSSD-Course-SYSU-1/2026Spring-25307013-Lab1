# InstantNote Development Guide

## Project Goal

InstantNote is a lightweight, modern, cross-platform note application.

Core principles:

- Simple
- Fast
- Native feeling
- Offline-first
- Cross-platform
- Beautiful UI
- Easy maintenance

The codebase should always remain clean, extensible and production-ready.

---

# Architecture Principles

Prefer:

- Modular architecture
- High cohesion
- Low coupling

Every feature should be independently maintainable.

Avoid giant files.

Avoid giant widgets/components.

Prefer composition over inheritance.

Avoid duplicated logic.

---

# UI Principles

Overall style:

- Minimal
- Flat
- Geometric
- Consistent spacing
- Material You inspired
- Fluent interaction

Avoid:

- Skeuomorphism
- Heavy shadows
- Fancy animations
- Emoji icons
- Inconsistent icon styles

Icons should use one consistent icon family.

---

# Responsive Design

Every page must support:

- Phone
- Tablet
- Desktop

Rules:

Phone

Single column

Tablet

Adaptive layout

Desktop

Two-column layout when appropriate

Never allow:

- Overflow
- Clipping
- Fixed width UI

Always use responsive constraints.

---

# Cross Platform

One codebase.

Target platforms:

- Android
- iOS
- Windows
- Linux
- macOS
- Web

Platform-specific implementations should be isolated.

Business logic must remain platform independent.

---

# Coding Style

Prefer:

Small functions

Small widgets/components

Readable names

Early return

Immutable data

Avoid:

Nested if

Long methods

Magic numbers

Repeated logic

Dead code

---

# Component Design

Components should be:

Reusable

Independent

Stateless whenever possible

Shared components belong in shared/.

Business components belong to their own module.

---

# State Management

Keep state localized.

Avoid global state unless necessary.

Business logic must not be inside UI components.

---

# Performance

Prefer:

Lazy loading

Memoization when appropriate

Virtual scrolling for large lists

Avoid unnecessary rebuilds/renders.

Optimize before adding complexity.

---

# Error Handling

Never silently ignore exceptions.

Every async operation should have:

Loading

Success

Failure

Empty state

---

# Accessibility

Support:

Keyboard navigation

Screen readers

Reasonable touch targets

Responsive font scaling

High contrast

---

# Network

Network should support:

Retry

Timeout

Offline mode

Graceful degradation

User-friendly error messages

---

# Feature Development Workflow

Every task follows:

1.

Understand requirement.

2.

Read related code.

3.

Design solution.

4.

Implement.

5.

Compile.

6.

Run tests.

7.

Fix compile errors.

8.

Fix lint errors.

9.

Self review.

10.

Architecture review.

11.

QA review.

12.

Refactor if necessary.

Repeat until satisfied.

---

# Self Review Checklist

Before finishing, verify:

[] No duplicated code

[] No dead code

[] No unused imports

[] No TODO left unintentionally

[] No magic numbers

[] No unnecessary comments

[] Naming is consistent

[] Folder structure is clean

[] Public APIs are reasonable

[] Performance is acceptable

[] UX is consistent

[] Responsive layout works

[] Dark mode works

[] Empty state works

[] Error state works

[] Loading state works

---

# QA Checklist

Test:

Phone

Tablet

Desktop

Portrait

Landscape

Very small screen

Very large screen

Dark mode

Light mode

Long text

Large data

Rapid interaction

Network failure

Offline mode

Unexpected inputs

---

# Architecture Review

Ask yourself:

Can this feature be simpler?

Can this module be reused?

Can this state be reduced?

Can this component be extracted?

Can this code be easier to understand?

Can future features build on this?

If the answer is yes,

Refactor.

---

# Completion Standard

A feature is NOT complete simply because it works.

It is complete only when:

- Production ready
- Readable
- Maintainable
- Extensible
- Responsive
- Cross-platform
- Reviewed
- Tested

Only then should work stop.