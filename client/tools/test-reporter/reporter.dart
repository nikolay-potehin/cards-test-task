#!/usr/bin/env dart
// ignore_for_file: avoid_print

/// Integration test reporter.
///
/// Parses a newline-delimited JSON event stream produced by the Dart/Flutter
/// test runner (`--file-reporter=json`) and renders a human-readable report.
///
/// Usage:
///   dart reporter.dart <report.json>                  # console report
///   dart reporter.dart <report.json> --html out.html  # self-contained HTML
///   dart reporter.dart <report.json> --json out.json  # machine-readable JSON
///   dart reporter.dart <report.json> --html out.html --json out.json
library;

import 'dart:convert';
import 'dart:io';

// ---------------------------------------------------------------------------
// Domain model
// ---------------------------------------------------------------------------

enum FailureType { none, assertion, flutterException, applicationCrash, timeout, infrastructure, unknown }

class TestResult {
  TestResult({required this.id, required this.name, required this.suiteId, required this.hidden});

  final int id;
  final String name;
  final int suiteId;
  bool hidden;

  String status = 'running'; // "running" | "success" | "error"
  bool skipped = false;
  int? startTime;
  int? endTime;

  final List<String> logs = [];
  String? error;
  String? stackTrace;
  bool isFailure = false;

  FailureType failureType = FailureType.none;

  int? get duration => startTime != null && endTime != null ? endTime! - startTime! : null;
}

/// Immutable, fully-parsed report ready to be consumed by any renderer.
class Report {
  Report({required this.success, required this.totalDurationMs, required this.tests});

  final bool success;
  final int? totalDurationMs;

  /// All tests, including hidden framework lifecycle tests, in start order.
  final List<TestResult> tests;

  /// User-visible tests only (hidden tests excluded), in start order.
  List<TestResult> get visibleTests => tests.where((t) => !t.hidden).toList();

  List<TestResult> get passed => visibleTests.where((t) => t.status == 'success').toList();

  List<TestResult> get failed => visibleTests.where((t) => t.status == 'error').toList();

  List<TestResult> get skipped => visibleTests.where((t) => t.skipped).toList();

  int get total => visibleTests.length;
  int get passedCount => passed.length;
  int get failedCount => failed.length;
  int get skippedCount => skipped.length;

  double get passRate => total == 0 ? 0 : (passedCount / total * 100);

  double get failRate => total == 0 ? 0 : (failedCount / total * 100);

  Map<FailureType, int> get failureCounts {
    final counts = <FailureType, int>{};
    for (final test in failed) {
      counts.update(test.failureType, (v) => v + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}

// ---------------------------------------------------------------------------
// Parser
// ---------------------------------------------------------------------------

/// Parses the NDJSON event stream at [path] into a [Report].
///
/// Throws a [FileSystemException] if the file does not exist.
Report parseReport(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw FileSystemException('File not found', path);
  }

  final tests = <int, TestResult>{};
  bool? overallSuccess;
  int? totalDuration;

  for (final line in file.readAsLinesSync()) {
    if (line.trim().isEmpty) continue;

    Map<String, dynamic> event;
    try {
      event = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      stderr.writeln('Skipping malformed JSON line.');
      continue;
    }

    switch (event['type']) {
      case 'testStart':
        final test = event['test'];
        if (test == null) break;

        final result = TestResult(
          id: test['id'] as int,
          name: test['name'] as String,
          suiteId: test['suiteID'] as int? ?? -1,
          hidden: false,
        );
        result.startTime = event['time'] as int?;
        tests[result.id] = result;
        break;

      case 'print':
        final id = event['testID'] as int?;
        final test = id == null ? null : tests[id];
        if (test == null) break;
        test.logs.add((event['message'] ?? '') as String);
        break;

      case 'error':
        final id = event['testID'] as int?;
        final test = id == null ? null : tests[id];
        if (test == null) break;

        test.error = event['error']?.toString();
        test.stackTrace = event['stackTrace']?.toString();
        test.isFailure = event['isFailure'] == true;
        break;

      case 'testDone':
        final id = event['testID'] as int?;
        final test = id == null ? null : tests[id];
        if (test == null) break;

        test.status = (event['result'] ?? 'error') as String;
        test.hidden = (event['hidden'] ?? false) as bool;
        test.skipped = (event['skipped'] ?? false) as bool;
        test.endTime = event['time'] as int?;

        if (test.status == 'error') {
          test.failureType = classifyFailure(test);
        }
        break;

      case 'done':
        overallSuccess = event['success'] as bool?;
        totalDuration = event['time'] as int?;
        break;
    }
  }

  final sorted = tests.values.toList()..sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));

