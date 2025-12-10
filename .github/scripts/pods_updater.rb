#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require 'rubygems/version'

TRUNK_BASE = 'https://trunk.cocoapods.org/api/v1/pods'

POD_TO_ADAPTER = {
  'AmazonPublisherServicesSDK' => ['BidonAdapterAmazon'],
  'AppLovinSDK'               => ['BidonAdapterAppLovin', 'AppLovinMediationBidonAdapter'],
  'BidMachine'                => ['BidonAdapterBidMachine'],
  'Google-Mobile-Ads-SDK'     => ['BidonAdapterGoogleMobileAds', 'BidonAdapterGoogleAdManager'],
  'BigoADS'                   => ['BidonAdapterBigoAds'],
  'Fyber_Marketplace_SDK'     => ['BidonAdapterDTExchange'],
  'FBAudienceNetwork'         => ['BidonAdapterMetaAudienceNetwork'],
  'UnityAds'                  => ['BidonAdapterUnityAds'],
  'MintegralAdSDK'            => ['BidonAdapterMintegral'],
  'MolocoSDKiOS'              => ['BidonAdapterMoloco'],
  'VungleAds'                 => ['BidonAdapterVungle'],
  'MobileFuseSDK'             => ['BidonAdapterMobileFuse'],
  'InMobiSDK'                 => ['BidonAdapterInMobi'],
  'myTargetSDK'               => ['BidonAdapterMyTarget'],
  'ChartboostSDK'             => ['BidonAdapterChartboost'],
  'IronSourceSDK'             => ['BidonAdapterIronSource', 'ISBidonCustomAdapter'],
  'YandexMobileAds'           => ['BidonAdapterYandex'],
  'TaurusxAdsSDK'             => ['BidonAdapterTaurusX'],
  'StartAppSDK'               => ['BidonAdapterStartIo']
}.freeze

def repo_slug
  ENV.fetch('GITHUB_REPOSITORY')
end

def github_token
  ENV.fetch('GITHUB_TOKEN')
end

def git_push_token
  # Prefer PAT for git pushes (to generate events outside GITHUB_TOKEN),
  # but fall back to GITHUB_TOKEN if PAT is not provided.
  ENV['PODS_UPDATER_TOKEN'].to_s.empty? ? github_token : ENV['PODS_UPDATER_TOKEN']
end

def default_branch
  # Base branch for PRs, override via env (e.g., 'dev')
  ENV['PODS_BASE_BRANCH'] || 'dev'
end

def http_get_json(url)
  uri = URI(url)
  req = Net::HTTP::Get.new(uri)
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
    resp = http.request(req)
    raise "HTTP #{resp.code} for #{url}" unless resp.is_a?(Net::HTTPSuccess)
    JSON.parse(resp.body)
  end
end

def semver_key(v)
  v.to_s.split(/[\.\-]/).map { |p| p =~ /^\d+$/ ? p.to_i : p }
end

def read_lock_versions(lock_path)
  versions = {}
  return versions unless File.exist?(lock_path)
  in_pods = false
  sanitize = proc do |raw|
    v = raw.to_s.strip
    v = v.sub(/^~>\s*/, "").sub(/^>=\s*/, "").sub(/^<=\s*/, "").sub(/^==\s*/, "").sub(/^=\s*/, "")
    v.gsub(/[^0-9A-Za-z\.\-]/, "")
  end
  File.foreach(lock_path) do |line|
    if line.start_with?("PODS:")
      in_pods = true
      next
    end
    if in_pods && line.match?(/^[A-Z][A-Z ]+:/)
      in_pods = false
    end
    next unless in_pods
    next unless line.start_with?("  - ")
    entry = line.sub(/^  - /, "").strip
    name, ver = entry.split(" (", 2)
    next unless name && ver
    v = ver.to_s.delete(")").strip
    v = sanitize.call(v)
    versions[name] = v if v.match(/^\d/)
  end
  versions
end

