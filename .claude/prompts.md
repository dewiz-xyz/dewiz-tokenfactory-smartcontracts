# Custom Prompts for Dewiz Token Factory

This file contains reusable prompts for common tasks in this project.

## Security Analysis

```markdown
Run a comprehensive security analysis on the smart contracts:
1. Run Slither with --exclude-dependencies
2. Check for common vulnerabilities (reentrancy, access control, etc.)
3. Verify all external calls follow checks-effects-interactions
4. Review gas optimization opportunities
5. Provide a summary report
```

## Add New Token Feature

```markdown
Add a new feature to all token types (ERC20, ERC721, ERC1155):
1. Implement the feature in all three token contracts
2. Update the factory interfaces if needed
3. Add comprehensive tests for each token type
4. Update NatSpec documentation
5. Run all tests to ensure nothing breaks
6. Run Slither to check for new issues
```

## Create Compliance Hook

```markdown
Create a new compliance hook implementation:
1. Review IComplianceHook interface
2. Implement the hook with specific validation logic
3. Add comprehensive tests
4. Document gas implications
5. Provide example usage
```

## Deploy Checklist

```markdown
Pre-deployment checklist:
1. All tests passing
2. Slither analysis clean
3. Gas optimization review
4. Documentation complete
5. Access control verified
6. Constructor parameters validated
7. Deployment script tested
```

## Test Coverage

```markdown
Generate and analyze test coverage:
1. Run forge coverage
2. Identify uncovered lines
3. Add tests for uncovered code paths
4. Verify edge cases are tested
5. Report final coverage percentage
```

## Workflow Orchestration

### 1. Plan Mode Default

- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy

- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop

- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done

- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)

- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing

- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests - then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `.claude/lessons.md` after corrections

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
