import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'verhistorial.dart';

class FotoHistorial {
  final String path;
  final DateTime fechaHora;
  final double lat;
  final double lng;

  FotoHistorial({
    required this.path,
    required this.fechaHora,
    required this.lat,
    required this.lng,
  });
}

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
  bool _isCameraLoading = false;
  bool _isLocationLoading = false;

  final String esp32Url = 'http://192.168.1.50:81/stream';
  final String otraCamUrl = 'http://otra-camara-url/stream';

  List<FotoHistorial> historialFotos = [];
  
  get verhistorial => null;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    if (kIsWeb) {
      await _initCameras();
      return;
    }

    if (!(Platform.isAndroid || Platform.isIOS)) return;

    var statusCam = await Permission.camera.status;
    var statusLoc = await Permission.locationWhenInUse.status;

    if (!statusCam.isGranted || !statusLoc.isGranted) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.locationWhenInUse,
      ].request();

      if (statuses[Permission.camera] != PermissionStatus.granted ||
          statuses[Permission.locationWhenInUse] != PermissionStatus.granted) {
        return;
      }
    }

    await _initCameras();
    await _getLocation();
  }

  Future<void> _initCameras() async {
    setState(() => _isCameraLoading = true);
    try {
      cameras = await availableCameras();
      if (_selectedCamera == 'local' && cameras != null && cameras!.isNotEmpty) {
        _cameraController = CameraController(
          cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
      }
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
    }
    setState(() => _isCameraLoading = false);
  }

  Future<void> _getLocation() async {
    setState(() => _isLocationLoading = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition();
      setState(() => _position = pos);
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
    }
    setState(() => _isLocationLoading = false);
  }

  Future<void> _sendCommand(String direction) async {
    final url = 'http://192.168.1.50/control?dir=$direction';
    try {
      final response = await http.get(Uri.parse(url));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.statusCode == 200
                ? 'Comando "$direction" enviado'
                : 'Error enviando comando: ${response.statusCode}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final file = await _cameraController!.takePicture();
      if (_position == null) await _getLocation();

      historialFotos.add(FotoHistorial(
        path: file.path,
        fechaHora: DateTime.now(),
        lat: _position?.latitude ?? 0,
        lng: _position?.longitude ?? 0,
      ));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto tomada y guardada en historial')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al tomar foto: $e')));
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Widget _buildCameraView() {
    if (_selectedCamera == 'local') {
      if (_isCameraLoading) return const Center(child: CircularProgressIndicator());
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        return const Center(child: Text('Cámara no disponible'));
      }
      return CameraPreview(_cameraController!);
    } else {
      String url = _selectedCamera == 'esp32Cam' ? esp32Url : otraCamUrl;
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Text('Error cargando cámara remota')),
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
  }

  Widget _buildDirectionButton(String dir, IconData icon) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(18),
        backgroundColor: Colors.indigo.withOpacity(0.8),
      ),
      onPressed: () => _sendCommand(dir),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.withOpacity(0.1),
      appBar: AppBar(title: const Text('Control Cámara'), backgroundColor: Colors.indigo),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCamera,
              decoration: InputDecoration(
                labelText: 'Seleccionar cámara',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.7),
              ),
              items: const [
                DropdownMenuItem(value: 'local', child: Text('Cámara local (PC/Móvil)')),
                DropdownMenuItem(value: 'esp32Cam', child: Text('ESP32-CAM')),
                DropdownMenuItem(value: 'otraCam', child: Text('Otra cámara')),
              ],
              onChanged: (val) async {
                if (val == null) return;
                setState(() => _selectedCamera = val);
                if (_selectedCamera == 'local') {
                  await _initCameras();
                } else {
                  await _cameraController?.dispose();
                  _cameraController = null;
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 6,
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.hardEdge,
                child: _buildCameraView(),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLocationLoading) const CircularProgressIndicator(),
            if (_position != null)
              Text(
                  'Ubicación: Lat ${_position!.latitude.toStringAsFixed(6)}, Lng ${_position!.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 12),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      const SizedBox(),
                      _buildDirectionButton('up', Icons.arrow_upward),
                      const SizedBox(),
                      _buildDirectionButton('left', Icons.arrow_back),
                      ElevatedButton(
                        onPressed: _takePicture,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blueAccent.withOpacity(0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: const Text('Marcar Objetivo'),
                      ),
                      _buildDirectionButton('right', Icons.arrow_forward),
                      const SizedBox(),
                      _buildDirectionButton('down', Icons.arrow_downward),
                      const SizedBox(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Salir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.7),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => verhistorial.dart(historial: historialFotos),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('Ver Historial'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.7),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
