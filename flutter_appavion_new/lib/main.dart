import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter cámara y ubicación',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraController? _cameraController;
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Solicitar permisos
    bool permisosOk = await _solicitarPermisos();
    if (!permisosOk) {
      setState(() => _isLoading = false);
      return;
    }

    // Inicializar cámara
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
      await _cameraController!.initialize();
    }

    // Obtener ubicación
    _currentPosition = await Geolocator.getCurrentPosition();

    setState(() => _isLoading = false);
  }

  Future<bool> _solicitarPermisos() async {
    var statusCamara = await Permission.camera.request();
    var statusUbicacion = await Permission.locationWhenInUse.request();
    return statusCamara.isGranted && statusUbicacion.isGranted;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: Text('No se pudo inicializar la cámara')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cámara y Ubicación')),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
          const SizedBox(height: 20),
          Text(
            _currentPosition != null
                ? 'Latitud: ${_currentPosition!.latitude.toStringAsFixed(6)}\nLongitud: ${_currentPosition!.longitude.toStringAsFixed(6)}'
                : 'No se pudo obtener ubicación',
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
