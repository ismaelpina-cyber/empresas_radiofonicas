import 'package:just_audio_background/just_audio_background.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
// ignore: depend_on_referenced_packages
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sur_tv_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setApplicationSwitcherDescription(
    const ApplicationSwitcherDescription(label: 'Empresas Radiofónicas'),
  );

  // 1. Inicializamos primero el servicio de fondo de forma ultra segura
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId:
          'com.example.empresas_radiofonicas.channel.audio',
      androidNotificationChannelName: 'Reproductor de Radio',
      androidNotificationOngoing: true,

      // 🟢 CORRECCIÓN DEFINITIVA: Apunta al archivo blanco plano que creamos en drawable
      androidNotificationIcon: 'drawable/ic_notification',
      androidNotificationClickStartsActivity: true,
      // 🚀 AGREGA ESTO: Esto obliga a que los controles siempre estén visibles
      androidShowNotificationBadge: true,
    );
  } catch (e) {
    debugPrint("Advertencia: El servicio de segundo plano falló: $e");
  }

  // 2. Ejecutamos la app
  runApp(const MyApp());
}

// Función separada para no bloquear el inicio de la app
Future<void> _solicitarPermisoNotificaciones() async {
  try {
    final status = await Permission.notification.status;
    if (status.isDenied || status.isLimited) {
      await Permission.notification.request();
    }
  } catch (e) {
    debugPrint("Error al solicitar permisos: $e");
  }
}

// En tu primera pantalla (o en un init dentro del main)
Future<void> checkPermissions() async {
  var status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Empresas Radiofónicas',

      // ☀️ TEMA CLARO INTELIGENTE
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF0000), // Tu rojo característico
          surface: Color(
            0xFFF5F6FA,
          ), // Fondo general de la app (Gris/blanco suave)
          onSurface: Color(
            0xFF1E2022,
          ), // Color para textos e iconos principales sobre el fondo
          surfaceContainer: Colors
              .white, // Color para TARJETAS y contenedores (Blanco puro en el día)
        ),
      ),

      // 🌙 TEMA OSCURO INTELIGENTE
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF0000), // Tu rojo característico
          surface: Color(
            0xFF090A0F,
          ), // Fondo general de la app (Tu Negro Espacial Premium)
          onSurface: Colors
              .white, // Color para textos e iconos principales en la noche
          surfaceContainer: Color(
            0xFF161823,
          ), // Color para TARJETAS y contenedores (Un negro sutilmente más claro)
        ),
      ),

      themeMode: ThemeMode.system, // Escucha al teléfono del usuario
      home: const HomeScreen(),
    );
  }
}

class AnimatedSoundWave extends StatefulWidget {
  final Color color;
  final bool isPlaying;
  final bool isSyncing;

  const AnimatedSoundWave({
    super.key,
    required this.color,
    required this.isPlaying,
    required this.isSyncing,
  });

  @override
  State<AnimatedSoundWave> createState() => _AnimatedSoundWaveState();
}

