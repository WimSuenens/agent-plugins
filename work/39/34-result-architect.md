# Result: architect — 39
Status: done
Progress:
  Done: start; newline fail-closed rule and worked example in contracts/39-plugin-scripts.md §2 (3c52259); result (this commit)
  Next: none
Summary:
  contracts/39-plugin-scripts.md §2 now carries the fail-closed rule the build (check-bump.sh `*$'\n'*` case) and the qa newline-* tests already hold: a changed path whose name contains a newline counts as standard work (minor bump), wherever it sits under plugins/factory/, scripts/ and hooks/ included.
  Added a worked example: a newline name under scripts/ bumped to 1.0.1 is refused with a minor suggestion (1.1.0), the path printed as is across two lines, which also covers the qa observation about two-line display.
  Nothing else in §2 changed. Nothing under plugins/ or tests/ touched.
Artifacts: contracts/39-plugin-scripts.md
Decisions:
  - Newline names fail closed as standard work everywhere under plugins/factory/ / rejected: classify by directory (patch under scripts/) / cost to undo: one contract line plus one case in check-bump.sh and its tests; the build already holds this, so the contract follows it.
  - Refusal prints a newline path as is (two lines), recorded in the example / rejected: require quoted or escaped display / cost to undo: a contract line and a printf change; the refusal itself is correct and the case is rare.
Open questions: none