  return Report(success: overallSuccess ?? false, totalDurationMs: totalDuration, tests: sorted);
}

/// Classifies a failed test into a [FailureType] by inspecting its error,
/// stack trace, and captured log messages.
FailureType classifyFailure(TestResult test) {
  final text = [
    if (test.error != null) test.error!,
    if (test.stackTrace != null) test.stackTrace!,
    ...test.logs,
  ].join('\n').toLowerCase();

  if (text.contains('lost connection to device') ||
      text.contains('process exited') ||
      text.contains('segmentation fault') ||
      text.contains('sigabrt') ||
      text.contains('fatal signal')) {
    return FailureType.applicationCrash;
  }

  if (text.contains('timeoutexception') || text.contains('timed out')) {
    return FailureType.timeout;
  }

  if (text.contains('device offline') ||
      text.contains('adb') ||
      text.contains('patrol server') ||
      text.contains('emulator')) {
    return FailureType.infrastructure;
  }

  if (text.contains('exception caught by flutter test framework')) {
    return FailureType.flutterException;
  }

  if (text.contains('testfailure') || text.contains('expected:') || text.contains('actual:')) {
    return FailureType.assertion;
  }

  return FailureType.unknown;
}

// ---------------------------------------------------------------------------
// Console renderer
// ---------------------------------------------------------------------------

void printReport(Report report) {
  final visible = report.visibleTests;
  final passed = report.passed;
  final failed = report.failed;
  final skipped = report.skipped;
  final counts = report.failureCounts;

  print('');
  print('===============================');
  print('      TEST EXECUTION REPORT');
  print('===============================');
  print('');

  print('Overall Status : ${report.success ? "PASSED" : "FAILED"}');
  print('Duration       : ${formatDuration(report.totalDurationMs)}');
  print('');

  print('Statistics');
  print('----------');
  print('Total tests : ${visible.length}');
  print('Passed      : ${passed.length}');
  print('Failed      : ${failed.length}');
  print('Skipped     : ${skipped.length}');
  print('Pass rate   : ${visible.isEmpty ? "0.0" : report.passRate.toStringAsFixed(1)}%');
  print('');

  print('Failure Categories');
  print('------------------');
  for (final type in FailureType.values.skip(1)) {
    print('${failureName(type).padRight(22)} ${counts[type] ?? 0}');
  }
  print('');

  if (failed.isNotEmpty) {
    print('Failed Tests');
    print('------------');
    for (final test in failed) {
      print('✗ ${test.name}');
      print('  Type     : ${failureName(test.failureType)}');
      if (test.error != null) {
        print('  Error    : ${firstLine(test.error!)}');
      }
      if (test.duration != null) {
        print('  Duration : ${test.duration} ms');
      }
      print('');
    }
  }

  print('Passed Tests');
  print('------------');
  for (final test in passed) {
    print('✓ ${test.name} (${test.duration ?? "-"} ms)');
  }
}

// ---------------------------------------------------------------------------
// HTML renderer
// ---------------------------------------------------------------------------