def adapter_revision(adapter_name)
  dir = File.join("Adapters", adapter_name)
  candidates = Dir.glob(File.join(dir, "**", "*DemandSourceAdapter.swift"))
  return "0" if candidates.empty?
  begin
    content = File.read(candidates.first)
    m = content.match(/adapterVersion\s*:\s*String\s*=\s*"(\d+)"/)
    return m[1] if m
  rescue => e
    warn "Could not read adapterVersion from #{candidates.first}: #{e}"
  end
  "0"
end

def compute_adapter_version(adapter_name, pod_name, sdk_version_hint)
  lock_versions = read_lock_versions("Podfile.lock")
  root = pod_name.to_s.split('/').first
  base = lock_versions[pod_name] || lock_versions[root] || sdk_version_hint
  rev  = adapter_revision(adapter_name)
  "#{base}.#{rev}"
end

def parse_podfile_entries
  src = File.read('Podfile')
  entries = []
  src.each_line.with_index(1) do |line, ln|
    if line =~ /^\s*pod\s+["']([^"']+)["']\s*(?:,\s*["']([^"']+)["'])?/
      name = Regexp.last_match(1)
      ver  = Regexp.last_match(2)
      entries << { line_no: ln, name: name, version: ver }
    end
  end
  entries
end

def exact_version?(s)
  return false if s.nil? || s.empty?
  !!(s =~ /^\d+(\.\d+)*$/)
end

def trunk_versions_for(pod)
  # Trunk API is keyed by the root pod (without subspec path).
  root = pod.to_s.split('/').first
  begin
    data = http_get_json("#{TRUNK_BASE}/#{URI.encode_www_form_component(root)}")
  rescue => e
    # Gracefully skip pods not present in Trunk (e.g., private pods) or 404 for subspecs
    if e.message.include?('HTTP 404')
      warn "Skip #{pod}: not found in Trunk"
      return []
    end
    raise
  end
  versions = (data['versions'] || []).map { |x| x['name'] }.compact.uniq
  versions.sort_by { |v| Gem::Version.new(v) }
end

def add_labels(issue_number, labels)
  owner, repo = repo_slug.split('/', 2)
  uri = URI("https://api.github.com/repos/#{owner}/#{repo}/issues/#{issue_number}/labels")
  req = Net::HTTP::Post.new(uri)
  req['Authorization'] = "Bearer #{github_token}"
  req['Accept'] = 'application/vnd.github+json'
  req.body = { labels: labels }.to_json
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
end

def add_comment(issue_number, body)
  owner, repo = repo_slug.split('/', 2)
  uri = URI("https://api.github.com/repos/#{owner}/#{repo}/issues/#{issue_number}/comments")
  req = Net::HTTP::Post.new(uri)
  req['Authorization'] = "Bearer #{github_token}"
  req['Accept'] = 'application/vnd.github+json'
  req.body = { body: body }.to_json
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
end

