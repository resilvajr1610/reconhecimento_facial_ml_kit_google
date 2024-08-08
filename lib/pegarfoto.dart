import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:typed_data';
import 'dart:io';

class PegarFoto extends StatefulWidget {
  @override
  _PegarFotoState createState() => _PegarFotoState();
}

class _PegarFotoState extends State<PegarFoto> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  List<Rect> _faceRects = [];
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableTracking: true,
      ),
    );
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(camera, ResolutionPreset.high);

    try {
      await _cameraController?.initialize();
      _cameraController?.startImageStream((CameraImage image) {
        if (_isDetecting) return;
        _isDetecting = true;
        _detectFaces(image);
      });
      setState(() {});
    } on CameraException catch (e) {
      print('Erro ao inicializar a câmera: $e');
    }
  }

  void _detectFaces(CameraImage image) async {
    try {
      final InputImage inputImage = _convertCameraImage(image);
      final List<Face> faces = await _faceDetector!.processImage(inputImage);
      if (faces.isNotEmpty) {
        setState(() {
          _faceRects = faces.map((face) => face.boundingBox).toList();
        });

        _cameraController?.stopImageStream();
        _capturePhoto();
      }
    } catch (e) {
      print('Erro ao detectar rostos: $e');
    } finally {
      _isDetecting = false;
    }
  }

  InputImage _convertCameraImage(CameraImage image) {
    final bytes = Uint8List.fromList(image.planes.expand((plane) => plane.bytes).toList());

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final InputImageRotation imageRotation = InputImageRotation.rotation270deg;
    final InputImageFormat inputImageFormat = InputImageFormat.yuv_420_888;

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }

  void _capturePhoto() async {
    try {
      final XFile? image = await _cameraController?.takePicture();
      if (image != null) {
        setState(() {
          _capturedImagePath = image.path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto capturada com sucesso!')),
        );
      } else {
        print('Nenhuma imagem foi capturada.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nenhuma foto capturada.')),
        );
      }
      _disposeCamera(); // Fechar a câmera após capturar a foto
    } catch (e) {
      print('Erro ao capturar foto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao capturar foto: $e')),
      );
      _disposeCamera(); // Fechar a câmera mesmo em caso de erro
    }
  }

  void _disposeCamera() {
    _cameraController?.dispose();
    _faceDetector?.close();
    setState(() {
      _cameraController = null; // Definir o controlador como nulo
    });
  }

  @override
  void dispose() {
    _disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detecção de Rosto Automática'),
      ),
      body: _capturedImagePath == null
          ?Stack(
        children: [
          _cameraController == null
              ? Center(child: CircularProgressIndicator())
              : CameraPreview(_cameraController!),
        ],
      ):Center(
        child: ListView(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 500,
              child: Image.file(File(_capturedImagePath!))
            ), // Exibir a imagem capturada
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _capturedImagePath = null; // Voltar para a visualização da câmera
                  _initializeCamera(); // Re-inicialize a câmera
                });
              },
              child: Text('Capturar Outra Foto'),
            ),
          ],
        ),
      ),
    );
  }
}

