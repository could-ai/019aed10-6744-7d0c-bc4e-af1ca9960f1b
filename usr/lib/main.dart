import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MiMascotaApp());
}

class MiMascotaApp extends StatelessWidget {
  const MiMascotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Mascota Virtual',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const PantallaJuego(),
      },
    );
  }
}

class PantallaJuego extends StatefulWidget {
  const PantallaJuego({super.key});

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego> with TickerProviderStateMixin {
  // Estadísticas de la mascota (0.0 a 1.0)
  double hambre = 0.8;
  double suciedad = 0.0; // 0.0 es limpio, 1.0 es muy sucio
  double felicidad = 0.8;
  double energia = 0.8;

  bool tieneBikini = true;
  bool estaDurmiendo = false;
  
  // Estado de animaciones
  double escalaRespiracion = 1.0;
  late AnimationController _respiracionController;
  
  // Loop del juego
  Timer? _gameLoop;

  @override
  void initState() {
    super.initState();
    
    // Configurar animación de respiración
    _respiracionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);

    _respiracionController.addListener(() {
      setState(() {
        escalaRespiracion = _respiracionController.value;
      });
    });

    // Iniciar ciclo de vida (bajan las estadísticas con el tiempo)
    _gameLoop = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (estaDurmiendo) {
        setState(() {
          energia = (energia + 0.05).clamp(0.0, 1.0);
          hambre = (hambre - 0.02).clamp(0.0, 1.0);
        });
      } else {
        setState(() {
          hambre = (hambre - 0.01).clamp(0.0, 1.0);
          suciedad = (suciedad + 0.01).clamp(0.0, 1.0);
          felicidad = (felicidad - 0.01).clamp(0.0, 1.0);
          energia = (energia - 0.01).clamp(0.0, 1.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    _respiracionController.dispose();
    super.dispose();
  }

  // Acciones
  void _alimentar() {
    setState(() {
      hambre = (hambre + 0.2).clamp(0.0, 1.0);
      // Efecto visual o sonido podría ir aquí
      if (hambre > 0.9) _mostrarMensaje("¡Estoy lleno!");
    });
  }

  void _limpiar() {
    setState(() {
      suciedad = (suciedad - 0.3).clamp(0.0, 1.0);
      if (suciedad < 0.1) _mostrarMensaje("¡Ya estoy limpio!");
    });
  }

  void _jugar() {
    if (energia < 0.2) {
      _mostrarMensaje("Estoy muy cansado para jugar...");
      return;
    }
    setState(() {
      felicidad = (felicidad + 0.2).clamp(0.0, 1.0);
      energia = (energia - 0.1).clamp(0.0, 1.0);
      hambre = (hambre - 0.05).clamp(0.0, 1.0);
    });
  }

  void _dormir() {
    setState(() {
      estaDurmiendo = !estaDurmiendo;
    });
  }

  void _cambiarRopa() {
    setState(() {
      tieneBikini = !tieneBikini;
    });
  }

  void _mostrarMensaje(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 500)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(
        title: const Text("Mi Mascota"),
        backgroundColor: Colors.pink[100],
        actions: [
          IconButton(
            icon: Icon(tieneBikini ? Icons.checkroom : Icons.checkroom_outlined),
            onPressed: _cambiarRopa,
            tooltip: "Cambiar Bikini",
          )
        ],
      ),
      body: Column(
        children: [
          // Barras de estado
          _buildStatusBars(),
          
          // Área principal de la mascota
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _jugar,
                onVerticalDragUpdate: (details) {
                  // Frotar para limpiar
                  if (suciedad > 0) {
                    _limpiar();
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // La Mascota
                    Transform.scale(
                      scale: escalaRespiracion,
                      child: CustomPaint(
                        size: const Size(200, 350),
                        painter: MascotaPainter(
                          color: const Color(0xFFFFCCBC), // Color piel
                          tieneBikini: tieneBikini,
                          felicidad: felicidad,
                          estaDurmiendo: estaDurmiendo,
                        ),
                      ),
                    ),
                    
                    // Manchas de suciedad (overlay)
                    if (suciedad > 0.3)
                      Positioned(
                        top: 100,
                        right: 50,
                        child: Icon(Icons.blur_on, size: 40, color: Colors.brown.withOpacity(suciedad)),
                      ),
                    if (suciedad > 0.6)
                      Positioned(
                        bottom: 80,
                        left: 60,
                        child: Icon(Icons.blur_on, size: 50, color: Colors.brown.withOpacity(suciedad)),
                      ),
                      
                    // Indicador de sueño Zzz
                    if (estaDurmiendo)
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Text("Zzz...", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Botones de acción
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildStatusBars() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white54,
      child: Column(
        children: [
          _buildBar("Hambre", hambre, Colors.orange),
          const SizedBox(height: 8),
          _buildBar("Salud/Limpieza", 1.0 - suciedad, Colors.green),
          const SizedBox(height: 8),
          _buildBar("Diversión", felicidad, Colors.blue),
          const SizedBox(height: 8),
          _buildBar("Energía", energia, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[300],
            color: color,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionButton(
            icon: Icons.fastfood,
            label: "Comer",
            color: Colors.orange,
            onTap: _alimentar,
          ),
          _ActionButton(
            icon: Icons.wash,
            label: "Bañar",
            color: Colors.blue,
            onTap: _limpiar,
          ),
          _ActionButton(
            icon: Icons.sports_soccer,
            label: "Jugar",
            color: Colors.green,
            onTap: _jugar,
          ),
          _ActionButton(
            icon: estaDurmiendo ? Icons.wb_sunny : Icons.bed,
            label: estaDurmiendo ? "Despertar" : "Dormir",
            color: Colors.purple,
            onTap: _dormir,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: onTap,
          backgroundColor: color,
          heroTag: label,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// Pintor personalizado para dibujar la mascota
class MascotaPainter extends CustomPainter {
  final Color color;
  final bool tieneBikini;
  final double felicidad;
  final bool estaDurmiendo;

  MascotaPainter({
    required this.color,
    required this.tieneBikini,
    required this.felicidad,
    required this.estaDurmiendo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Dibujar el cuerpo (Forma de cápsula/fálica abstracta pero "cute")
    // Usamos un RRect (Rectángulo redondeado) vertical
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.1, size.width * 0.6, size.height * 0.8),
      Radius.circular(size.width * 0.3),
    );
    
    // Sombra simple
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.85, size.width * 0.6, 20),
      Paint()..color = Colors.black12,
    );

    canvas.drawRRect(bodyRect, paint);

    // Borde suave para dar volumen
    final borderPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(bodyRect, borderPaint);

    // 2. Dibujar Ojos Tiernos
    _drawEyes(canvas, size);

    // 3. Dibujar Boca
    _drawMouth(canvas, size);

    // 4. Dibujar Bikini (si está activado)
    if (tieneBikini) {
      _drawBikini(canvas, size);
    }
  }

  void _drawEyes(Canvas canvas, Size size) {
    if (estaDurmiendo) {
      // Ojos cerrados (líneas curvas)
      final eyePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
        
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.35, size.height * 0.3, 30, 10),
        0, 3.14, false, eyePaint
      );
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.3, 30, 10),
        0, 3.14, false, eyePaint
      );
    } else {
      // Ojos abiertos grandes y tiernos (estilo anime/kawaii)
      final whitePaint = Paint()..color = Colors.white;
      final blackPaint = Paint()..color = Colors.black;
      final shinePaint = Paint()..color = Colors.white.withOpacity(0.8);

      // Ojo izquierdo
      canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.35), 25, whitePaint);
      canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.35), 12, blackPaint);
      canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.33), 5, shinePaint); // Brillo

      // Ojo derecho
      canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.35), 25, whitePaint);
      canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.35), 12, blackPaint);
      canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.33), 5, shinePaint); // Brillo
    }
  }

  void _drawMouth(Canvas canvas, Size size) {
    final mouthPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    if (felicidad > 0.5) {
      // Sonrisa
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.45, size.height * 0.42, 30, 15),
        0, 3.14, false, mouthPaint
      );
    } else {
      // Triste
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.45, size.height * 0.45, 30, 15),
        3.14, 3.14, false, mouthPaint
      );
    }
  }

  void _drawBikini(Canvas canvas, Size size) {
    final bikiniPaint = Paint()
      ..color = Colors.pinkAccent
      ..style = PaintingStyle.fill;
      
    final stringPaint = Paint()
      ..color = Colors.pinkAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Parte de arriba (Top) - Dos triángulos/círculos abstractos
    // Como el personaje es cilíndrico, el bikini va en el "pecho" imaginario
    // Dibujamos una banda o triángulos
    
    // Tiras del cuello
    canvas.drawLine(Offset(size.width * 0.35, size.height * 0.5), Offset(size.width * 0.5, size.height * 0.45), stringPaint);
    canvas.drawLine(Offset(size.width * 0.65, size.height * 0.5), Offset(size.width * 0.5, size.height * 0.45), stringPaint);

    // Copas del bikini
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.55), 15, bikiniPaint);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.55), 15, bikiniPaint);
    
    // Tira central
    canvas.drawLine(Offset(size.width * 0.35, size.height * 0.55), Offset(size.width * 0.65, size.height * 0.55), stringPaint);

    // Parte de abajo (Bottom) - Triángulo invertido en la base
    final path = Path();
    path.moveTo(size.width * 0.25, size.height * 0.75); // Izquierda
    path.lineTo(size.width * 0.75, size.height * 0.75); // Derecha
    path.lineTo(size.width * 0.5, size.height * 0.88);  // Abajo centro
    path.close();
    
    canvas.drawPath(path, bikiniPaint);
    
    // Tiras laterales de la parte de abajo
    canvas.drawLine(Offset(size.width * 0.25, size.height * 0.75), Offset(size.width * 0.2, size.height * 0.73), stringPaint);
    canvas.drawLine(Offset(size.width * 0.75, size.height * 0.75), Offset(size.width * 0.8, size.height * 0.73), stringPaint);
  }

  @override
  bool shouldRepaint(covariant MascotaPainter oldDelegate) {
    return oldDelegate.felicidad != felicidad || 
           oldDelegate.tieneBikini != tieneBikini ||
           oldDelegate.estaDurmiendo != estaDurmiendo;
  }
}
