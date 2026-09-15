import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class AIService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
    ),
  );

  Future<List<Face>> detectFaces(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final List<Face> faces = await _faceDetector.processImage(inputImage);
    return faces;
  }

  bool isPotentialMatch(List<Face> detectedFaces) {
    // For a prototype, we check if at least one clear face is detected
    // In production, we would compare embeddings with the database
    return detectedFaces.isNotEmpty;
  }

  void dispose() {
    _faceDetector.close();
  }
}
