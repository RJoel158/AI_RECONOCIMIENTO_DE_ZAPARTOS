import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiService {
  final String baseUrl = ApiConfig.baseUrl;

  /// Reconoce un zapato enviando una ráfaga de imágenes
  Future<Map<String, dynamic>> recognizeShoe(List<String> imagePaths) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/recognize'),
    );

    // Adjuntar todas las imágenes
    for (var path in imagePaths) {
      final file = await http.MultipartFile.fromPath('images', path);
      request.files.add(file);
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Error del servidor: ${response.statusCode} - ${response.body}',
        );
      }
    } on SocketException {
      throw Exception('Sin conexión a Internet');
    } on FormatException {
      throw Exception('Respuesta del servidor no válida');
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  /// Obtiene los detalles de un producto por su SKU
  Future<Map<String, dynamic>> getProductBySku(String sku) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/recognize/$sku'));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Producto no encontrado: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Sin conexión a Internet');
    } on FormatException {
      throw Exception('Respuesta del servidor no válida');
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  Future<Map<String, dynamic>> listProducts({
    String? q,
    String? brand,
    String? type,
    String? colorPrimary,
    String? colorSecondary,
    String? material,
    String? aisle,
    String? shelf,
    String? shelfLevel,
    int skip = 0,
    int limit = 50,
  }) async {
    final query = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };

    void addIfPresent(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        query[key] = value.trim();
      }
    }

    addIfPresent('q', q);
    addIfPresent('brand', brand);
    addIfPresent('type', type);
    addIfPresent('color_primary', colorPrimary);
    addIfPresent('color_secondary', colorSecondary);
    addIfPresent('material', material);
    addIfPresent('aisle', aisle);
    addIfPresent('shelf', shelf);
    addIfPresent('shelf_level', shelfLevel);

    try {
      final uri = Uri.parse(
        '$baseUrl/products',
      ).replace(queryParameters: query);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Error del servidor: ${response.statusCode}');
    } on SocketException {
      throw Exception('Sin conexión a Internet');
    } on FormatException {
      throw Exception('Respuesta del servidor no válida');
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception(
        'Error del servidor: ${response.statusCode} - ${response.body}',
      );
    } on SocketException {
      throw Exception('Sin conexión a Internet');
    } on FormatException {
      throw Exception('Respuesta del servidor no válida');
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  Future<List<dynamic>> createCapture({
    required String sku,
    required List<String> imagePaths,
    String? source,
    String? note,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/captures'),
    );
    request.fields['sku'] = sku;
    if (source != null && source.trim().isNotEmpty) {
      request.fields['source'] = source.trim();
    }
    if (note != null && note.trim().isNotEmpty) {
      request.fields['note'] = note.trim();
    }
    for (final path in imagePaths) {
      request.files.add(await http.MultipartFile.fromPath('images', path));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as List<dynamic>;
      }
      throw Exception(
        'Error del servidor: ${response.statusCode} - ${response.body}',
      );
    } on SocketException {
      throw Exception('Sin conexión a Internet');
    } on FormatException {
      throw Exception('Respuesta del servidor no válida');
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }
}
