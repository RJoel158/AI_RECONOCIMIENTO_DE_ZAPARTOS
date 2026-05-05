import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ApiService {
  final String baseUrl = "http://localhost:8000"; // Cambia a la IP de tu servidor en la red local si es necesario

  /// Reconoce un zapato enviando una ráfaga de imágenes
  Future<Map<String, dynamic>> recognizeShoe(List<String> imagePaths) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/recognize'));
    
    // Adjuntar todas las imágenes
    for (var path in imagePaths) {
      var file = await http.MultipartFile.fromPath('images', path);
      request.files.add(file);
    }
    
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error del servidor: ${response.statusCode} - ${response.body}');
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
}