import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class UploadService {
  final Dio _dio;

  UploadService(this._dio);

  Future<String> uploadImage(XFile imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });

      final response = await _dio.post(
        '/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return response.data['url'];
    } on DioException catch (e) {
      print('DioError uploading image: ${e.response?.data}');
      rethrow;
    }
  }
}
