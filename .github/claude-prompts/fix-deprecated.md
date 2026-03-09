# Task: Fix deprecated code

## Adapters to fix:
{{ADAPTERS}}

## Deprecated warnings by adapter:
{{ISSUES}}

## Release Notes URLs:
{{RELEASE_NOTES}}

## Instructions:
1. Read the deprecated warnings above carefully
2. For each adapter, fetch its Release Notes URL to find migration guide
3. Fix deprecated code in each adapter's `Adapters/<AdapterName>/` directory
4. Ensure SwiftLint passes (e.g. replace unused closure parameters with `_`)
5. Commit and push changes for ALL adapters in ONE commit:
   ```bash
   rm -f deprecated_warnings.txt build_output.log
   git add Adapters/*/
   git commit -m "fix: migrate deprecated APIs in <list adapters>"
   git push
   ```

## IMPORTANT:
- Fix ALL listed adapters in this task
- Only modify code under `Adapters/` directories
- Do NOT change `Podfile`, `Podfile.lock`, or core SDK code
- If you cannot fix an adapter, report what you found and continue with others
- Do NOT add "Generated with Claude Code" footer to commits
- Do NOT add "Co-Authored-By" line to commits
- Write descriptive commit message listing what deprecated APIs were migrated
