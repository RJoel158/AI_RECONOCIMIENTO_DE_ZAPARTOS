import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import 'api_config.dart';

class ApiService {
  final String baseUrl = ApiConfig.baseUrl;

  /// Determines the MediaType for an image file based on its extension.
  MediaType _imageMediaType(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.png':
        return MediaType('image', 'png');
      case '.webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  /// Reconoce un zapato enviando una ráfaga de imágenes
  Future<Map<String, dynamic>> recognizeShoe(List<String> imagePaths) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/recognize'),
    );

    // Adjuntar todas las imágenes con content-type explícito
    for (var path in imagePaths) {
      final file = await http.MultipartFile.fromPath(
        'images',
        path,
        contentType: _imageMediaType(path),
      );
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

  Future<Map<String, dynamic>> uploadProductImage({
    required String sku,
    required String imagePath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/products/$sku/image'),
    );
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imagePath,
      contentType: _imageMediaType(imagePath),
    ));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
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
      request.files.add(await http.MultipartFile.fromPath(
        'images',
        path,
        contentType: _imageMediaType(path),
      ));
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

  /// Fetches distinct values for a given product field (for filter dropdowns)
  Future<List<String>> getDistinctValues(String field) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/distinct/$field'),
      );
      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List<dynamic>;
        return list.map((e) => e.toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
