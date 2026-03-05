#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'optparse'

ErrorEntry = Struct.new(:file, :line, :col, :message, :context, :adapter, keyword_init: true)

def parse_csv_list(v)
  v.to_s.split(',').map(&:strip).reject(&:empty?)
end

def detect_adapter_from_path(path)
  m = path.to_s.match(%r{/(Adapters/(BidonAdapter[A-Za-z0-9_]+))/})
  m ? m[2] : nil
end

def build_basename_to_adapter_map(adapters_root: 'Adapters')
  map = {}
  return map unless Dir.exist?(adapters_root)

  Dir.glob(File.join(adapters_root, '**', '*')).each do |p|
    next unless File.file?(p)
    adapter = detect_adapter_from_path("/#{p}") # ensure leading slash for regex
    next unless adapter
    bn = File.basename(p)
    next if bn.nil? || bn.empty?
    # If a basename exists in multiple adapters, keep the first; it's best-effort.
    map[bn] ||= adapter
  end

  map
rescue StandardError => e
  warn "Failed to build basename->adapter map: #{e.message}"
  {}
end

def xcode_error_line?(line)
  # Typical Xcode diagnostic:
  # /path/File.swift:47:67: error: message...
  line.match?(/\A.+\.(swift|m|mm|h|hpp|cpp):\d+:\d+:\s+error:\s+/i)
end

def parse_xcode_errors_from_log(log_path)
  entries = []
  lines = File.exist?(log_path) ? File.read(log_path, mode: 'r:BOM|UTF-8').lines : []

  i = 0
  while i < lines.length
    l = lines[i].to_s.rstrip
    if (m = l.match(/\A(?<file>.+\.(?:swift|m|mm|h|hpp|cpp)):(?<line>\d+):(?<col>\d+):\s+error:\s+(?<msg>.*)\z/i))
      file = m[:file]
      line_no = m[:line].to_i
      col_no = m[:col].to_i
      msg = m[:msg].to_s.strip

      ctx = []
      # Capture up to 2 following indented lines (often code line + caret line).
      1.upto(3) do |off|
        nl = lines[i + off]
        break if nl.nil?
        s = nl.to_s.rstrip
        break if xcode_error_line?(s)
        # Stop on other diagnostics (warning/note) that start like a path:line:col:
        break if s.match?(/\A.+\.(swift|m|mm|h|hpp|cpp):\d+:\d+:\s+(warning|note):\s+/i)
        break unless s.match?(/\A\s+/)
        ctx << s
      end

      adapter = detect_adapter_from_path(file)
      entries << ErrorEntry.new(file: file, line: line_no, col: col_no, message: msg, context: ctx, adapter: adapter)
    end
    i += 1
  end

  entries
rescue StandardError => e
  warn "Failed to parse log #{log_path}: #{e.message}"
  []
end

def read_source_line(path, line_no)
  return nil unless path && File.file?(path)
  return nil unless line_no && line_no > 0
  File.foreach(path).with_index(1) { |ln, idx| return ln.rstrip if idx == line_no }
  nil
rescue StandardError
  nil
end

def write_outputs(outputs)
  out_path = ENV['GITHUB_OUTPUT'].to_s
  return if out_path.empty?
  File.open(out_path, 'a') do |f|
    outputs.each do |k, v|
      f.puts("#{k}=#{v}")
    end
  end
rescue StandardError => e
  warn "Failed to write GITHUB_OUTPUT: #{e.message}"
end

options = {
  logs: [],
  out: 'build/reports/adapter-errors/adapter_errors.md',
  adapters: []
}

OptionParser.new do |opts|
  opts.banner = "Usage: collect_adapter_errors_report.rb --log <path> [--log <path> ...] [--out <md_path>] [--adapters A,B]"
  opts.on('--log PATH', 'Path to xcodebuild log (repeatable)') { |v| options[:logs] << v }
  opts.on('--out PATH', 'Output markdown path') { |v| options[:out] = v }
  opts.on('--adapters CSV', 'Comma-separated adapter names to include') { |v| options[:adapters] = parse_csv_list(v) }
end.parse!

if options[:logs].empty?
  warn 'No --log specified; nothing to do.'
  FileUtils.mkdir_p(File.dirname(options[:out]))
  File.write(options[:out], "# Adapters Build Errors Report\n\n- Findings: 0\n\n_No logs provided._\n")
  write_outputs('count' => '0', 'adapters' => '', 'has_errors' => 'false')
  exit 0
end

all_entries = options[:logs].flat_map { |p| parse_xcode_errors_from_log(p) }

# Best-effort fill adapter by basename map for entries without adapter.
if all_entries.any? { |e| e.adapter.nil? || e.adapter.to_s.empty? }
  bn_map = build_basename_to_adapter_map
  all_entries.each do |e|
    next if e.adapter && !e.adapter.to_s.empty?
    bn = File.basename(e.file.to_s)
    e.adapter = bn_map[bn] if bn && bn_map.key?(bn)
  end
end

# Optional filter to keep only errors from specified adapter(s)
filtered = if options[:adapters].any?
             needles = options[:adapters].map { |a| "/Adapters/#{a}/" }
             all_entries.select do |e|
               a = e.adapter.to_s
               options[:adapters].include?(a) || needles.any? { |n| e.file.to_s.include?(n) }
             end
           else
             all_entries
           end

filtered.uniq! { |e| [e.file, e.line, e.col, e.message] }

FileUtils.mkdir_p(File.dirname(options[:out]))
txt_out = options[:out].sub(/\.md\z/i, '.txt')

grouped = filtered.group_by { |e| (e.adapter && !e.adapter.to_s.empty?) ? e.adapter : 'UnknownAdapter' }
adapters_list = grouped.keys.reject { |k| k == 'UnknownAdapter' }.sort
count = filtered.length

md = +""

if count.zero?
  md << "Build/Test errors found (0)\n\n"
  md << "No `error:` diagnostics found in build/test logs.\n"
else
  adapter_label =
    if adapters_list.empty?
      "UnknownAdapter"
    else
      adapters_list.join(', ')
    end

  md << "Build/Test errors found (#{count}) for: #{adapter_label}\n\n"
  md << "```text\n"
  # Match deprecated report style: diagnostics lines only (no code/caret context).
  filtered
    .sort_by { |e| [e.file.to_s, e.line.to_i, e.col.to_i] }
    .each do |e|
      md << "#{e.file}:#{e.line}:#{e.col}: error: #{e.message}\n"
    end
  md << "```\n"
end

File.write(options[:out], md)

File.open(txt_out, 'w') do |f|
  filtered.sort_by { |e| [e.adapter.to_s, e.file.to_s, e.line.to_i, e.col.to_i] }.each do |e|
    f.puts("#{e.file}:#{e.line}:#{e.col}: error: #{e.message}")
  end
end

write_outputs(
  'count' => count.to_s,
  'adapters' => adapters_list.join(','),
  'has_errors' => (count.zero? ? 'false' : 'true'),
  'report_md' => options[:out],
  'report_txt' => txt_out
)

puts "Adapter errors: #{count}"
