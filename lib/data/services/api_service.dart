import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/equipment.dart';
import '../models/loan.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 8);

  Future<List<Equipment>> getEquipment({String search = ''}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/equipment',
    ).replace(queryParameters: search.isEmpty ? null : {'search': search});
    final response = await _request(() => _client.get(uri));
    return (jsonDecode(response.body) as List)
        .map((item) => Equipment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Equipment> createEquipment(EquipmentInput input) async {
    final response = await _request(
      () => _client.post(
        _uri('/equipment'),
        headers: _headers,
        body: jsonEncode(input.toJson()),
      ),
    );
    return Equipment.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Equipment> updateEquipment(int id, EquipmentInput input) async {
    final response = await _request(
      () => _client.put(
        _uri('/equipment/$id'),
        headers: _headers,
        body: jsonEncode(input.toJson()),
      ),
    );
    return Equipment.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteEquipment(int id) async {
    await _request(() => _client.delete(_uri('/equipment/$id')));
  }

  Future<List<Loan>> getLoans({String status = ''}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/loans',
    ).replace(queryParameters: status.isEmpty ? null : {'status': status});
    final response = await _request(() => _client.get(uri));
    return (jsonDecode(response.body) as List)
        .map((item) => Loan.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Loan> createLoan(LoanInput input) async {
    final response = await _request(
      () => _client.post(
        _uri('/loans'),
        headers: _headers,
        body: jsonEncode(input.toJson()),
      ),
    );
    return Loan.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Loan> updateLoan(int id, Map<String, dynamic> input) async {
    final response = await _request(
      () => _client.put(
        _uri('/loans/$id'),
        headers: _headers,
        body: jsonEncode(input),
      ),
    );
    return Loan.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Loan> returnLoan(int id) async {
    final response = await _request(
      () => _client.patch(_uri('/loans/$id/return')),
    );
    return Loan.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteLoan(int id) async {
    await _request(() => _client.delete(_uri('/loans/$id')));
  }

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');
  Map<String, String> get _headers => const {
    'Content-Type': 'application/json',
  };

  Future<http.Response> _request(
    Future<http.Response> Function() operation,
  ) async {
    try {
      final response = await operation().timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }

      var message = 'No se pudo completar la operación.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = (body['message'] as String?) ?? message;
      } catch (_) {}
      throw ApiException(message);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'No se pudo conectar con la API. Verifica que el servidor esté encendido.',
      );
    }
  }
}
