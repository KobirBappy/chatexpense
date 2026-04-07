import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';

/// Minimal MCP server over stdio.
///
/// Tool exposed:
/// - search_employee_by_name(employee_name)
///
/// Excel source path:
/// - ENV INVENTORY_XLSX_PATH
/// - or default: C:\Users\MdKobirHosan\Downloads\IT Device Inventory_CSL.xlsx
void main() async {
  final server = _InventoryMcpServer();
  await server.run();
}

class _InventoryMcpServer {
  static const String _defaultInventoryPath =
      r'C:\Users\MdKobirHosan\Downloads\IT Device Inventory_CSL.xlsx';

  Future<void> run() async {
    stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleLine, onError: _writeErrorLine);
  }

  Future<void> _handleLine(String line) async {
    if (line.trim().isEmpty) return;

    dynamic payload;
    try {
      payload = jsonDecode(line);
    } catch (e) {
      _writeJson({
        'jsonrpc': '2.0',
        'error': {'code': -32700, 'message': 'Parse error: $e'},
      });
      return;
    }

    if (payload is! Map<String, dynamic>) return;

    final id = payload['id'];
    final method = payload['method']?.toString();
    final params =
        payload['params'] is Map<String, dynamic> ? payload['params'] as Map<String, dynamic> : <String, dynamic>{};

    try {
      switch (method) {
        case 'initialize':
          _writeResult(id, {
            'protocolVersion': '2024-11-05',
            'capabilities': {
              'tools': {},
            },
            'serverInfo': {
              'name': 'inventory-mcp-server',
              'version': '1.0.0',
            },
          });
          return;

        case 'notifications/initialized':
          // No response for notifications.
          return;

        case 'tools/list':
          _writeResult(id, {
            'tools': [
              {
                'name': 'search_employee_by_name',
                'description':
                    'Search IT device inventory by employee name and return matching device records.',
                'inputSchema': {
                  'type': 'object',
                  'properties': {
                    'employee_name': {
                      'type': 'string',
                      'description': 'Full or partial employee name.',
                    },
                  },
                  'required': ['employee_name'],
                },
              }
            ]
          });
          return;

        case 'tools/call':
          await _handleToolCall(id, params);
          return;

        default:
          _writeError(
            id,
            code: -32601,
            message: 'Method not found: $method',
          );
      }
    } catch (e, st) {
      _writeError(
        id,
        code: -32000,
        message: 'Server error: $e',
        data: st.toString(),
      );
    }
  }

  Future<void> _handleToolCall(dynamic id, Map<String, dynamic> params) async {
    final toolName = params['name']?.toString();
    final args = params['arguments'] is Map<String, dynamic>
        ? params['arguments'] as Map<String, dynamic>
        : <String, dynamic>{};

    if (toolName != 'search_employee_by_name') {
      _writeError(id, code: -32602, message: 'Unknown tool: $toolName');
      return;
    }

    final employeeName = args['employee_name']?.toString().trim() ?? '';
    if (employeeName.isEmpty) {
      _writeError(id, code: -32602, message: 'employee_name is required.');
      return;
    }

    final inventoryPath = Platform.environment['INVENTORY_XLSX_PATH'] ?? _defaultInventoryPath;
    final file = File(inventoryPath);
    if (!file.existsSync()) {
      _writeError(
        id,
        code: -32001,
        message: 'Inventory file not found: $inventoryPath',
      );
      return;
    }

    final rows = _searchByEmployeeName(
      xlsxPath: inventoryPath,
      employeeName: employeeName,
    );

    final text = rows.isEmpty
        ? 'No records found for "$employeeName".'
        : const JsonEncoder.withIndent('  ').convert(rows);

    _writeResult(id, {
      'content': [
        {'type': 'text', 'text': text}
      ],
      'structuredContent': {
        'matches': rows,
        'count': rows.length,
      }
    });
  }

  List<Map<String, String>> _searchByEmployeeName({
    required String xlsxPath,
    required String employeeName,
  }) {
    final bytes = File(xlsxPath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return const [];

    final table = excel.tables.values.first;
    if (table.maxRows <= 1) return const [];

    final headerCells = table.rows.first;
    final headers = headerCells.map((c) => _cellToString(c).trim()).toList();

    final employeeCol = _findEmployeeColumn(headers);
    if (employeeCol == -1) {
      throw StateError(
        'Could not find employee name column. Available headers: ${headers.join(', ')}',
      );
    }

    final needle = employeeName.toLowerCase();
    final matches = <Map<String, String>>[];

    for (var r = 1; r < table.maxRows; r++) {
      final row = table.rows[r];
      if (row.isEmpty) continue;

      final employeeValue = employeeCol < row.length ? _cellToString(row[employeeCol]) : '';
      if (!employeeValue.toLowerCase().contains(needle)) continue;

      final mapped = <String, String>{};
      for (var c = 0; c < headers.length; c++) {
        final key = headers[c].isEmpty ? 'column_${c + 1}' : headers[c];
        final value = c < row.length ? _cellToString(row[c]) : '';
        mapped[key] = value;
      }
      matches.add(mapped);
    }

    return matches;
  }

  int _findEmployeeColumn(List<String> headers) {
    final normalized = headers.map(_normalize).toList();
    const strongCandidates = [
      'employee name',
      'employee_name',
      'employeename',
      'staff name',
      'staff_name',
      'assignee',
      'assigned to',
      'user name',
      'username',
      'name',
    ];

    for (final candidate in strongCandidates) {
      final i = normalized.indexOf(_normalize(candidate));
      if (i != -1) return i;
    }

    for (var i = 0; i < normalized.length; i++) {
      final h = normalized[i];
      if (h.contains('employee') || h.contains('staff') || h.contains('assignee')) {
        return i;
      }
    }
    return -1;
  }

  String _normalize(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  String _cellToString(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString().trim();
  }

  void _writeResult(dynamic id, Object? result) {
    _writeJson({
      'jsonrpc': '2.0',
      'id': id,
      'result': result,
    });
  }

  void _writeError(
    dynamic id, {
    required int code,
    required String message,
    Object? data,
  }) {
    _writeJson({
      'jsonrpc': '2.0',
      'id': id,
      'error': {
        'code': code,
        'message': message,
        if (data != null) 'data': data,
      }
    });
  }

  void _writeErrorLine(Object e) {
    _writeJson({
      'jsonrpc': '2.0',
      'error': {'code': -32000, 'message': e.toString()},
    });
  }

  void _writeJson(Map<String, dynamic> obj) {
    stdout.writeln(jsonEncode(obj));
  }
}
