import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'login_page.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  Future<bool> _emailExists(String correo) async {
    final res = await DatabaseHelper.instance.queryUserByEmail(correo);
    return res.isNotEmpty;
  }

  // Función para hashear contraseña con SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _successMessage = '';
      });

      bool exists = await _emailExists(correoController.text.trim());
      if (exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Este correo ya está registrado.';
        });
        return;
      }

      final hashedPassword = _hashPassword(contrasenaController.text.trim());

      Map<String, dynamic> newUser = {
        'nombre': nombreController.text.trim(),
        'correo': correoController.text.trim(),
        'contraseña': hashedPassword,
      };

      try {
        await DatabaseHelper.instance.insertUser(newUser);
        setState(() {
          _isLoading = false;
          _successMessage = 'Registro exitoso. Por favor, inicia sesión.';
          nombreController.clear();
          correoController.clear();
          contrasenaController.clear();
        });

        Future.delayed(const Duration(seconds: 3), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al registrar usuario: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text("Registro"),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Card(
            elevation: 10,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Crea tu cuenta",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade900,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: "Nombre completo",
                        prefixIcon:
                            const Icon(Icons.person_outline, color: Colors.indigo),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: correoController,
                      decoration: InputDecoration(
                        labelText: "Correo electrónico",
                        prefixIcon:
                            const Icon(Icons.email_outlined, color: Colors.indigo),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            !value.contains('@')) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: contrasenaController,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon:
                            const Icon(Icons.lock_outline, color: Colors.indigo),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.all(0),
                              ),
                              onPressed: _submit,
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.indigo, Colors.blueAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Registrarse",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (_successMessage.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        _successMessage,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("¿Ya tienes cuenta? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                            );
                          },
                          child: Text(
                            "Inicia sesión",
                            style: TextStyle(
                              color: Colors.indigo.shade700,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