class _AnimatedSoundWaveState extends State<AnimatedSoundWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _baseHeights = [8.0, 16.0, 12.0, 18.0, 10.0];

  // 🟢 Tu excelente getter que calcula si debe animarse usando las propiedades reales del widget
  bool get _deberiaAnimar => widget.isPlaying && !widget.isSyncing;

  // Función para pedir permisos de notificaciones de forma segura
  Future<void> pedirPermisoNotificaciones() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  @override
  void initState() {
    super.initState();

    // 🟢 Cambiamos "pedirPermisoNotificaciones();" por el nombre exacto de tu función:
    _solicitarPermisoNotificaciones();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Si al iniciar la pantalla la radio ya está sonando, empezamos la animación
    if (_deberiaAnimar) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedSoundWave oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🟢 CLAVE: Evaluamos '_deberiaAnimar' (tu getter local) en lugar de 'widget.deberiaAnimar'
    if (_deberiaAnimar && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!_deberiaAnimar && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(_baseHeights.length, (index) {
            double factor =
                0.3 +
                0.7 *
                    (0.5 +
                        0.5 *
                            (index % 2 == 0
                                ? _controller.value
                                : 1.0 - _controller.value));

            if (!_deberiaAnimar) factor = 0.2;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.0),
              width: 2.5,
              height: _baseHeights[index] * factor,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int? _indiceActual;
  bool _isPlaying = false;
  bool _isSyncing = false;
  String? _liveMetaTitle;
  String? _liveArtUrl;

  // 1. AGREGA ESTA LÍNEA AQUÍ:
  Timer? _whatsappTimer;
  bool _mostrarTextoWhatsapp = true;
  bool _mostrarWhatsApp =
      false; // Agrega esta también por si acaso no la habías declarado

  Timer? _timerConsultaCancion;
  final AudioPlayer _audioPlayer = AudioPlayer();
  // ✅ Declaración correcta: inicializada en null explícitamente
  // ✅ Limpio, elegante y estilísticamente correcto para Dart
  ConcatenatingAudioSource? _playlist;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Si el usuario desliza la app hacia arriba en el menú de recientes para matarla
    if (state == AppLifecycleState.detached) {
      _apagarRadioYSalir();
    }
  }

  // Apaga el reproductor y borra la notificación de Android obligatoriamente
  void _apagarRadioYSalir() {
    try {
      _timerConsultaCancion?.cancel();
      _audioPlayer.stop();
      _audioPlayer.dispose();
    } catch (e) {
      debugPrint("El reproductor ya estaba cerrado: $e");
    }
  }

  // El cartel estético que pregunta si desea salir
  Future<bool> _mostrarDialogoSalir(BuildContext context) async {
    // 1. Detectamos si la aplicación está actualmente en modo oscuro
    final bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    // 2. Obtenemos el color de texto adecuado según el tema (Blanco en oscuro, Negro/Gris en claro)
    // Usamos 'onSurface' que está garantizado que existe en todos los temas de Flutter
    final Color colorTextoBase = Theme.of(context).colorScheme.onSurface;
    final Color colorTextoConOpacidad = colorTextoBase.withValues(alpha: 0.9);

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        // Si está oscuro usa tu color personalizado, si está claro usa el fondo del Scaffold
        backgroundColor: esOscuro
            ? const Color(0xFF161824)
            : Theme.of(dialogContext).scaffoldBackgroundColor,

        surfaceTintColor:
            Colors.transparent, // Evita tintes raros de Material 3
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.exit_to_app, color: Colors.amber),
            const SizedBox(width: 10),
            Text(
              '¿Deseas salir?',
              style: TextStyle(
                color: colorTextoBase, // 🌟 Aplicado de forma directa y segura
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Si decides salir, la transmisión de la radio se apagará por completo.',
          style: TextStyle(
            color:
                colorTextoConOpacidad, // 🌟 Aplicado con opacidad sin errores
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'NO',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'SÍ',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }
  //botoon whassapp

  // Intercepta el botón de atrás físico del teléfono
  void _manejarBotonAtras() async {
    final deberiaSalir = await _mostrarDialogoSalir(context);
    if (deberiaSalir) {
      _apagarRadioYSalir(); // Frena el sonido de golpe
      SystemNavigator.pop(); // Cierra la app por completo
    }
  }

  // ==========================================
  // TU LISTA DE EMISORAS ORIGINAL MODIFICADA
  // ==========================================
  final List<Map<String, dynamic>> emisoras = [
    {
      // ... Tu lista sigue aquí abajo ...
      'nombre': 'PALMA\n90.7 FM',
      'color': const Color(0xFF4CAF50),
      'esVideo': false,
      'logo': 'palma',
      'key': 'PALMA',
      'streamUrl': 'https://radiordomi.com/8030/stream',
      "telefono": "18095244907",
    },
    {
      'nombre': 'MEGA\n105.1 FM',
      'color': const Color(0xFF1E88E5),
      'esVideo': false,
      'logo': 'mega',
      'key': 'MEGA',
      'streamUrl': 'https://radiordomi.com/8122/stream',
      "telefono": "18095246342",
    },
    {
      'nombre': 'MI 97\nFM',
      'color': const Color(0xFFFF9800),
      'esVideo': false,
      'logo': 'mi97',
      'key': 'MI 97',
      'streamUrl': 'https://radiordomi.com/8160/stream',
      "telefono": "18095243497",
    },
    {
      'nombre': 'ESCALA\n106 FM',
      'color': const Color(0xFF8BC34A),
      'esVideo': false,
      'logo': 'escala',
      'key': 'ESCALA',
      'streamUrl': 'https://radiordomi.com/8204/stream',
      "telefono": "18095273211",
    },
    {
      'nombre': 'COSMOS\n99.1 FM',
      'color': const Color(0xFF00BCD4),
      'esVideo': false,
      'logo': 'cosmos',
      'key': 'COSMOS',
      'streamUrl': 'https://radiordomi.com/8626/stream',
      "telefono": "18095213363",
    },
    {
      'nombre': 'ENAMORADA\n99.9 FM',
      'color': const Color(0xFFE91E63),
      'esVideo': false,
      'logo': 'enamorada99',
      'key': 'ENAMORADA',
      'streamUrl': 'https://radiordomi.com/8628/stream',
      "telefono": "18095242476",
    },
    {
      'nombre': 'TRUENO\n99 FM',
      'color': const Color(0xFF3F51B5),
      'esVideo': false,
      'logo': 'trueno',
      'key': 'TRUENO',
      'streamUrl': 'https://radiordomi.com/8630/stream',
      "telefono": "18095240148",
    },
    {
      'nombre': 'PESÁ\n92.3 FM',
      'color': const Color(0xFFFF5722),
      'esVideo': false,
      'logo': 'pesa',
      'key': 'PESÁ',
      'streamUrl': 'https://radiordomi.com/8632/stream',
      "telefono": "18092483028",
    },
    {
      'nombre': 'RADIO\nNEYBA',
      'color': const Color(0xFF009688),
      'esVideo': false,
      'logo': 'neyba',
      'key': 'RADIO NEYBA',
      'streamUrl': 'https://radiordomi.com/8634/stream',
      "telefono": "",
    },
    {
      'nombre': 'RADIO\nBARAHONA 970',
      'color': const Color(0xFF9C27B0),
      'esVideo': false,
      'logo': 'radiobarahona970',
      'key': 'RADIO BARAHONA 970',
      'streamUrl': 'https://radiordomi.com/8020/stream',
      "telefono": "",
    },
    {
      'nombre': 'RADIO\n1410',
      'color': const Color(0xFF795548),
      'esVideo': false,
      'logo': 'radio1410',
      'key': 'RADIO 1410',
      'streamUrl': 'https://radiordomi.com/8636/stream',
      "telefono": "",
    },
    {
      'nombre': 'VIBRA\nFM',
      'color': const Color(0xFFE91E63),
      'esVideo': false,
      'logo': 'vibra',
      'key': 'VIBRA',
      'streamUrl': 'https://radiordomi.com/8646/stream',
      "telefono": "",
    },
    {
      'nombre': 'RADIO\nBARAHONA 4930',
      'color': const Color(0xFF673AB7),
      'esVideo': false,
      'logo': 'radiobarahona4930',
      'key': 'RADIO BARAHONA 4930',
      'streamUrl': 'https://radiordomi.com/8020/stream',
      "telefono": "",
    },
    {
      'nombre': 'RADIO\nBARAHONA 1470',
      'color': const Color(0xFF3F51B5),
      'esVideo': false,
      'logo': 'radiobarahona1470',
      'key': 'RADIO BARAHONA 1470',
      'streamUrl': 'https://radiordomi.com/8020/stream',
      "telefono": "",
    },
    {
      'nombre': 'RADIO\nCARACOL',
      'color': const Color(0xFF00ACC1),
      'esVideo': false,
      'logo': 'radiocaracol',
      'key': 'RADIO CARACOL',
      'streamUrl': 'https://radiordomi.com/8640/stream',
      "telefono": "",
    },
    {
      'nombre': 'RADIO\nJIMANÍ',
      'color': const Color(0xFF43A047),
      'esVideo': false,
      'logo': 'radiojimani',
      'key': 'RADIO JIMANÍ',
      'streamUrl': 'https://radiordomi.com/8642/stream',
      "telefono": "",
    },
    {
      'nombre': 'RADIO\nPEDERNALES',
      'color': const Color(0xFFF4511E),
      'esVideo': false,
      'logo': 'radiopedernales',
      'key': 'RADIO PEDERNALES',
      'streamUrl': 'https://radiordomi.com/8638/stream',
      "telefono": "",
    },
    {
      'nombre': 'ENAMORADA\n107.1 FM',
      'color': const Color(0xFFFF1744),
      'esVideo': false,
      'logo': 'enamorada107',
      'key': 'ENAMORADA 107.1',
      'streamUrl': 'https://radiordomi.com/8644/stream',
      "telefono": "",
    },
    {
      'nombre': 'SUPRA\nDIGITAL',
      'color': const Color(0xFF00E5FF),
      'esVideo': false,
      'logo': 'supra',
      'key': 'SUPRA DIGITAL',
      'streamUrl': 'https://radiordomi.com/8682/stream',
      "telefono": "",
    },
    {
      'nombre': 'RETRO\nRADIO',
      'color': const Color(0xFFFFEA00),
      'esVideo': false,
      'logo': 'retro',
      'key': 'RETRO RADIO',
      'streamUrl': 'https://radiordomi.com/8686/stream',
      "telefono": "",
    },
    {
      'nombre': 'SUR TV\nONLINE',
      'color': const Color(0xFFD50000),
      'esVideo': true,
      'logo': 'surtv',
      'key': 'SUR TV ONLINE',
      'streamUrl':
          'https://ss2.tvrdomi.com:1936/eradiofonicas/eradiofonicas/playlist.m3u8',
      "telefono": "",
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 🛡️ [NUEVO]: Cargamos la playlist de manera asíncrona usando los assets locales
    _inicializarPlaylistConLogosLocales();

    // 3. Control del estado de la reproducción (Play/Pause y Sincronización)
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;

          // Si ya está reproduciéndose activamente (playing es true),
          // forzamos a que '_isSyncing' sea false para que la barra de sonido
          // se active y se quite el círculo de carga.
          if (state.playing) {
            _isSyncing = false;
          } else {
            // Solo muestra el icono de "cargando" si no está sonando y está cargando/almacenando búfer
            _isSyncing =
                _indiceActual != null &&
                (state.processingState == ProcessingState.buffering ||
                    state.processingState == ProcessingState.loading);
          }
        });
      }
    });

    // 4. Control de la emisora seleccionada (¡SOLO REACCIONA SI SE ESTÁ REPRODUCIENDO!)
    _audioPlayer.currentIndexStream.listen((index) {
      if (mounted && index != null) {
        // Verificamos si el reproductor está intentando sonar o ya suena
        final bool estaReproduciendoActivo =
            _audioPlayer.playing ||
            _audioPlayer.processingState == ProcessingState.buffering ||
            _audioPlayer.processingState == ProcessingState.ready;

        // Si hay actividad real y es un índice diferente al que tenemos guardado:
        if (estaReproduciendoActivo && index != _indiceActual) {
          setState(() {
            _indiceActual = index;
            _isSyncing = true;
            _isPlaying = false;
            _liveMetaTitle = "Sintonizando...";
            _liveArtUrl = null;
          });

          // Cancelamos cualquier consulta anterior de canciones en bucle para que no se acumulen
          _timerConsultaCancion?.cancel();

          // ✅ Corrección: usamos la variable global 'emisoras' directamente
          _iniciarMonitoreoDeCanciones(emisoras[index]['streamUrl'] as String);
        }
      }
    });
  }
  // Esto se declara arriba en tu clase State

  // 🟢 BOTON DE WHATSAPP INTELIGENTE (Con redirección automática a Soporte)
  Future<void> abrirWhatsApp(String telefono, String nombreEmisora) async {
    // Si el teléfono de la emisora está vacío, redirigimos directamente a Soporte
    if (telefono.isEmpty) {
      await _abrirSoporteTecnico(nombreEmisora);
      return;
    }

    // 1. Limpiamos el número de la emisora por seguridad
    final String telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d]'), '');

    final String mensaje = Uri.encodeComponent(
      "¡Hola! Estoy escuchando $nombreEmisora y quería escribirles.",
    );

    final Uri whatsappAppUrl = Uri.parse(
      "whatsapp://send?phone=$telefonoLimpio&text=$mensaje",
    );

    final Uri whatsappWebUrl = Uri.parse(
      "https://wa.me/$telefonoLimpio?text=$mensaje",
    );

    try {
      // Intentamos abrir la App Nativa directamente
      bool launched = await launchUrl(
        whatsappAppUrl,
        mode: LaunchMode.externalApplication,
      );

      // Si no funcionó, intentamos la Web
      if (!launched) {
        await launchUrl(whatsappWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      await _abrirSoporteTecnico(nombreEmisora);
    }
  }

  // 🛠️ FUNCIÓN PRIVADA DE RESPALDO: SOPORTE TÉCNICO
  Future<void> _abrirSoporteTecnico(String nombreEmisora) async {
    // 📞 COLOCA AQUÍ TU NÚMERO DE SOPORTE PERSONAL (Con código de país, sin +)
    final String miNumeroSoporte = "18294701913";

    final String mensajeSoporte = Uri.encodeComponent(
      "¡Hola! Tuve un inconveniente al intentar contactar a la emisora *$nombreEmisora* desde la App y necesito ayuda.",
    );

    final Uri soporteAppUrl = Uri.parse(
      "whatsapp://send?phone=$miNumeroSoporte&text=$mensajeSoporte",
    );
    final Uri soporteWebUrl = Uri.parse(
      "https://wa.me/$miNumeroSoporte?text=$mensajeSoporte",
    );

    try {
      if (await canLaunchUrl(soporteAppUrl)) {
        await launchUrl(soporteAppUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(soporteWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Si ya de plano no se puede abrir WhatsApp de ninguna forma en el teléfono
      // (por ejemplo, si no tiene internet), puedes mostrar un Toast o un print.
    }
  }

  // ==========================================
  // METODOS DE LOGOS Y PLAYLIST DE LA RADIO
  // ==========================================

  // 1. Inicializar Playlist con Logos Locales (Corregida y segura)
  Future<void> _inicializarPlaylistConLogosLocales() async {
    List<AudioSource> fuentesDeAudio = [];

    for (var em in emisoras) {
      final String logoOriginal = em['logo'] as String? ?? 'logo';
      final String nombreLogoLimpio = logoOriginal
          .replaceAll('.png', '')
          .toLowerCase()
          .trim();

      Uri? logoUriFisico;
      try {
        // Intentamos extraer el logo localmente de forma segura
        logoUriFisico = await _obtenerUriDelLogoLocal(nombreLogoLimpio);
      } catch (e) {
        debugPrint("Error extrayendo logo para ${em['nombre']}: $e");
        logoUriFisico = null; // Si falla, queda nulo para no romper los botones
      }

      fuentesDeAudio.add(
        AudioSource.uri(
          Uri.parse(em['streamUrl'] as String),
          tag: MediaItem(
            id: em['key'] as String,
            album: "Empresas Radiofónicas",
            title: (em['nombre'] as String).replaceAll('\n', ' '),
            artist: "La Gran Cadena del Sur Dominicano",
            playable: true,
            duration: null,
            artUri:
                logoUriFisico, // Asegúrate de que esto sea un objeto Uri válido
            extras: const {
              'live': true, // Esto es suficiente para indicar que es radio
            },
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _playlist = ConcatenatingAudioSource(children: fuentesDeAudio);
      });

      try {
        // Cargamos la playlist de forma segura
        await _audioPlayer.setAudioSource(
          _playlist!,
          initialIndex: 0,
          preload: true,
        );
      } catch (e) {
        debugPrint("Error al configurar fuente de audio: $e");
      }
    }
  }

  // 2. Extraer Logo a Almacenamiento Temporal (Corregida y rápida)
  Future<Uri?> _obtenerUriDelLogoLocal(String nombreLogo) async {
    try {
      final byteData = await rootBundle.load('assets/logos/$nombreLogo.png');
      final tempDir = await getTemporaryDirectory();

      final file = File('${tempDir.path}/$nombreLogo.png');

      // 🛡️ Optimización clave: Si el archivo ya existe y tiene tamaño, no lo reescribas.
      // Esto evita que Android se confunda reescribiendo el archivo mientras se reproduce.
      if (await file.exists() && (await file.length()) > 0) {
        return file.uri;
      }

      // Escribimos los bytes de manera síncrona y segura
      await file.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
        flush:
            true, // Forzamos a que el sistema operativo guarde el archivo en disco YA
      );

      return file.uri;
    } catch (e) {
      debugPrint(
        "No se pudo cargar el asset 'assets/logos/$nombreLogo.png': $e",
      );
      return null; // Retornamos null para que la app continúe sin logo pero con botones activos
    }
  }

  // ==========================================
  //  ¡AQUÍ PEGAS EL PASO 2! (Justo abajo de initState)
  // ==========================================
  Widget _buildBotonCapsula({
    required String texto,
    required Color colorInicio,
    required Color colorFin,
    required Color colorBorde,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorBorde, width: 1.5),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colorInicio, colorFin],
              ),
              boxShadow: [
                BoxShadow(
                  // 🧠 Si es modo oscuro usa un blanco muy tenue, si es claro usa un negro sutil
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                texto,
                // 💡 Recuerda quitar el "const" antes de TextStyle porque ahora usamos código dinámico
                style: TextStyle(
                  // 🧠 Texto oscuro en el día, blanco en la noche
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  shadows: Theme.of(context).brightness == Brightness.dark
                      ? [
                          const Shadow(
                            color: Colors.black38,
                            offset: Offset(1, 1),
                            blurRadius: 1,
                          ),
                        ]
                      : null, // Sin sombra en modo claro para que se vea limpio
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 1. Quitamos el observador de la app para que no gaste memoria
    WidgetsBinding.instance.removeObserver(this);
    _whatsappTimer?.cancel();

    // 2. Apagamos la radio y liberamos los recursos de forma segura
    _apagarRadioYSalir();

    super.dispose();
  }

  void _abrirEnlace(BuildContext context, String tipo, String url) async {
    final Uri uri = Uri.parse(url);

    try {
      // Aquí ocurre la pausa asíncrona (el "async gap")
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint('Error al intentar abrir el enlace ($tipo): $e');

      // 🛡️ CONTROL DE SEGURIDAD (La solución al warning):
      // Si el usuario cerró la app o cambió de pantalla durante el await, detenemos todo aquí.
      if (!context.mounted) return;

      // Si la pantalla sigue activa, entonces sí es seguro mostrar el error.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir el enlace de $tipo'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _extraerPuerto(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        final primerSegmento = uri.pathSegments.first;
        if (int.tryParse(primerSegmento) != null) {
          return primerSegmento;
        }
      }
    } catch (e) {
      // Ignorar silenciosamente
    }
    return '';
  }

  String _limpiarTextoMetadatos(String rawTitle) {
    String titulo = rawTitle.trim();
    final RegExp prefijoRegExp = RegExp(
      r'^(now\s*on\s*air|now\s*playing|nowonair)\s*:\s*',
      caseSensitive: false,
    );
    titulo = titulo.replaceFirst(prefijoRegExp, '');
    final RegExp parentesisRegExp = RegExp(
      r'\s*\([^)]*\)\s*$',
      caseSensitive: false,
    );
    titulo = titulo.replaceFirst(parentesisRegExp, '');
    return titulo.trim();
  }

  Future<void> _consultarCancionEnVivo(String urlStream) async {
    final puerto = _extraerPuerto(urlStream);
    if (puerto.isEmpty) return;

    try {
      final apiUri = Uri.parse(
        'https://radiordomi.com/cp/get_info.php?p=$puerto',
      );
      final response = await http
          .get(apiUri)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data != null) {
          setState(() {
            if (data['title'] != null &&
                data['title'].toString().trim().isNotEmpty) {
              String rawTitle = data['title'].toString().trim();
              if (rawTitle.toLowerCase() == "stream" ||
                  rawTitle.toLowerCase() == "live" ||
                  rawTitle.toLowerCase() == "offline") {
                _liveMetaTitle = null;
              } else {
                _liveMetaTitle = _limpiarTextoMetadatos(rawTitle);
              }
            } else {
              _liveMetaTitle = null;
            }

            if (data['art'] != null &&
                data['art'].toString().startsWith('http')) {
              _liveArtUrl = data['art'].toString().trim();
            } else {
              _liveArtUrl = null;
            }
          });
        }
      }
    } catch (e) {
      // Ignorar silenciosamente
    }
  }

  void _iniciarMonitoreoDeCanciones(String urlStream) {
    _timerConsultaCancion?.cancel();
    _consultarCancionEnVivo(urlStream);

    _timerConsultaCancion = Timer.periodic(const Duration(seconds: 15), (
      timer,
    ) {
      if (mounted && _isPlaying) {
        _consultarCancionEnVivo(urlStream);
      }
    });
  }

  Future<void> _reproducirConSincronizacion(int index) async {
    try {
      _timerConsultaCancion?.cancel();

      setState(() {
        _isSyncing = true;
        _isPlaying = false;
        _indiceActual = index;
        _liveMetaTitle = "Sintonizando...";
        _liveArtUrl = null;
      });

      // 1. Detiene la reproducción actual para liberar cualquier bloqueo de red nativo
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }

      // 🟢 CORRECCIÓN: Eliminamos la variable local 'logoUriFisico' que no se usaba en el flujo de la playlist.
      // (El Plan B abajo sigue teniendo su propio 'logoUriFisicoPlanB' que SÍ se usa correctamente).

      // 2. 🛡️ IMPORTANTE: Si por alguna razón Android perdió la playlist en memoria, la reasignamos.
      if (_audioPlayer.audioSource == null) {
        await _audioPlayer.setAudioSource(_playlist!, preload: false);
      }

      // 3. Verificamos que el índice solicitado esté dentro del rango real de la playlist
      if (index >= 0 && index < _playlist!.length) {
        await _audioPlayer.seek(Duration.zero, index: index);
      } else {
        throw Exception(
          "El índice de emisora ($index) está fuera del rango de la playlist.",
        );
      }

      // 4. Pequeña pausa de seguridad (150ms) para que el búfer de Android se estabilice
      await Future.delayed(const Duration(milliseconds: 150));

      if (mounted) {
        // Iniciamos el monitoreo de metadatos de la emisora elegida
        _iniciarMonitoreoDeCanciones(emisoras[index]['streamUrl'] as String);

        // 5. Intentamos reproducir de manera controlada
        await _audioPlayer.play();

        // Mostramos el botón de WhatsApp temporal
        _activarWhatsAppTemporal();
      }
    } catch (e) {
      debugPrint("🚨 Error crítico al cambiar de emisora: $e");

      // 🛡️ PLAN B: Si la playlist por alguna razón falla el 'seek',
      // cargamos la emisora de forma individual con un MediaItem ultra seguro y explícito.
      try {
        debugPrint(
          "Sintonizando mediante carga directa individual (Plan B)...",
        );
        final streamUrl = emisoras[index]['streamUrl'] as String;

        final Uri? logoUriFisicoPlanB = await _obtenerUriDelLogoLocal(
          emisoras[index]['key'] as String,
        );

        await _audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(streamUrl.trim()),
            tag: MediaItem(
              id: emisoras[index]['key'] as String? ?? streamUrl,
              album: "Empresas Radiofónicas",
              title:
                  emisoras[index]['nombre']?.replaceAll('\n', ' ') ??
                  'Radio en Vivo',
              artist: "La Gran Cadena del Sur Dominicano",
              playable: true,
              artUri: logoUriFisicoPlanB,
              extras: const {'live': true},
            ),
          ),
          preload: true,
        );

        if (mounted) {
          await _audioPlayer.play();
        }
      } catch (errFallback) {
        debugPrint("Fallo también el plan B: $errFallback");
      }

      if (mounted) {
        setState(() {
          _isSyncing = false;
          _isPlaying = _audioPlayer.playing;
          _liveMetaTitle = "Reconectando...";
        });
      }
    }
  }

  Future<void> _pausarAudio() async {
    _timerConsultaCancion?.cancel();
    setState(() {
      _isPlaying = false;
      _isSyncing = false;
      _liveMetaTitle = null;
      _liveArtUrl = null;
    });
    try {
      await _audioPlayer.stop();
    } catch (e) {
      // Ignorar silenciosamente
    }
  }

  void _irAtras() {
    if (_indiceActual == null) return;
    int target = (_indiceActual! - 1 + emisoras.length) % emisoras.length;
    _reproducirConSincronizacion(target);
  }

  void _irAlante() {
    if (_indiceActual == null) return;
    int target = (_indiceActual! + 1) % emisoras.length;
    _reproducirConSincronizacion(target);
  }

  String _obtenerTextoEstado(Map<String, dynamic>? emisoraActual) {
    if (_isSyncing) {
      return 'Sincronizando señal en vivo...';
    }
    if (_isPlaying) {
      if (_liveMetaTitle == null ||
          _liveMetaTitle == "Conectando al servidor...") {
        final nombreCompleto =
            emisoraActual?['nombre'] as String? ?? 'Radio en Vivo';
        final nombreEmisora = nombreCompleto.replaceAll('\n', ' ');
        return 'En Vivo • $nombreEmisora';
      }
      return _liveMetaTitle!;
    }
    return 'Señal Pausada';
  }

  int indiceSeleccionado = 0; // La emisora que está sonando ahora mismo

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    int columnas = 3;
    if (screenWidth > 900) {
      columnas = 6;
    } else if (screenWidth > 600) {
      columnas = 4;
    }

    double playerHeight = screenHeight * 0.26;
    if (playerHeight > 210) playerHeight = 210;
    if (playerHeight < 170) playerHeight = 170;

    bool reproductorActivo = _indiceActual != null;
    Map<String, dynamic>? emisoraActual = reproductorActivo
        ? emisoras[_indiceActual!]
        : null;

    // Aquí envolvemos el Scaffold con el PopScope de forma limpia:
    return PopScope(
      canPop: false, // Bloquea que el sistema cierre o minimice la app solo
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Llamamos a tu función para que ella haga todo el trabajo
        _manejarBotonAtras();
      },
      child: Scaffold(
        // 🌟 Esto solucionará el fondo negro detrás de todo en modo claro:
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(
                0xFF12131A,
              ) // Color de fondo en modo oscuro (puedes ajustar el código de color a tu gusto)
            : const Color(
                0xFFFFFFFF,
              ), // Color de fondo claro (gris muy sutil y premium para el día)
        // ... aquí continúa tu código (appBar, body, etc.)
        appBar: AppBar(
          centerTitle: true,
          backgroundColor:
              Theme.of(context).appBarTheme.backgroundColor ??
              (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF12131A)
                  : Colors.white),
          elevation: 0,
          iconTheme: IconThemeData(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),

          // El icono limpio flotando a la derecha
          actions: [
            AnimatedOpacity(
              opacity: _mostrarWhatsApp ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: IgnorePointer(
                ignoring: !_mostrarWhatsApp,
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: 16.0,
                  ), // Margen limpio al borde de la pantalla
                  child: Center(
                    // 🟢 La magia: Si '_mostrarTextoWhatsapp' es true mide 150 (óvalo), si es false mide 42 (tu círculo original)
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      width: _mostrarTextoWhatsapp ? 150 : 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(
                          Radius.circular(21),
                        ), // Mantiene los bordes redondeados en ambos estados
                        color: Color(0xFF25D366), // Verde exacto de WhatsApp
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black38, // Sombra sutil premium
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap:
                                _abrirWhatsApp, // Tu función actual para abrir el enlace
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 🟢 ICONO DE WHATSAPP (Siempre visible)
                                  const FaIcon(
                                    FontAwesomeIcons.whatsapp,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  // 🟢 TEXTO ANIMADO (Aparece y desaparece suavemente)
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: _mostrarTextoWhatsapp ? 1.0 : 0.0,
                                    child: _mostrarTextoWhatsapp
                                        ? const Padding(
                                            padding: EdgeInsets.only(left: 8.0),
                                            child: Text(
                                              "Pide tu música",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(), // No ocupa espacio cuando se oculta
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                width: double.infinity,
                height: reproductorActivo ? playerHeight : 80,

                // 💡 El color cambia dinámicamente y se animará suavemente al cambiar el tema
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(
                          0xFF12131A,
                        ) // Color original para el Modo Oscuro
                      : const Color(
                          0xFFFFFFFF,
                        ), // Blanco puro para el Modo Claro
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.fastOutSlowIn,
                      height: reproductorActivo ? 50 : 60,
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 300,
                          ), // Hace que el cambio de tamaño sea súper suave
                          curve: Curves.easeInOut,
                          // Si el reproductor está activo se muestra más pequeño (ej. 24), si está cerrado se ve más grande (ej. 45)
                          height: reproductorActivo ? 50 : 60,
                          child: Image.asset(
                            'assets/logos/logom.png',
                            fit: BoxFit
                                .contain, // Mantiene la proporción para que no se estire ni se deforme
                          ),
                        ),
                      ),
                    ),

                    if (reproductorActivo && emisoraActual != null) ...[
                      const SizedBox(height: 8),
                      Expanded(
                        child: AnimatedOpacity(
                          opacity: reproductorActivo ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF12131A)
                                  : const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                // 💡 Corregido: Cambiado '?[' por '[' ya que no puede ser nulo
                                color:
                                    ((emisoraActual['color'] as Color?) ??
                                            Colors.blue)
                                        .withValues(
                                          alpha:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? 0.58
                                              : 0.35,
                                        ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  // 💡 Corregido: Cambiado '?[' por '[' aquí también
                                  color:
                                      ((emisoraActual['color'] as Color?) ??
                                              Colors.blue)
                                          .withValues(
                                            alpha:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? 0.12
                                                : 0.08,
                                          ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          // 🧠 Detecta si el celular está en modo oscuro para adaptar el fondo del logo
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(
                                                  0xFF090A0F,
                                                ) // Noche: Negro profundo
                                              : Colors
                                                    .white, // Día: Blanco impecable
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color:
                                                (emisoraActual['color']
                                                    as Color?) ??
                                                Colors.blue,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: _liveArtUrl != null
                                              ? Image.network(
                                                  _liveArtUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return _buildLogoRespaldo(
                                                          emisoraActual,
                                                        );
                                                      },
                                                )
                                              : Image.asset(
                                                  'assets/logos/${emisoraActual['logo'] ?? 'logo'}.png',
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return _buildLogoRespaldo(
                                                          emisoraActual,
                                                        );
                                                      },
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                ((emisoraActual['nombre']
                                                            as String?) ??
                                                        'Emisora')
                                                    .replaceAll('\n', ' '),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color:
                                                      (emisoraActual['color']
                                                          as Color?) ??
                                                      Colors.blue,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _obtenerTextoEstado(
                                                      emisoraActual,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF1C1E29,
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                AnimatedSoundWave(
                                                  color:
                                                      (emisoraActual['color']
                                                          as Color?) ??
                                                      Colors.blue,
                                                  isPlaying: _isPlaying,
                                                  isSyncing: _isSyncing,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 1),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.sensors_rounded,
                                                  size: 11,
                                                  color:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.white38
                                                      : Colors.black38,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'La Gran Cadena del Sur Dominicano',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color:
                                                          ((emisoraActual['color']
                                                                      as Color?) ??
                                                                  Colors.blue)
                                                              .withValues(
                                                                alpha: 0.86,
                                                              ),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 0.2,
                                                    ),
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
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(width: 24),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(
                                            Icons.skip_previous_rounded,
                                            size: 26,
                                          ),
                                          color:
                                              (Theme.of(context).brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : const Color(0xFF1C1E29))
                                                  .withValues(alpha: 0.78),
                                          onPressed: _irAtras,
                                        ),
                                        const SizedBox(width: 14),
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            if (_isSyncing)
                                              SizedBox(
                                                width: 38,
                                                height: 38,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(
                                                        (emisoraActual['color']
                                                                as Color?) ??
                                                            Colors.blue,
                                                      ),
                                                ),
                                              ),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              icon: Icon(
                                                _isSyncing
                                                    ? Icons.stop_circle_rounded
                                                    : (_isPlaying
                                                          ? Icons
                                                                .pause_circle_filled_rounded
                                                          : Icons
                                                                .play_circle_filled_rounded),
                                              ),
                                              iconSize: 34,
                                              color: _isSyncing
                                                  ? Colors.redAccent
                                                  : (emisoraActual['color']
                                                            as Color?) ??
                                                        Colors.blue,
                                              onPressed: () {
                                                if (_isSyncing || _isPlaying) {
                                                  _pausarAudio();
                                                } else {
                                                  _reproducirConSincronizacion(
                                                    _indiceActual!,
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 14),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(
                                            Icons.skip_next_rounded,
                                            size: 26,
                                          ),
                                          color:
                                              (Theme.of(context).brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : const Color(0xFF1C1E29))
                                                  .withValues(alpha: 0.78),
                                          onPressed: _irAlante,
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                      ),
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white38
                                          : Colors.black38,
                                      onPressed: () {
                                        _pausarAudio();
                                        setState(() {
                                          _indiceActual = null;
                                          _isPlaying = false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // ... tu línea divisoria
              Container(
                height: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(
                        alpha: 0.08,
                      ) // Color para modo oscuro
                    : Colors.black.withValues(
                        alpha: 0.08,
                      ), // Color para modo claro
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(), // Desplazamiento suave de rebote (iOS/Android)
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =======================================================
                      // 1. LOS 3 BOTONES GRANDES (REPARTIDOS EQUITATIVAMENTE)
                      // =======================================================
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            // Botón TELEVISIÓN (Ocupa 1/3 del ancho)
                            Expanded(
                              child: _buildBotonCapsula(
                                texto: "TELEVISIÓN",
                                colorInicio: const Color(0xFFFFD447),
                                colorFin: const Color(0xFFFFAE00),
                                colorBorde: const Color(0xFFFF9E00),
                                onTap: () {
                                  if (_audioPlayer.playing) {
                                    _audioPlayer.pause();
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SurTvPlayerScreen(
                                        videoUrl:
                                            'https://ss2.tvrdomi.com:1936/eradiofonicas/eradiofonicas/playlist.m3u8',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ), // Espacio idéntico entre botones
                            // Botón PERIÓDICO (Ocupa 1/3 del ancho)
                            Expanded(
                              child: _buildBotonCapsula(
                                texto: "PERIÓDICO",
                                colorInicio: const Color(0xFF63B8FF),
                                colorFin: const Color(0xFF1E90FF),
                                colorBorde: const Color(0xFF104E8B),
                                onTap: () {
                                  // Abre el portal de Diario Noticias integrado en la app
                                  _abrirEnlace(
                                    context,
                                    'Periódico',
                                    'https://diarionoticias.do/',
                                  );
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ), // Espacio idéntico entre botones
                            // Botón YOUTUBE (Ocupa 1/3 del ancho)
                            Expanded(
                              child: _buildBotonCapsula(
                                texto: "YOUTUBE",
                                colorInicio: const Color(0xFFFF3B30),
                                colorFin: const Color(0xFFCD201F),
                                colorBorde: const Color(0xFF8B0000),
                                onTap: () {
                                  _abrirEnlace(
                                    context,
                                    'YouTube',
                                    'https://www.youtube.com/@empresasradiofonicasrd',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ), // Espacio limpio y elegante antes de la cuadrícula
                      // ==========================================
                      // 2. CUADRÍCULA DE EMISORAS INTEGRADA Y ADAPTATIVA
                      // ==========================================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isDark =
                                Theme.of(context).brightness == Brightness.dark;

                            return GridView.builder(
                              shrinkWrap:
                                  true, // Adapta la cuadrícula al contenido interno sin desbordar
                              physics:
                                  const NeverScrollableScrollPhysics(), // El scroll lo maneja el SingleChildScrollView principal
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columnas,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 1.15,
                                  ),
                              itemCount: emisoras.length,
                              itemBuilder: (context, index) {
                                final emisora = emisoras[index];
                                final bool esLaSeleccionada =
                                    _indiceActual == index;

                                // Extracción de datos Null-Safe para blindar la app contra caídas catastróficas
                                final Color emisoraColor =
                                    (emisora['color'] as Color?) ?? Colors.blue;
                                final bool esVideo =
                                    (emisora['esVideo'] as bool?) ?? false;
                                final String? logoNombre =
                                    emisora['logo'] as String?;

                                return Container(
                                  decoration: BoxDecoration(
                                    // Fondo inteligente adaptado al tema activo del celular
                                    color: isDark
                                        ? Colors.white.withValues(
                                            alpha: 0.80,
                                          ) // Blanco opaco ideal para destacar logos oscuros en fondo negro
                                        : Colors.white.withValues(
                                            alpha: 0.93,
                                          ), // Blanco casi sólido para el modo claro
                                    borderRadius: BorderRadius.circular(16),
                                    // Borde dinámico según selección y contraste
                                    border: Border.all(
                                      color: esLaSeleccionada
                                          ? emisoraColor
                                          : emisoraColor.withValues(
                                              alpha: isDark ? 0.25 : 0.45,
                                            ),
                                      width: esLaSeleccionada ? 2.5 : 1.2,
                                    ),
                                    // Sombras dinámicas antialiasing
                                    boxShadow: esLaSeleccionada
                                        ? [
                                            BoxShadow(
                                              color: emisoraColor.withValues(
                                                alpha: isDark ? 0.35 : 0.25,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: isDark
                                                  ? Colors.black.withValues(
                                                      alpha: 0.3,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.05,
                                                    ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      15,
                                    ), // Ligeramente menor que el Container para evitar sangrado de bordes (antialiasing)
                                    child: InkWell(
                                      // Efecto de onda traslúcido usando el color de la propia marca de la emisora
                                      splashColor: emisoraColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      highlightColor: emisoraColor.withValues(
                                        alpha: 0.05,
                                      ),
                                      onTap: () {
                                        setState(() {});
                                        _reproducirConSincronizacion(index);
                                      },
                                      child: Stack(
                                        children: [
                                          // Icono identificador de tipo (Radio / TV) en la esquina superior derecha
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Icon(
                                              esVideo
                                                  ? Icons.videocam
                                                  : Icons.radio,
                                              size: 13,
                                              color: esLaSeleccionada
                                                  ? emisoraColor
                                                  : emisoraColor.withValues(
                                                      alpha: 0.70,
                                                    ),
                                            ),
                                          ),
                                          // Logotipo centrado o fallback de texto estilizado
                                          Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                10.0,
                                              ),
                                              child: logoNombre != null
                                                  ? Image.asset(
                                                      'assets/logos/$logoNombre.png',
                                                      fit: BoxFit.contain,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return _buildTextFallback(
                                                              emisora,
                                                              esLaSeleccionada,
                                                            );
                                                          },
                                                    )
                                                  : _buildTextFallback(
                                                      emisora,
                                                      esLaSeleccionada,
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 32,
                      ), // Colchón de aire al final para una navegación desahogada
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ), // Cierra el Scaffold
    ); // Cierra el PopScope
  } // Cierra el método Widget build

  void _activarWhatsAppTemporal() {
    // 1. Si ya había un temporizador corriendo, lo cancelamos para reiniciar los conteos
    _whatsappTimer?.cancel();

    // 2. Mostramos el botón inmediatamente y forzamos a que nazca expandido con texto
    setState(() {
      _mostrarWhatsApp = true;
      _mostrarTextoWhatsapp =
          true; // 🟢 Nace expandido mostrando "Pide tu música"
    });

    // 3. Programamos que el TEXTO se encoja automáticamente a los 6 segundos
    Timer(const Duration(seconds: 6), () {
      if (mounted && _mostrarWhatsApp) {
        // Solo si el botón sigue visible
        setState(() {
          _mostrarTextoWhatsapp =
              false; // 🟢 Se encoge suavemente a tu círculo original
        });
      }
    });

    // 4. Programamos que
    _whatsappTimer = Timer(const Duration(seconds: 20), () {
      if (mounted) {
        setState(() {
          _mostrarWhatsApp = false;
        });
      }
    });
  }

  //  PEGA EL MÉTODO JUSTO AQUÍ, EN ESTE HUECO:
  Future<void> _abrirWhatsApp() async {
    // 1. Obtenemos los datos dinámicos de la emisora que se está reproduciendo
    // Si no hay ninguna seleccionada (es null), usamos un número y mensaje por defecto.
    final String nombreEmisora = _indiceActual != null
        ? (emisoras[_indiceActual!]['nombre'] ?? "la radio")
        : "la radio";

    // Obtenemos el teléfono de la emisora actual. Si no tiene uno personalizado, usamos el principal.
    final String numeroTelefono =
        _indiceActual != null && emisoras[_indiceActual!]['telefono'] != null
        ? emisoras[_indiceActual!]['telefono'].toString().replaceAll(
            RegExp(r'[^0-9]'),
            '',
          ) // Limpiamos espacios y guiones
        : "18095242313"; // Tu número de respaldo de Empresas Radiofónicas

    // 2. Creamos el mensaje personalizado
    final String mensaje =
        "¡Hola! Estoy escuchando * $nombreEmisora * desde la app móvil y quiero enviar un saludo.";

    // 3. Construimos la URL de manera segura
    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/$numeroTelefono?text=${Uri.encodeComponent(mensaje)}",
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        // Respaldo en caso de que use un navegador sin la app nativa instalada
        final Uri webUrl = Uri.parse(
          "https://web.whatsapp.com/send?phone=$numeroTelefono&text=${Uri.encodeComponent(mensaje)}",
        );
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error al intentar abrir WhatsApp: $e");
    }
  }

  Widget _buildLogoRespaldo(Map<String, dynamic>? emisoraActual) {
    if (emisoraActual == null) return const SizedBox.shrink();

    // 1. Creamos el texto de respaldo una sola vez para no duplicar código
    final widgetTextoRespaldo = Center(
      child: Padding(
        padding: const EdgeInsets.all(
          4.0,
        ), // Un pequeño espacio para que no toque los bordes
        child: Text(
          (emisoraActual['key'] as String?) ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9, // Subimos a 9 para mejorar la legibilidad en 44x44
            fontWeight: FontWeight.w900,
            // Evitamos caídas usando un color por defecto (rojo) si viene nulo
            color: (emisoraActual['color'] as Color?) ?? Colors.red,
          ),
        ),
      ),
    );

    // 2. Si tiene logo configurado, intentamos cargarlo
    if (emisoraActual['logo'] != null) {
      return Image.asset(
        'assets/logos/${emisoraActual['logo']}.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Si el archivo físico no existe en los assets, mostramos el texto
          return widgetTextoRespaldo;
        },
      );
    }

    // 3. Si directamente no tiene logo configurado, mostramos el texto
    return widgetTextoRespaldo;
  }

  Widget _buildTextFallback(
    Map<String, dynamic> emisora,
    bool esLaSeleccionada,
  ) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        emisora['nombre'] as String? ?? '',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: esLaSeleccionada
              ? Colors.white
              : Colors.white.withValues(alpha: 0.78),
          height: 1.3,
        ),
      ), // Este cierra tu Scaffold
    ); // Este cierra tu PopScope
  } // Aquí termina tu "Widget build"
}