Future<void> writeHtmlReport(Report report, File output) async {
  final buf = StringBuffer();

  final passedCount = report.passedCount;
  final failedCount = report.failedCount;
  final skippedCount = report.skippedCount;
  final total = report.total;
  final passRate = report.passRate.toStringAsFixed(1);
  final failRate = report.failRate.toStringAsFixed(1);
  final counts = report.failureCounts;

  buf.writeln('<!DOCTYPE html>');
  buf.writeln('<html lang="en">');
  buf.writeln('<head>');
  buf.writeln('<meta charset="utf-8">');
  buf.writeln('<meta name="viewport" content="width=device-width, initial-scale=1">');
  buf.writeln('<title>Integration Test Report</title>');
  buf.writeln('<style>');
  buf.writeln(':root {');
  buf.writeln('  --green: #2e7d32;');
  buf.writeln('  --red: #c62828;');
  buf.writeln('  --orange: #ef6c00;');
  buf.writeln('  --bg: #fafafa;');
  buf.writeln('  --card: #ffffff;');
  buf.writeln('  --border: #e0e0e0;');
  buf.writeln('  --muted: #757575;');
  buf.writeln('}');
  buf.writeln('* { box-sizing: border-box; }');
  buf.writeln('body {');
  buf.writeln('  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;');
  buf.writeln('  margin: 0;');
  buf.writeln('  background: var(--bg);');
  buf.writeln('  color: #212121;');
  buf.writeln('}');
  buf.writeln('.progress-bar {');
  buf.writeln('  height: 6px;');
  buf.writeln('  background: var(--border);');
  buf.writeln('  position: sticky;');
  buf.writeln('  top: 0;');
  buf.writeln('  z-index: 100;');
  buf.writeln('}');
  buf.writeln('.progress-bar .fill {');
  buf.writeln('  height: 100%;');
  buf.writeln('  background: ${report.success ? 'var(--green)' : 'var(--red)'};');
  buf.writeln('  width: $passRate%;');
  buf.writeln('  transition: width 0.3s;');
  buf.writeln('}');
  buf.writeln('.summary {');
  buf.writeln('  position: sticky;');
  buf.writeln('  top: 6px;');
  buf.writeln('  z-index: 99;');
  buf.writeln('  background: var(--card);');
  buf.writeln('  border-bottom: 1px solid var(--border);');
  buf.writeln('  padding: 20px 40px 16px;');
  buf.writeln('  box-shadow: 0 2px 8px rgba(0,0,0,0.06);');
  buf.writeln('}');
  buf.writeln('.summary h1 { margin: 0 0 12px; font-size: 1.5rem; }');
  buf.writeln('.summary-grid {');
  buf.writeln('  display: flex;');
  buf.writeln('  flex-wrap: wrap;');
  buf.writeln('  gap: 24px;');
  buf.writeln('  align-items: center;');
  buf.writeln('}');
  buf.writeln('.stat {');
  buf.writeln('  display: flex;');
  buf.writeln('  flex-direction: column;');
  buf.writeln('}');
  buf.writeln(
    '.stat .label { font-size: 0.75rem; color: var(--muted); text-transform: uppercase; letter-spacing: 0.5px; }',
  );
  buf.writeln('.stat .value { font-size: 1.4rem; font-weight: 700; }');
  buf.writeln('.badge {');
  buf.writeln('  display: inline-block;');
  buf.writeln('  padding: 4px 12px;');
  buf.writeln('  border-radius: 999px;');
  buf.writeln('  font-size: 0.85rem;');
  buf.writeln('  font-weight: 700;');
  buf.writeln('}');
  buf.writeln('.badge.passed { background: #e8f5e9; color: var(--green); }');
  buf.writeln('.badge.failed { background: #ffebee; color: var(--red); }');
  buf.writeln('.badge.skipped { background: #fff3e0; color: var(--orange); }');
  buf.writeln('.toolbar {');
  buf.writeln('  display: flex;');
  buf.writeln('  gap: 12px;');
  buf.writeln('  align-items: center;');
  buf.writeln('  margin-top: 16px;');
  buf.writeln('  flex-wrap: wrap;');
  buf.writeln('}');
  buf.writeln('.toolbar input[type="text"] {');
  buf.writeln('  padding: 8px 14px;');
  buf.writeln('  border: 1px solid var(--border);');
  buf.writeln('  border-radius: 8px;');
  buf.writeln('  font-size: 0.9rem;');
  buf.writeln('  width: 280px;');
  buf.writeln('  outline: none;');
  buf.writeln('  transition: border-color 0.2s;');
  buf.writeln('}');
  buf.writeln('.toolbar input[type="text"]:focus { border-color: #90caf9; }');
  buf.writeln('.toolbar button {');
  buf.writeln('  padding: 8px 16px;');
  buf.writeln('  border: 1px solid var(--border);');
  buf.writeln('  border-radius: 8px;');
  buf.writeln('  background: var(--card);');
  buf.writeln('  cursor: pointer;');
  buf.writeln('  font-size: 0.85rem;');
  buf.writeln('  transition: all 0.2s;');
  buf.writeln('}');
  buf.writeln('.toolbar button:hover { background: #f5f5f5; }');
  buf.writeln('.toolbar button.active { background: #e3f2fd; border-color: #90caf9; }');
  buf.writeln('.content { padding: 24px 40px 60px; max-width: 1200px; margin: 0 auto; }');
  buf.writeln('h2 {');
  buf.writeln('  font-size: 1.2rem;');
  buf.writeln('  margin: 32px 0 16px;');
  buf.writeln('  padding-bottom: 8px;');
  buf.writeln('  border-bottom: 2px solid var(--border);');
  buf.writeln('}');
  buf.writeln('.failure-types {');
  buf.writeln('  display: flex;');
  buf.writeln('  flex-wrap: wrap;');
  buf.writeln('  gap: 16px;');
  buf.writeln('  margin-bottom: 8px;');
  buf.writeln('}');
  buf.writeln('.failure-type {');
  buf.writeln('  background: var(--card);');
  buf.writeln('  border: 1px solid var(--border);');
  buf.writeln('  border-radius: 8px;');
  buf.writeln('  padding: 12px 20px;');
  buf.writeln('  min-width: 180px;');
  buf.writeln('}');
  buf.writeln('.failure-type .name { font-size: 0.8rem; color: var(--muted); }');
  buf.writeln('.failure-type .count { font-size: 1.5rem; font-weight: 700; }');
  buf.writeln('.failure-type .pct { font-size: 0.75rem; color: var(--muted); }');
  buf.writeln('details {');
  buf.writeln('  background: var(--card);');
  buf.writeln('  border: 1px solid var(--border);');
  buf.writeln('  border-radius: 8px;');
  buf.writeln('  margin-bottom: 12px;');
  buf.writeln('  overflow: hidden;');
  buf.writeln('}');
  buf.writeln('details summary {');
  buf.writeln('  padding: 14px 20px;');
  buf.writeln('  cursor: pointer;');
  buf.writeln('  font-weight: 600;');
  buf.writeln('  display: flex;');
  buf.writeln('  align-items: center;');
  buf.writeln('  gap: 10px;');
  buf.writeln('  list-style: none;');
  buf.writeln('}');
  buf.writeln('details summary::-webkit-details-marker { display: none; }');
  buf.writeln('details summary::marker { display: none; }');
  buf.writeln('details[open] summary { border-bottom: 1px solid var(--border); }');
  buf.writeln('.test-icon { font-size: 1.1rem; }');
  buf.writeln('.test-meta { padding: 16px 20px; }');
  buf.writeln('.test-meta p { margin: 4px 0; }');
  buf.writeln('.test-meta .field { color: var(--muted); font-size: 0.85rem; }');
  buf.writeln('pre {');
  buf.writeln('  overflow-x: auto;');
  buf.writeln('  background: #f3f3f3;');
  buf.writeln('  padding: 12px 16px;');
  buf.writeln('  border-radius: 6px;');
  buf.writeln('  font-size: 0.82rem;');
  buf.writeln('  line-height: 1.5;');
  buf.writeln('  white-space: pre-wrap;');
  buf.writeln('  word-break: break-word;');
  buf.writeln('}');
  buf.writeln('h4 { margin: 16px 0 6px; font-size: 0.9rem; color: var(--muted); }');
  buf.writeln('.passed-list {');
  buf.writeln('  display: grid;');
  buf.writeln('  grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));');
  buf.writeln('  gap: 8px;');
  buf.writeln('}');
  buf.writeln('.passed-item {');
  buf.writeln('  background: var(--card);');
  buf.writeln('  border: 1px solid var(--border);');
  buf.writeln('  border-radius: 6px;');
  buf.writeln('  padding: 10px 16px;');
  buf.writeln('  display: flex;');
  buf.writeln('  align-items: center;');
  buf.writeln('  gap: 8px;');
  buf.writeln('}');
  buf.writeln('.passed-item .name { flex: 1; font-size: 0.9rem; }');
  buf.writeln('.passed-item .dur { color: var(--muted); font-size: 0.8rem; }');
  buf.writeln('.hidden { display: none !important; }');
  buf.writeln('</style>');
  buf.writeln('</head>');
  buf.writeln('<body>');

  // Progress bar
  buf.writeln('<div class="progress-bar"><div class="fill"></div></div>');

  // Sticky summary
  buf.writeln('<div class="summary">');
  buf.writeln('  <h1>Integration Test Report</h1>');
  buf.writeln('  <div class="summary-grid">');
  buf.writeln(
    '    <div class="stat"><span class="label">Status</span><span class="value"><span class="badge ${report.success ? 'passed' : 'failed'}">${report.success ? 'PASSED' : 'FAILED'}</span></span></div>',
  );
  buf.writeln(
    '    <div class="stat"><span class="label">Duration</span><span class="value">${formatDuration(report.totalDurationMs)}</span></div>',
  );
  buf.writeln('    <div class="stat"><span class="label">Pass rate</span><span class="value">$passRate%</span></div>');
  buf.writeln('    <div class="stat"><span class="label">Total</span><span class="value">$total</span></div>');
  buf.writeln(
    '    <div class="stat"><span class="label">Passed</span><span class="value" style="color:var(--green)">$passedCount</span></div>',
  );
  buf.writeln(
    '    <div class="stat"><span class="label">Failed</span><span class="value" style="color:var(--red)">$failedCount</span></div>',
  );
  buf.writeln(
    '    <div class="stat"><span class="label">Skipped</span><span class="value" style="color:var(--orange)">$skippedCount</span></div>',
  );
  buf.writeln('  </div>');
  buf.writeln('  <div class="toolbar">');
  buf.writeln('    <input type="text" id="search" placeholder="Search tests..." autocomplete="off">');
  buf.writeln('    <button class="active" data-filter="all" onclick="setFilter(\'all\')">Show all</button>');
  buf.writeln('    <button data-filter="failed" onclick="setFilter(\'failed\')">Show only failed</button>');
  buf.writeln('    <button data-filter="passed" onclick="setFilter(\'passed\')">Show only passed</button>');
  buf.writeln('  </div>');
  buf.writeln('</div>');

  // Content
  buf.writeln('<div class="content">');

  // Failure types
  buf.writeln('  <h2>Failure Types</h2>');
  buf.writeln('  <div class="failure-types">');
  for (final type in FailureType.values.skip(1)) {
    final count = counts[type] ?? 0;
    final pct = failedCount == 0 ? '0.0' : (count / failedCount * 100).toStringAsFixed(1);
    buf.writeln('    <div class="failure-type">');
    buf.writeln('      <div class="name">${failureName(type)}</div>');
    buf.writeln('      <div class="count">$count</div>');
    buf.writeln('      <div class="pct">$pct% of failures</div>');
    buf.writeln('    </div>');
  }
  buf.writeln('  </div>');

  // Failed tests
  buf.writeln('  <h2>Failed Tests ($failedCount)</h2>');
  if (report.failed.isEmpty) {
    buf.writeln('  <p style="color:var(--green)">No failed tests 🎉</p>');
  } else {
    for (final test in report.failed) {
      buf.writeln('  <details class="test-entry" data-status="failed" data-name="${escapeAttr(test.name)}">');
      buf.writeln('    <summary>');
      buf.writeln('      <span class="test-icon">✗</span>');
      buf.writeln('      <span>${escapeHtml(test.name)}</span>');
      buf.writeln('    </summary>');
      buf.writeln('    <div class="test-meta">');
      buf.writeln('      <p><span class="field">Failure type:</span> ${failureName(test.failureType)}</p>');
      if (test.duration != null) {
        buf.writeln('      <p><span class="field">Duration:</span> ${test.duration} ms</p>');
      }
      if (test.error != null) {
        buf.writeln('      <h4>Error</h4>');
        buf.writeln('      <pre>${escapeHtml(test.error!)}</pre>');
      }
      if (test.stackTrace != null) {
        buf.writeln('      <h4>Stack trace</h4>');
        buf.writeln('      <pre>${escapeHtml(test.stackTrace!)}</pre>');
      }
      if (test.logs.isNotEmpty) {
        buf.writeln('      <h4>Captured logs</h4>');
        buf.writeln('      <pre>${escapeHtml(test.logs.join('\n'))}</pre>');
      }
      buf.writeln('    </div>');
      buf.writeln('  </details>');
    }
  }

  // Passed tests
  buf.writeln('  <h2>Passed Tests ($passedCount)</h2>');
  if (report.passed.isEmpty) {
    buf.writeln('  <p style="color:var(--muted)">No passed tests.</p>');
  } else {
    buf.writeln('  <div class="passed-list">');
    for (final test in report.passed) {
      buf.writeln('    <div class="passed-item test-entry" data-status="passed" data-name="${escapeAttr(test.name)}">');
      buf.writeln('      <span class="test-icon" style="color:var(--green)">✓</span>');
      buf.writeln('      <span class="name">${escapeHtml(test.name)}</span>');
      buf.writeln('      <span class="dur">${test.duration ?? '-'} ms</span>');
      buf.writeln('    </div>');
    }
    buf.writeln('  </div>');
  }

  buf.writeln('</div>'); // .content

  // Vanilla JS for search + filter
  buf.writeln('<script>');
  buf.writeln('let currentFilter = "all";');
  buf.writeln('const entries = document.querySelectorAll(".test-entry");');
  buf.writeln('const searchInput = document.getElementById("search");');
  buf.writeln('');
  buf.writeln('function applyFilters() {');
  buf.writeln('  const query = searchInput.value.toLowerCase().trim();');
  buf.writeln('  entries.forEach(el => {');
  buf.writeln('    const matchesFilter = currentFilter === "all" || el.dataset.status === currentFilter;');
  buf.writeln('    const matchesSearch = !query || el.dataset.name.toLowerCase().includes(query);');
  buf.writeln('    el.classList.toggle("hidden", !(matchesFilter && matchesSearch));');
  buf.writeln('  });');
  buf.writeln('}');
  buf.writeln('');
  buf.writeln('function setFilter(filter) {');
  buf.writeln('  currentFilter = filter;');
  buf.writeln('  document.querySelectorAll(".toolbar button").forEach(btn => {');
  buf.writeln('    btn.classList.toggle("active", btn.dataset.filter === filter);');
  buf.writeln('  });');
  buf.writeln('  applyFilters();');
  buf.writeln('}');
  buf.writeln('');
  buf.writeln('searchInput.addEventListener("input", applyFilters);');
  buf.writeln('</script>');

  buf.writeln('</body>');
  buf.writeln('</html>');

  await output.writeAsString(buf.toString());
}

