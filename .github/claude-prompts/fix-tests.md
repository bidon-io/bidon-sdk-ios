## Task: Fix test failures

### Adapters to fix:
{{ADAPTERS}}

### Test failures by adapter:
{{ISSUES}}

### Release Notes URLs:
{{RELEASE_NOTES}}

### Instructions:
1. Read the test failures above carefully
2. For each adapter, fetch its Release Notes URL to understand API changes
3. Fix failing tests in each adapter's `Tests/AdaptersTests/` directory
4. Run adapter tests to verify:
   ```bash
   xcodebuild test \
     -workspace BidOn.xcworkspace \
     -scheme AdaptersTests \
     -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'
   ```
5. Run SwiftLint to format code:
   ```bash
   ./lint
   ```
6. Commit and push changes for ALL adapters in ONE commit:
   ```bash
   rm -f deprecated_warnings.txt build_output.log test_failures.txt
   git add Adapters/*/ Tests/*/
   git commit -m "fix: fix unit tests in <list adapters>"
   git push
   ```

### IMPORTANT:
- Fix ALL listed adapters in this task
- Only modify code under `Adapters/` and `Tests/` directories
- Do NOT change `Podfile`, `Podfile.lock`, or core SDK code
- Focus on updating tests to match new API, not changing adapter implementation
- If you cannot fix a test, report what you found and continue with others
- Do NOT add "Generated with Claude Code" footer to commits
- Do NOT add "Co-Authored-By" line to commits
- Write descriptive commit message explaining what tests were fixed
