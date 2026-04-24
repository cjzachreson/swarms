# Collaboration Preferences

## File Access Restrictions

## Collaboration & Editing (from .continue rules)
- **Implement one change at a time**; stop and confirm before next
- **Before edits**: outline plan + alternatives, explain fit, ask *"May I proceed?"*
- **Minimal diffs**: use targeted changes, summarize edits, update/add tests
- **No batching** or exceeding agreed scope without approval
- **Ask clarifying questions early** for ambiguous requirements, schema/API/test changes
- **Stop immediately** if asked

## Communication Style
- **Ask before assuming**: If unsure about approach or next steps, ask rather than guess
- **Explain before implementing**: Describe your planned approach before making changes
- **Respect pacing requests**: If I ask you to slow down or stop, follow that instruction immediately
- **Concise planning**: Begin with brief Plan (≤5 bullets, ≤10 words each): goal, constraints, files, scope, tests

## Development Approach (aligned with `.continue` rules)
- **Favor simple, elegant solutions**; preserve behavior during refactors
- **After edits**: run/suggest quick syntax/runtime checks
- **Test incrementally**: isolate components, use test functions (avoid scoping pitfalls)
- **Reuse helpers** e.g. in `WardDynamics/test/_setup/` or `TransmissionDynamics/experiments/init_test.jl` for consistent setup
- **Make tests deterministic** via config seeds, not global state
- **⚠️ NO EXIT COMMANDS**: Never use `exit()`, `quit()`, `sys.exit()`, `process.exit()` - use returns/errors
- **⚠️ AVOID BROAD TRY-CATCH**: Include full stack info if needed; avoid during development debugging 

## Project Context  
This project is about creating swarm simulations that respond to audio or audio-visual input signals. The basic logic is 2D standard-vicsek-model with some modifications that will be added for interesting visual dynamics (adhesion, repulsion, trail-following, vortexing, etc.). This will be developed as a julia package. 

---

**Quick Start Reminder**: 
- Step-by-step implementation, wait for feedback between changes
- Ask questions before assumptions, test incrementally  
- Always ask *"May I proceed with these changes"* before code modifications
- Stop and ask if you run into unexpected problems 

**Style Guide**
Try not to be overly enthusiastic when responding to prompts - overuse of exclamations like 'Perfect!' or 'Excellent!' should be avoided. You can respond with 'Thank you' after I answer a question for you, or just a simple acknowledgement that you've processed my prompt ('OK.' or 'Right.'). Also, try not to complement me too much - it gets annoying, and it can make me overconfident in my choices - I would prefer a more constructively critical approach, remember that I can make mistakes and may misunderstand you at times.

**Tips**

[User Note] Note that Copilot gets very confused when data in external files like CSVs doesn't get parsed into the types it's code is expecting. 

[User Note] On VS Code in Windows, the terminal integration is not good, so Copilot appears impatient when waiting for terminal output, and will often jump to the conclusion that something has gone wrong when it's just taking a bit more time than expected, or it's lost visibility of the terminal output. This can probably be fixed - need to figure out shell integration (note this has not been a problem in Linux using Bash)

[User Note] Make sure to slow down the pace during debugging because copilot will start introducing ad-hoc fixes and end up with layers upon layers of buggy code to fix bugs that weren't there or were trivial. The solution to this is to slow down and do some systematic manual debugging. 

[User Note] A NOTE about reading terminal output: Copilot can get confused if multiple terminals are running simultaneously in VS Code (at least in Windows). It will try to look at terminal output by using the command get_terminal_output - this can accidentally read the wrong one and can *sometimes* confuse the AI. To avoid this, use get_terminal_last_command instead; this will examine the terminal output for the terminal ID that Copilot has been using to run commands. 

**Testing** 
- **Prefer test functions** to avoid Julia scoping pitfalls
- **Reuse helpers** in `test/_setup/` for consistent dependency/path navigation
- **Deterministic tests** via config seeds, not global state
- **Implement as functions**: return key metrics/outputs as tuple elements for easy consolidation
- **Test incrementally**: isolate components when possible
- Both packages (WardDynamics, TransmissionDynamics) implemented with full package structure

**Documentation** 
- **Write for new contributors**; avoid jargon and code-specific shorthand
- **Keep docstrings clear and fold-friendly** (see docstring style below)
- **Note doc/example changes** when delivering code updates
- **Avoid verbosity**: plans are for reference, not repetition in chat

For example, avoid jargon-heavy checklists

**AI Assistant Memory**
[User Note]
if you see the notification: "summarizing conversation history" or similar this means you're working with a compressed context that may have lost important information. It may be necessary to refresh context from worklogs, plans, and reports. 


**Worklogs and Context Refresh**

## Refresh Triggers
- Run at session start, on "refresh context" commands, or after compressing context

