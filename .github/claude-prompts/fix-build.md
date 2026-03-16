## Task: Fix build errors

### Adapters to fix:
{{ADAPTERS}}

### Build errors by adapter:
{{ISSUES}}

### Release Notes URLs:
{{RELEASE_NOTES}}

### Instructions:
1. Read the build errors above carefully
2. For each adapter, fetch its Release Notes URL to find API changes and migration guide
3. Fix build errors in each adapter's `Adapters/<AdapterName>/` directory
4. Build each adapter to verify fix:
   ```bash
   xcodebuild build \
     -workspace BidOn.xcworkspace \
     -scheme BidonAdapter<AdapterName> \
     -destination 'generic/platform=iOS Simulator'
   ```
5. Run SwiftLint to format code:
   ```bash
   ./lint
   ```
6. Commit and push changes for ALL adapters in ONE commit:
   ```bash
   rm -f build_output.log
   git add Adapters/*/
   git commit -m "fix: resolve build errors in <list adapters>"
   git push
   ```

### IMPORTANT:
- Fix ALL listed adapters in this task
- Only modify code under `Adapters/` directories
- Do NOT change `Podfile`, `Podfile.lock`, or core SDK code
- Focus on fixing compilation errors caused by SDK API changes
- If you cannot fix an adapter, report what you found and continue with others
- Do NOT add "Generated with Claude Code" footer to commits
- Do NOT add "Co-Authored-By" line to commits
- Write descriptive commit message explaining what was fixed
