#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require 'rubygems/version'

TRUNK_BASE = 'https://trunk.cocoapods.org/api/v1/pods'

def repo_slug
  ENV.fetch('GITHUB_REPOSITORY')
end

def github_token
  ENV.fetch('GITHUB_TOKEN')
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
  data = http_get_json("#{TRUNK_BASE}/#{URI.encode_www_form_component(pod)}")
  versions = (data['versions'] || []).map { |x| x['name'] }.compact.uniq
  versions.sort_by { |v| Gem::Version.new(v) }
end

def replace_pod_version_in_podfile(pod, to_version)
  src = File.read('Podfile')
  changed = false
  new_src = src.gsub(/^(\s*pod\s+["']#{Regexp.escape(pod)}["'])\s*(?:,\s*["']([^"']+)["'])?/) do
    prefix = Regexp.last_match(1)
    changed = true
    %(#{prefix}, "#{to_version}")
  end
  raise "Pod '#{pod}' not found in Podfile" unless changed
  File.write('Podfile', new_src)
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
  remote = "https://x-access-token:#{github_token}@github.com/#{owner}/#{repo}.git"
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
        break
      end
    end
  end
  raise "PR create failed: #{last_resp&.code} #{last_resp&.body}" unless pr
  issues_uri = URI("https://api.github.com/repos/#{owner}/#{repo}/issues/#{pr['number']}/labels")
  lab_req = Net::HTTP::Post.new(issues_uri)
  lab_req['Authorization'] = "Bearer #{github_token}"
  lab_req['Accept'] = 'application/vnd.github+json'
  lab_req.body = { labels: labels }.to_json
  Net::HTTP.start(issues_uri.host, issues_uri.port, use_ssl: true) { |http| http.request(lab_req) }
  pr
end

def pr_body(pod, from_v, to_v, adapter: nil)
  meta = { pod: pod, from: from_v, to: to_v, adapter: adapter.to_s }
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
      branch = "chore/pod-#{pod}-#{to_v}"
      # Always base PR branch from the base branch (e.g., 'dev')
      sh!("git fetch origin #{default_branch}")
      sh!("git checkout -B #{branch} origin/#{default_branch}")
      replace_pod_version_in_podfile(pod, to_v)
      pod_bin = ENV['POD_BIN'] || 'pod'
      sh!("#{pod_bin} update #{pod} --no-repo-update")
      sh!("git add Podfile Podfile.lock")
      msg = "chore(pods): #{pod} #{cur} -> #{to_v}"
      sh!(%{git commit -m "#{msg}"})
      git_push_branch(branch)
      begin
        create_pr(branch, msg, pr_body(pod, cur, to_v))
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


