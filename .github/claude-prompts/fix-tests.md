# Task: Fix test failures

## Adapters to fix:
{{ADAPTERS}}

## Test failures by adapter:
{{ISSUES}}

## Release Notes URLs:
{{RELEASE_NOTES}}

## Instructions:
1. Read the test failures above carefully
2. For each adapter, fetch its Release Notes URL to understand API changes
3. Fix failing tests in each adapter's `Adapters/<AdapterName>/` directory
4. Ensure SwiftLint passes (e.g. replace unused closure parameters with `_`)
5. Commit and push changes for ALL adapters in ONE commit:
   ```bash
   rm -f deprecated_warnings.txt build_output.log test_failures.txt
   git add Adapters/*/
   git commit -m "fix: fix unit tests in <list adapters>"
   git push
   ```

## IMPORTANT:
- Fix ALL listed adapters in this task
- Only modify code under `Adapters/` directories
- Do NOT change `Podfile`, `Podfile.lock`, or core SDK code
- Focus on updating tests to match new API, not changing adapter implementation
- If you cannot fix a test, report what you found and continue with others
- Do NOT add "Generated with Claude Code" footer to commits
- Do NOT add "Co-Authored-By" line to commits
- Write descriptive commit message explaining what tests were fixed
