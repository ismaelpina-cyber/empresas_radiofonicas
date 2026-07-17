import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class SurTvPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const SurTvPlayerScreen({super.key, required this.videoUrl});

  @override
  State<SurTvPlayerScreen> createState() => _SurTvPlayerScreenState();
}

class _SurTvPlayerScreenState extends State<SurTvPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _tieneError = false;
  bool _fuePausado =
      false; // Bandera para saber si el usuario pausó manualmente

  @override
  void initState() {
    super.initState();
    _inicializarReproductor();
  }

  Future<void> _inicializarReproductor() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoPlayerController.initialize();

      // Escuchamos los cambios del reproductor (play, pause, etc.)
      _videoPlayerController.addListener(_escucharCambiosReproductor);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        autoPlay: true,
        looping: false,
        isLive: true, // Configura el reproductor optimizado para TV en directo
        allowedScreenSleep: false,
        allowFullScreen: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFD50000),
          handleColor: const Color(0xFFD50000),
          bufferedColor: Colors.white24,
          backgroundColor: Colors.white12,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFD50000)),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.signal_wifi_off,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'La señal no está disponible en este momento.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      setState(() {});
    } catch (e) {
      debugPrint("Error inicializando el video: $e");
      setState(() {
        _tieneError = true;
      });
    }
  }

  // Esta función es la "magia" que soluciona tu problema
  void _escucharCambiosReproductor() {
    if (!mounted) return;

    final isPlaying = _videoPlayerController.value.isPlaying;

    if (!isPlaying) {
      // Si el usuario presiona PAUSA, marcamos que fue pausado
      _fuePausado = true;
    } else if (isPlaying && _fuePausado) {
      // Si le da a PLAY de nuevo tras haber estado pausado:
      _fuePausado = false;

      // Forzamos al reproductor a ir al final del búfer (el directo absoluto)
      final duracionTotal = _videoPlayerController.value.duration;
      _videoPlayerController.seekTo(duracionTotal);

      // En algunos servidores de streaming, seekTo al final no basta y se necesita
      // reconectar la fuente de datos para "limpiar" el retraso acumulado.
      // Si notas que no salta del todo al presente, descomenta las líneas de abajo:
      /*
      _videoPlayerController.removeListener(_escucharCambiosReproductor);
      _videoPlayerController.dispose();
      _chewieController?.dispose();
      _inicializarReproductor();
      */
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _videoPlayerController.removeListener(_escucharCambiosReproductor);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        title: const Text(
          'SUR TV EN VIVO',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF161824),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _tieneError
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 50),
                  SizedBox(height: 16),
                  Text(
                    'No se pudo conectar con el servidor',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              )
            : _chewieController != null &&
                  _chewieController!.videoPlayerController.value.isInitialized
            ? AspectRatio(
                aspectRatio: _videoPlayerController.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFD50000)),
                  SizedBox(height: 16),
                  Text(
                    'Conectando con la señal en vivo...',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
      ),
    );
  }
}
