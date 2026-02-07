import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../widgets/primary_button.dart';
import '../../routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);
    try {
      await AuthService().login(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.authGate);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final surface = isDark ? const Color(0xFF141417) : Colors.white;
    final border = isDark ? const Color(0xFF2A2A2F) : const Color(0xFFE7E8EC);

    final scaffoldBg = theme.scaffoldBackgroundColor ?? surface;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Material(
        type: MaterialType.transparency,
        color: Colors.transparent,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: scaffoldBg,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
            systemStatusBarContrastEnforced: false,
          ),
          child: Stack(
          children: [
            // Animated gradient background (own widget so controller is always initialized)
            Positioned.fill(
              child: _AnimatedLoginBackground(isDark: isDark),
            ),
            // Sparkles / glitter layer
            Positioned.fill(
              child: _AnimatedSparkles(isDark: isDark),
            ),
            // Login content on top
            SafeArea(
              child: LayoutBuilder(
            builder: (context, constraints) {
              final viewportHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
                  ? constraints.maxHeight
                  : 600.0;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewportHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    const SizedBox(height: 32),

                    // Logo – full logo visible, no crop
                    SizedBox(
                      width: 200,
                      height: 100,
                      child: Image.asset(
                        'assets/sp_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.favorite, size: 48, color: cs.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'sparks',
                      style: GoogleFonts.quicksand(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome back. Sign in to continue.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Form – no box, sits directly on background
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'you@example.com',
                                prefixIcon: Icon(
                                  Icons.mail_outlined,
                                  color: cs.onSurfaceVariant,
                                  size: 22,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: cs.primary, width: 2),
                                ),
                                filled: true,
                                fillColor: theme.scaffoldBackgroundColor ?? surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: '••••••••',
                                prefixIcon: Icon(
                                  Icons.lock_outlined,
                                  color: cs.onSurfaceVariant,
                                  size: 22,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: cs.onSurfaceVariant,
                                    size: 22,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: cs.primary, width: 2),
                                ),
                                filled: true,
                                fillColor: theme.scaffoldBackgroundColor ?? surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: Validators.password,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.errorContainer.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: cs.error.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, size: 20, color: cs.error),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: cs.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            PrimaryButton(
                              text: 'Sign in',
                              onPressed: _submit,
                              loading: _loading,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, Routes.register),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
            },
          ),
        ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Owns the animation controller so it's always initialized before use.
class _AnimatedLoginBackground extends StatefulWidget {
  final bool isDark;

  const _AnimatedLoginBackground({required this.isDark});

  @override
  State<_AnimatedLoginBackground> createState() => _AnimatedLoginBackgroundState();
}

class _AnimatedLoginBackgroundState extends State<_AnimatedLoginBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _LoginGradientPainter(
                value: _controller.value,
                isDark: widget.isDark,
              ),
              size: size,
            );
          },
        );
      },
    );
  }
}

/// Animated sparkles / glitter layer.
class _AnimatedSparkles extends StatefulWidget {
  final bool isDark;

  const _AnimatedSparkles({required this.isDark});

  @override
  State<_AnimatedSparkles> createState() => _AnimatedSparklesState();
}

class _AnimatedSparklesState extends State<_AnimatedSparkles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _SparklePainter(
                value: _controller.value,
                isDark: widget.isDark,
              ),
              size: size,
            );
          },
        );
      },
    );
  }
}

/// Golden glitter shower: dense at top, thinning toward bottom, with stars and soft bokeh.
class _SparklePainter extends CustomPainter {
  final double value;
  final bool isDark;

  _SparklePainter({required this.value, required this.isDark});

  double _h(int i, int seed) {
    final n = (i * 7919 + seed * 7829) % 10000;
    return n / 10000;
  }

