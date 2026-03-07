import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class UploadService {
  final Dio _dio;

  UploadService(this._dio);

  Future<String> uploadImage(XFile imageFile) async {
    try {
      final String fileName = imageFile.name.isNotEmpty
          ? imageFile.name
          : imageFile.path.split(RegExp(r'[\\/]')).last;
      final bytes = await imageFile.readAsBytes();

      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dio.post(
        '/upload',
        data: formData,
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['url'] is String) {
        return data['url'] as String;
      }
      throw Exception("Reponse d'upload invalide: url absente.");
    } on DioException catch (e) {
      print('DioError uploading image: ${e.response?.data}');
      rethrow;
    }
  }
}
