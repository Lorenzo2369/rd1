// home.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedCamera = 'local';
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  Position? _position;

  final String esp32Url = 'http://192.168.1.50:81/stream';
  final String otraCamUrl = 'http://otra-camara-url/stream';

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    var statusCamara = await Permission.camera.request();
    var statusUbicacion = await Permission.locationWhenInUse.request();

    if (statusCamara.isGranted && statusUbicacion.isGranted) {
      await _initCameras();
      await _getLocation();
    } else {
      print('Permisos de cámara o ubicación no otorgados');
    }
  }

  Future<void> _initCameras() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty && _selectedCamera == 'local') {
        _cameraController = CameraController(cameras![0], ResolutionPreset.medium);
        await _cameraController!.initialize();
        setState(() {});
      }
    } catch (e) {
      print('Error inicializando cámaras: $e');
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Servicio de ubicación desactivado');
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Permiso de ubicación denegado');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      print('Permiso de ubicación denegado permanentemente');
      return;
    }
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _position = position;
    });
  }

  Future<void> _sendCommand(String direction) async {
    final url = 'http://192.168.1.50/control?dir=$direction';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print('Comando $direction enviado');
      } else {
        print('Error enviando comando: ${response.statusCode}');
      }
    } catch (e) {
      print('Error conexión: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      final XFile file = await _cameraController!.takePicture();
      print('Foto tomada en: ${file.path}');
      // Aquí puedes mostrar la foto o subirla a un servidor
    } catch (e) {
      print('Error al tomar foto: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Widget _buildCameraWidget() {
    if (_selectedCamera == 'local') {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }
      return CameraPreview(_cameraController!);
    } else {
      String url = _selectedCamera == 'esp32Cam' ? esp32Url : otraCamUrl;
      return Image.network(url, fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home - Control Cámara'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedCamera,
              items: const [
                DropdownMenuItem(value: 'local', child: Text('Cámara local (PC)')),
                DropdownMenuItem(value: 'esp32Cam', child: Text('ESP32-CAM')),
                DropdownMenuItem(value: 'otraCam', child: Text('Otra cámara')),
              ],
              onChanged: (value) async {
                setState(() {
                  _selectedCamera = value!;
                });
                if (_selectedCamera == 'local') {
                  await _initCameras();
                } else {
                  _cameraController?.dispose();
                  _cameraController = null;
                  setState(() {});
                }
              },
            ),
          ),
          Expanded(child: _buildCameraWidget()),
          if (_position != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Lat: ${_position!.latitude.toStringAsFixed(6)}, Lng: ${_position!.longitude.toStringAsFixed(6)}',
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.arrow_upward), onPressed: () => _sendCommand('up')),
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _sendCommand('left')),
              IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => _sendCommand('right')),
              IconButton(icon: const Icon(Icons.arrow_downward), onPressed: () => _sendCommand('down')),
            ],
          ),
          ElevatedButton(
            onPressed: () async {
              if (_selectedCamera != 'local') {
                String url = _selectedCamera == 'esp32Cam' ? esp32Url : otraCamUrl;
                final Uri uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  print('No se pudo abrir $url');
                }
              } else {
                await _takePicture();
              }
            },
            child: const Text('Marcar Objetivo'),
          )
        ],
      ),
    );
  }
}