def replace_pod_version_in_podfile(pod, to_version)
  src = File.read('Podfile')
  changed = false
  new_src = src.gsub(/^(\s*pod\s+["']#{Regexp.escape(pod)}["'])\s*(?:,\s*["']([^"']+)["'])?/) do
    prefix = Regexp.last_match(1)
    changed = true
    %(#{prefix}, '#{to_version}')
  end
  raise "Pod '#{pod}' not found in Podfile" unless changed
  File.write('Podfile', new_src)
end

def update_adapter_changelog(adapter_name, pod_name, sdk_version_hint)
  path = File.join("Adapters", adapter_name, "CHANGELOG.md")
  unless File.exist?(path)
    warn "CHANGELOG not found for #{adapter_name} (#{path})"
    return
  end

  adapter_ver = compute_adapter_version(adapter_name, pod_name, sdk_version_hint)
  content = File.read(path)
  # Skip if this version already documented
  return if content.include?("## #{adapter_ver}")

  lines = content.lines
  idx = lines.index { |l| l.start_with?("# Changelog") } || 0
  insert_at = idx + 1

  # Normalize whitespace after "# Changelog": remove any existing blank lines
  while lines[insert_at]&.strip&.empty?
    lines.delete_at(insert_at)
  end

  block = []
  # Exactly one blank line after "# Changelog"
  block << "\n"
  # Header line with no extra blank before bullet
  block << "## #{adapter_ver}\n"
  # Single bullet immediately after header
  root = pod_name.to_s.split('/').first
  lock_versions = read_lock_versions("Podfile.lock")
  sdk_ver = lock_versions[pod_name] || lock_versions[root] || sdk_version_hint
  block << "* Updated to #{pod_name} #{sdk_ver}\n"
  # Trailing blank line for spacing
  block << "\n"

  lines.insert(insert_at, *block)
  File.write(path, lines.join)
rescue => e
  warn "Failed to update CHANGELOG for #{adapter_name}: #{e}"
end

def run_pods_tests
  sh!(<<~'BASH')
    # Do not use -u here to avoid failing on unset env vars in older shells
    set -eo pipefail
    echo "Selecting iOS Simulator runtime via simctl…"
    RUNTIME_ID=$(xcrun simctl list runtimes -j \
      | jq -r '[.runtimes[] | select((.availability?=="(available)" or .isAvailable==true) and (.identifier|test("iOS"))) | .identifier] | sort | last')
    if [ -z "${RUNTIME_ID:-}" ] || [ "$RUNTIME_ID" = "null" ]; then
      echo "No available iOS simulator runtime found";
      xcrun simctl list runtimes || true;
      exit 1;
    fi
    echo "Using runtime: $RUNTIME_ID"
    DEST_ID=$(xcrun simctl list devices -j \
      | jq -r --arg rid "$RUNTIME_ID" '((.devices[$rid] // []) | map(select(.isAvailable==true)) | map(.udid) | .[0])')
    if [ -z "${DEST_ID:-}" ] || [ "$DEST_ID" = "null" ]; then
      echo "No device under $RUNTIME_ID, falling back to any available device";
      DEST_ID=$(xcrun simctl list devices -j \
        | jq -r '[.devices[] | .[] | select(.isAvailable==true) | .udid][0]')
    fi
    if [ -z "${DEST_ID:-}" ] || [ "$DEST_ID" = "null" ]; then
      echo "No available iOS Simulator device";
      xcrun simctl list devices || true;
      exit 1;
    fi
    DD="${GITHUB_WORKSPACE:-$PWD}/DerivedData"
    mkdir -p "$DD" Result build/reports || true
    echo "Running AdaptersTests on Simulator id=$DEST_ID…"
    xcodebuild test \
      -workspace BidOn.xcworkspace \
      -scheme AdaptersTests \
      -sdk iphonesimulator \
      -destination "id=$DEST_ID" \
      -derivedDataPath "$DD" \
      -resultBundlePath Result/AdaptersTests.xcresult \
      | tee build/reports/pods_tests.log \
      | xcbeautify
  BASH
end

def sh!(cmd)
  puts ">> #{cmd}"
  ok = system(cmd)
  raise "Command failed: #{cmd}" unless ok
end

def git_reset_to_default
  sh!("git fetch origin #{default_branch}")
  sh!("git checkout -B #{default_branch} origin/#{default_branch}")
  sh!("git reset --hard origin/#{default_branch}")
  sh!("git clean -fd")
end

def git_push_branch(branch)
  owner, repo = repo_slug.split('/', 2)
   if ENV['PODS_UPDATER_TOKEN'].to_s.empty?
     puts '>> git_push: using GITHUB_TOKEN'
   else
     puts '>> git_push: using PODS_UPDATER_TOKEN'
   end
  remote = "https://x-access-token:#{git_push_token}@github.com/#{owner}/#{repo}.git"
  # First attempt with force-with-lease (safer)
  ok = system("git push -u #{remote} HEAD:#{branch} --force-with-lease")
  unless ok
    # If lease fails due to stale info, refresh and force push
    system("git fetch origin #{branch}") # ignore result
    sh!("git push -u #{remote} HEAD:#{branch} --force")
  end
end

def create_pr(branch, title, body, labels: %w[dependencies cocoapods])
  owner, repo = repo_slug.split('/', 2)
  uri = URI("https://api.github.com/repos/#{owner}/#{repo}/pulls")
  payloads = [
    { title: title, head: branch, base: default_branch, body: body, maintainer_can_modify: true },
    { title: title, head: "#{owner}:#{branch}", base: default_branch, body: body, maintainer_can_modify: true }
  ]
  pr = nil
  last_resp = nil
  created = false
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    payloads.each do |pl|
      req = Net::HTTP::Post.new(uri)
      req['Authorization'] = "Bearer #{github_token}"
      req['Accept'] = 'application/vnd.github+json'
      req.body = pl.to_json
      resp = http.request(req)
      last_resp = resp
      if resp.is_a?(Net::HTTPSuccess)
        pr = JSON.parse(resp.body)
        created = (resp.code.to_s == '201')
        break
      end
    end
  end
  # If PR already exists (422), locate it and proceed to labeling/reviewers
  if pr.nil? && last_resp && last_resp.code.to_s == '422'
    list_uri = URI("https://api.github.com/repos/#{owner}/#{repo}/pulls?head=#{owner}%3A#{branch}&base=#{default_branch}&state=open")
    list_req = Net::HTTP::Get.new(list_uri)
    list_req['Authorization'] = "Bearer #{github_token}"
    list_req['Accept'] = 'application/vnd.github+json'
    list_prs = nil
    Net::HTTP.start(list_uri.host, list_uri.port, use_ssl: true) do |http|
      list_resp = http.request(list_req)
      if list_resp.is_a?(Net::HTTPSuccess)
        arr = JSON.parse(list_resp.body)
        pr = arr.first if arr.is_a?(Array) && !arr.empty?
      end
    end
    puts ">> Found existing PR for #{branch}: ##{pr['number']}" if pr
  end
  raise "PR create failed: #{last_resp&.code} #{last_resp&.body}" unless pr
  # Add labels
  issues_uri = URI("https://api.github.com/repos/#{owner}/#{repo}/issues/#{pr['number']}/labels")
  lab_req = Net::HTTP::Post.new(issues_uri)
  lab_req['Authorization'] = "Bearer #{github_token}"
  lab_req['Accept'] = 'application/vnd.github+json'
  lab_req.body = { labels: labels }.to_json
  Net::HTTP.start(issues_uri.host, issues_uri.port, use_ssl: true) { |http| http.request(lab_req) }

  # Optionally request reviewers if PODS_REVIEWERS provided (comma-separated).
  reviewers_csv = ENV['PODS_REVIEWERS'].to_s.strip
  unless reviewers_csv.empty?
    users = []
    teams = []
    reviewers_csv.split(',').map(&:strip).each do |entry|
      if entry.include?('/')
        teams << entry.split('/', 2).last
      elsif !entry.empty?
        users << entry
      end
    end
    if users.any? || teams.any?
      rr_uri = URI("https://api.github.com/repos/#{owner}/#{repo}/pulls/#{pr['number']}/requested_reviewers")
      rr_req = Net::HTTP::Post.new(rr_uri)
      rr_req['Authorization'] = "Bearer #{github_token}"
      rr_req['Accept'] = 'application/vnd.github+json'
      rr_req.body = { reviewers: users, team_reviewers: teams }.to_json
      rr_resp = nil
      Net::HTTP.start(rr_uri.host, rr_uri.port, use_ssl: true) { |http| rr_resp = http.request(rr_req) }
      if rr_resp.is_a?(Net::HTTPSuccess)
        puts ">> Requested reviewers: users=#{users.join(',')} teams=#{teams.join(',')}"
      else
        warn "Request reviewers failed: #{rr_resp.code} #{rr_resp.body}"
        # Fallback: add as assignees to surface ownership even if review request was rejected
        unless users.empty?
          assign_uri = URI("https://api.github.com/repos/#{owner}/#{repo}/issues/#{pr['number']}/assignees")
          assign_req = Net::HTTP::Post.new(assign_uri)
          assign_req['Authorization'] = "Bearer #{github_token}"
          assign_req['Accept'] = 'application/vnd.github+json'
          assign_req.body = { assignees: users }.to_json
          Net::HTTP.start(assign_uri.host, assign_uri.port, use_ssl: true) do |http|
            assign_resp = http.request(assign_req)
            if assign_resp.is_a?(Net::HTTPSuccess)
              puts ">> Assigned as fallback: users=#{users.join(',')}"
            else
              warn "Assign fallback result: #{assign_resp.code} #{assign_resp.body}"
            end
          end
        end
      end
    end
  end
  [pr, created]
end

def pr_body(pod, from_v, to_v, adapters: [])
  meta = { pod: pod, from: from_v, to: to_v, adapters: adapters }
  <<~MD
  Update CocoaPods dependency

  - #{pod}: #{from_v || 'unset'} → #{to_v}

  <!-- build-metadata
  #{JSON.pretty_generate(meta)}
  -->
  MD
end

def main
  git_reset_to_default
  entries = parse_podfile_entries
  exact = entries.select { |e| exact_version?(e[:version]) }
  return if exact.empty?

  exact.each do |e|
    pod = e[:name]
    cur = e[:version]
    all = trunk_versions_for(pod)
    cur_v = Gem::Version.new(cur)
    newer = all.select { |v| Gem::Version.new(v) > cur_v }
    next if newer.empty?

    newer.each do |to_v|
      puts "\n=============================="
      puts "🚀 Processing SDK #{pod} #{cur} → #{to_v}"
      puts "=============================="
      branch = "chore/pod-#{pod}-#{to_v}"
      # Always base PR branch from the base branch (e.g., 'dev')
      sh!("git fetch origin #{default_branch}")
      sh!("git checkout -B #{branch} origin/#{default_branch}")
      replace_pod_version_in_podfile(pod, to_v)
      pod_bin = ENV['POD_BIN'] || 'pod'
      sh!("#{pod_bin} update #{pod} --no-repo-update")
      # Update adapter changelogs before committing
      adapter_key = pod.split('/').first
      (POD_TO_ADAPTER[adapter_key] || POD_TO_ADAPTER[pod] || []).each do |adapter_name|
        update_adapter_changelog(adapter_name, pod, to_v)
      end
      sh!("git add Podfile Podfile.lock Adapters/*/CHANGELOG.md")
      msg = "chore(pods): #{pod} #{cur} -> #{to_v}"
      sh!(%{git commit -m "#{msg}"})
      git_push_branch(branch)
      begin
        adapter_key = pod.split('/').first
        adapter_names = POD_TO_ADAPTER[adapter_key] || POD_TO_ADAPTER[pod] || []
        pr, created = create_pr(branch, msg, pr_body(pod, cur, to_v, adapters: adapter_names))
        if created && pr
          tests_ok = true
          begin
            run_pods_tests
          rescue => e
            warn "Pods tests failed for #{pod} #{cur} -> #{to_v}: #{e.message}"
            tests_ok = false
          ensure
            begin
              if tests_ok
                add_labels(pr['number'], ['pods-tests-passed'])
                add_comment(pr['number'], "✅ Pods tests passed for this update.")
              else
                add_labels(pr['number'], ['pods-tests-failed'])
                add_comment(pr['number'], "❌ Pods tests FAILED for this update. Please check the Pods Updater workflow logs.")
              end
            rescue => e2
              warn "Unable to annotate PR ##{pr['number']} with test result: #{e2.message}"
            end
          end
        end
      rescue => e
        # If PR already exists (422), ignore; re-raise for other errors
        if e.message.include?('422') && e.message.include?('already exists')
          # no-op
        else
          raise
        end
      end
      git_reset_to_default
    end
  end
end

main