// ---------------------------------------------------------------------------
// JSON renderer
// ---------------------------------------------------------------------------

Future<void> writeJsonReport(Report report, File output) async {
  final json = {
    'success': report.success,
    'durationMs': report.totalDurationMs,
    'duration': formatDuration(report.totalDurationMs),
    'total': report.total,
    'passed': report.passedCount,
    'failed': report.failedCount,
    'skipped': report.skippedCount,
    'passRate': double.parse(report.passRate.toStringAsFixed(1)),
    'failRate': double.parse(report.failRate.toStringAsFixed(1)),
    'failureCounts': {
      for (final type in FailureType.values.skip(1)) failureName(type): report.failureCounts[type] ?? 0,
    },
    'tests': report.visibleTests
        .map(
          (t) => {
            'id': t.id,
            'name': t.name,
            'status': t.status,
            'skipped': t.skipped,
            'durationMs': t.duration,
            'failureType': t.failureType == FailureType.none ? null : failureName(t.failureType),
            'error': t.error,
            'stackTrace': t.stackTrace,
            'logs': t.logs,
          },
        )
        .toList(),
  };

  await output.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String failureName(FailureType type) {
  switch (type) {
    case FailureType.none:
      return 'None';
    case FailureType.assertion:
      return 'Assertion';
    case FailureType.flutterException:
      return 'Flutter Exception';
    case FailureType.applicationCrash:
      return 'Application Crash';
    case FailureType.timeout:
      return 'Timeout';
    case FailureType.infrastructure:
      return 'Infrastructure';
    case FailureType.unknown:
      return 'Unknown';
  }
}

String firstLine(String text) {
  return text.split('\n').first.trim();
}

String formatDuration(int? milliseconds) {
  if (milliseconds == null) return '-';
  final seconds = milliseconds / 1000;
  if (seconds < 60) return '${seconds.toStringAsFixed(1)} s';
  final mins = (seconds / 60).floor();
  final secs = (seconds % 60).toStringAsFixed(0);
  return '${mins}m ${secs}s';
}

String escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

String escapeAttr(String text) {
  return text.replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll("'", '&#39;');
}

// ---------------------------------------------------------------------------
// CLI entry point
// ---------------------------------------------------------------------------

void main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart reporter.dart <report.json> [--html out.html] [--json out.json]');
    exit(1);
  }

  final inputPath = args.first;
  String? htmlPath;
  String? jsonPath;

  for (var i = 1; i < args.length; i++) {
    switch (args[i]) {
      case '--html':
      case '-h':
        if (i + 1 < args.length) {
          htmlPath = args[++i];
        } else {
          stderr.writeln('--html requires a file path');
          exit(1);
        }
      case '--json':
        if (i + 1 < args.length) {
          jsonPath = args[++i];
        } else {
          stderr.writeln('--json requires a file path');
          exit(1);
        }
      case '--help':
        stdout.writeln('Usage: dart reporter.dart <report.json> [--html out.html] [--json out.json]');
        stdout.writeln('');
        stdout.writeln('Options:');
        stdout.writeln('  --html <path>  Write a self-contained HTML report');
        stdout.writeln('  --json <path>  Write a machine-readable JSON report');
        stdout.writeln('  --help         Show this help');
        exit(0);
      default:
        stderr.writeln('Unknown option: ${args[i]}');
        exit(1);
    }
  }

  final Report report;
  try {
    report = parseReport(inputPath);
  } catch (e) {
    stderr.writeln(e.toString());
    exit(1);
  }

  // Console report is always printed.
  printReport(report);

  if (htmlPath != null) {
    await writeHtmlReport(report, File(htmlPath));
    print('');
    print('HTML report written to: $htmlPath');
  }

  if (jsonPath != null) {
    await writeJsonReport(report, File(jsonPath));
    print('JSON report written to: $jsonPath');
  }
}