## Refresh Process  
1. Starting from most recent worklog, scan backward until latest `## [Plan ...]` is found
2. **Stop scanning after this Plan is located**
3. Read only that Plan and checkpoints that follow it
4. Extract: overview, current goal/scope, todos, decisions/invariants, active files/modules/configs, blockers, status, branch+SHA
5. Summarize as **Session Context** (5-8 bullets)
6. Present for confirmation; **no code edits during refresh**

## Worklog Updates
- Add checkpoint every 5 tool calls, >3 edits, or on decisions/scope changes
- Use today's worklog (`docs/worklogs/WORKLOG-YYYY-MM-DD.md`), create from template if missing
- **Append-only**: newest entries first, do not edit existing checkpoints unless explicitly asked

## Checkpoint Entries
- Must be **concise**: ≤8 bullets, ≤15 words each
- Include: timestamp (Australia/Sydney), branch+SHA, goal/scope, todos, decisions, files changed, status, next steps, blockers
- Record "no changes" + timestamp if nothing new
- If advancing a Plan, state: "Progress on Plan <ID>, Step Sx" with acceptance criteria if relevant 


## Checkpoint Template
```md
## [Checkpoint YYYY-MM-DD HH:MM TZ | branch | abc1234]
- Goal/scope: …
- Active todos: …
- Decisions/assumptions/invariants: …
- Files changed since last checkpoint: …
- Status: Build PASS | Tests n/n PASS | Notes: …
- Next 1–2 steps: …
- Open questions/blockers: …
##
```

## Grep Patterns for Worklogs
- Plans: `^## \[Plan`
- Checkpoints: `^## \[Checkpoint`

Helpful commands for initiating worklogs: 
powershell: 
     - identify current repo: git --no-pager rev-parse --abbrev-ref HEAD
     - current commit: git --no-pager rev-parse --short HEAD
     - date and timezone (IANA label in header): "$((Get-Date).ToString('yyyy-MM-dd HH:mm')) Australia/Sydney"

Before making any changes to code, check precompilation: 
powershell: 
     1) Ensures all dependencies from Project.toml/Manifest.toml are installed:
          julia -q --project=. -e "import Pkg; Pkg.instantiate()"
     2) Precompile dependencies: 
          julia -q --project=. -e "using Pkg; Pkg.precompile()"
     3) check the package loads: 
          julia --% -q --project=. -e "using WardDynamics; println(\"Precompile OK\")"

Helpful commands for running unit tests in the test/temp folder: 
powershell: 
     julia -q --project=. -e "using Test; include(joinpath(\"test\", \"temp\", \"test_schedule_reader_smoke.jl\")); println(\"test complete\")"

Linux/bash equivalents:

- Worklog helpers:
  - Repo branch: git --no-pager rev-parse --abbrev-ref HEAD
  - Commit: git --no-pager rev-parse --short HEAD
  - Timestamp (IANA label in header): echo "$(TZ=Australia/Sydney date '+%Y-%m-%d %H:%M') Australia/Sydney"

- Precompile and sanity-load:
  - julia -q --project=. -e 'import Pkg; Pkg.instantiate()'
  - julia -q --project=. -e 'using Pkg; Pkg.precompile()'
  - julia -q --project=. -e 'using WardDynamics; println("Precompile OK")'

- Run a temp test:
  - julia -q --project=. -e 'using Test; include(joinpath("test","temp","test_schedule_reader_smoke.jl")); println("test complete")'

- Full test suite:
  - julia -e 'using Pkg; Pkg.activate("."); Pkg.test()'

## Working documentation structure
 - <repo-root>\docs\ contains \plans, \reports, and \worklogs
 - \plans is for ad-hoc documentation of large-scale workplans, guided by the user, recoreded as \plans\PLAN_*.md
 - \reports is for finalising summary documentation after the plans recorded in \plans are completed, recorded as \reports\REPORT_*.md
 - \worklogs is for automatic checkpoint entry (which can include planning checkpoints - these can detail expansions of the documented steps recorded in \plans, recorded as per instructions above)

## Style notes
**Docstring Style**
Indentation should facilitate code folding: 
```julia
     """
     is_dashdot_line_object(obj::SVGElement)

          Check if an SVG element has dash-dot line styling (alternating long/short pattern).

          # Arguments
          - `obj::SVGElement`: The SVG element to check

          # Returns
          - `Bool`: True if the element has dash-dot line styling

          # Examples
          
          # Dash-dot patterns (4+ values with alternating long/short)
          stroke-dasharray="5,2,1,2"        # long, gap, short, gap
          stroke-dasharray="4,1,2,1"        # long, gap, short, gap  
          stroke-dasharray="6,3,1,3"        # long, gap, short, gap
          
     """
```
so it folds to: 
```julia
     """
     is_dashdot_line_object(obj::SVGElement)
     """
``` 