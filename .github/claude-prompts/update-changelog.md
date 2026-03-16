## Task: Update changelog for adapter dependency updates

### Adapters to update:
{{ADAPTERS}}

### Version changes:
{{VERSION_CHANGES}}

### Release Notes URLs:
{{RELEASE_NOTES}}

### AI fixes applied (if any):
{{AI_FIXES}}

### Instructions:

1. **Fetch and summarize release notes:**
   - For each adapter, fetch its Release Notes URL using WebFetch
   - Extract key changes relevant to the specific version being updated
   - Post a PR comment with release notes summary:
     ```markdown
     ## Release Notes Summary

     ### AdapterName (OLD_VERSION -> NEW_VERSION)
     - Key change 1
     - Key change 2
     - ...

     [Full release notes](URL)
     ```
   - If fetch fails: note in comment that release notes were unavailable, but continue with other tasks

2. **Update CHANGELOG.md:**
   - For each adapter, update `Adapters/<AdapterName>/CHANGELOG.md`
   - First, check git diff for the adapter to understand what was actually changed:
     ```bash
     git diff origin/{{BASE_BRANCH}} -- Adapters/<AdapterName>/
     ```
   - Find the topmost `## <version>` entry (already created by the updater script)
   - Add bullet points describing specific changes under the existing version header
   - **If AI fixed deprecated code**: Add SPECIFIC entries describing what was migrated, NOT generic "Migrated deprecated APIs". Examples:
     - `- Migrated from deprecated \`ALAdView(frame:size:sdk:)\` to \`ALAdView(size:)\``
     - `- Replaced deprecated \`setUserId()\` with \`setUserConsent()\``
     - `- Updated ad loading to use new \`load(request:)\` signature`
   - **If AI fixed build errors**: Describe the specific fix:
     - `- Fixed compilation error due to removed \`adDidClick()\` method`
     - `- Updated initializer parameters for \`BannerView\` class`
   - **If AI fixed tests**: Describe what was fixed:
     - `- Updated mock setup for changed \`AdDelegate\` protocol`
     - `- Fixed test assertions for new response format`

3. **Commit and push:**
   ```bash
   git add Adapters/*/CHANGELOG.md
   git commit -m "chore: update changelogs for dependency updates"
   git push
   ```

### IMPORTANT:
- Process ALL listed adapters
- Do NOT create new version headers -- append to the existing one
- Do NOT add "Generated with Claude Code" footer to commits
- Do NOT add "Co-Authored-By" line to commits
- NEVER use generic changelog entries like "Migrated deprecated APIs" -- always check the actual code changes and describe SPECIFICALLY what was migrated or fixed