  void _drawStar(Canvas canvas, Offset center, double radius, double opacity, bool isDark) {
    final color = isDark
        ? Color.fromRGBO(255, 228, 150, opacity)
        : Color.fromRGBO(255, 215, 120, opacity);
    final paint = Paint()..color = color;
    canvas.drawCircle(center, radius * 0.4, paint);
    final strokeW = (radius * 0.35).clamp(2.0, 6.0);
    for (var a = 0.0; a < 2 * math.pi; a += math.pi / 2) {
      final dx = math.cos(a) * radius;
      final dy = math.sin(a) * radius;
      canvas.drawLine(center, center + Offset(dx, dy), paint..strokeWidth = strokeW);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = value * 2 * math.pi;
    const fallSpeed = 120.0;

    // Soft bokeh – fewer, well spaced
    for (var i = 0; i < 4; i++) {
      final x = 0.15 * size.width + _h(i, 40) * size.width * 0.7;
      final y = _h(i, 41) * size.height * 0.5;
      final r = 45.0 + _h(i, 42) * 45;
      final opacity = (0.03 + 0.05 * (math.sin(t + i) + 1) / 2).clamp(0.0, 1.0);
      final color = isDark
          ? Color.fromRGBO(255, 220, 140, opacity)
          : Color.fromRGBO(255, 235, 180, opacity);
      canvas.drawCircle(Offset(x, y), r, Paint()..color = color);
    }

    // Golden dots – same style, spread over full height so they cover the whole screen
    const dotCount = 48;
    for (var i = 0; i < dotCount; i++) {
      final baseX = (_h(i, 1) * 0.9 + 0.05) * size.width;
      final baseY = _h(i, 2) * (size.height + 240) - 60;
      final y = (baseY + value * fallSpeed * 0.7) % (size.height + 240) - 60;
      final x = baseX + math.sin(t * 0.2 + i * 0.4) * 12;
      final phase = _h(i, 3) * 2 * math.pi;
      final twinkle = (math.sin(t + phase) + 1) / 2;
      final opacity = (0.2 + 0.4 * twinkle).clamp(0.0, 1.0);
      final radius = 4.0 + _h(i, 4) * 5.0;

      final color = isDark
          ? Color.fromRGBO(255, 218, 130, opacity)
          : Color.fromRGBO(255, 205, 100, opacity);
      canvas.drawCircle(Offset(x, y), radius, Paint()..color = color);
    }

    // Star sparkles – same style, spread over full height so they cover the whole screen
    const starCount = 16;
    for (var i = 0; i < starCount; i++) {
      final baseX = (_h(i + 50, 1) * 0.85 + 0.075) * size.width;
      final baseY = _h(i + 50, 2) * (size.height + 280) - 70;
      final y = (baseY + value * fallSpeed * 0.6) % (size.height + 280) - 70;
      final x = baseX + math.sin(t * 0.4 + i * 0.5) * 15;
      final phase = _h(i + 50, 3) * 2 * math.pi;
      final twinkle = (math.sin(t * 1.1 + phase) + 1) / 2;
      final opacity = (0.25 + 0.45 * twinkle).clamp(0.0, 1.0);
      _drawStar(canvas, Offset(x, y), 12.0 + _h(i + 50, 4) * 10.0, opacity, isDark);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) =>
      old.value != value || old.isDark != isDark;
}

/// Paints a slowly shifting gradient for the login background.
class _LoginGradientPainter extends CustomPainter {
  final double value;
  final bool isDark;

  _LoginGradientPainter({required this.value, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final t = value * 2 * math.pi;

    if (isDark) {
      final gradient = LinearGradient(
        begin: Alignment(-1.0 + 0.15 * (1 + math.sin(t * 0.5)), -1.0),
        end: Alignment(1.0 + 0.15 * (1 + math.cos(t * 0.5)), 1.0),
        colors: [
          const Color(0xFF2d0a0a),
          Color.lerp(const Color(0xFF3d1515), const Color(0xFF4a1a1a), (0.4 + 0.3 * math.sin(t)).clamp(0.0, 1.0))!,
          const Color(0xFF1a0808),
          Color.lerp(const Color(0xFF2d1212), const Color(0xFF351818), (0.35 + 0.25 * math.cos(t)).clamp(0.0, 1.0))!,
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
      );
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    } else {
      final gradient = LinearGradient(
        begin: Alignment(-1.0 + 0.15 * (1 + math.sin(t * 0.5)), -1.0),
        end: Alignment(1.0 + 0.15 * (1 + math.cos(t * 0.5)), 1.0),
        colors: [
          const Color(0xFFFFE5E5),
          Color.lerp(const Color(0xFFFFCCCC), const Color(0xFFFFDDDD), (0.35 + 0.4 * math.sin(t)).clamp(0.0, 1.0))!,
          Color.lerp(const Color(0xFFFFD6D6), const Color(0xFFFFE8E8), (0.3 + 0.35 * math.cos(t)).clamp(0.0, 1.0))!,
          const Color(0xFFFFEBEB),
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      );
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    }
  }

  @override
  bool shouldRepaint(covariant _LoginGradientPainter old) => old.value != value || old.isDark != isDark;
}
