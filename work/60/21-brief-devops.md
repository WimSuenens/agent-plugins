# Brief: devops — 60
Goal: Delivery for release 1.3.0 of the factory: make sure the release path works and the runbook is right. Nothing is deployed.
Inputs: docs/factory/release-runbook.md; docs/adr/0012 and 0013; plugins/factory/scripts/check-bump.sh and fingerprint.sh; contracts/60-standard-changes.md (release section); work/60/20-result-security.md and 19-result-qa.md; docs/agents/factory.md; tracker issue 60; the PR for item/60.
Constraints:
- You own pipeline, scripts and runbooks outside plugins/ (docs/factory/release-runbook.md). Do not edit plugins/, tests/, CHANGELOG or README.
- Change the runbook only where 1.3.0 needs it (the standard fingerprint, v5 records, a timing line only if a measure moved; none is expected). Say "no change needed" if so.
- Verify without installing: check-bump.sh against origin/main (exit 0), the fingerprints equal to the QA-quoted values (standard d146280132f3ad44339ec587ae5ecc93c4b9a4ebf00db4bff5ce5837da256068, tooling 295033f4e6c6fcc69a2ceb6caf71968c5cc3fb233a92f6bd074fffaff2423ff5), tag factory-v1.3.0 does not exist yet (git ls-remote --tags origin), plugin.json version is a plain MAJOR.MINOR.PATCH. The tag is made by the Lead by hand after the merge; do not tag, push, merge, or install, and do not run /plugin marketplace update or /reload-plugins (the run is frozen on install 9147301f75c3). No production action.
- No absolute home paths in any committed file. Commits "#60 devops:".
Output: runbook edit if any; result in work/60/22-result-devops.md (Status: working at start). Include the exact post-merge steps the Lead will run for the tag.
Done: the checks above quoted with their outputs; runbook current or "no change needed"; post-merge tag steps listed.
