// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
/// Login — Fixmyitch minimal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signInState = ref.watch(signInProvider);
    final isLoading = signInState.isLoading;

    ref.listen<AsyncValue<void>>(signInProvider, (_, next) {
      if (next.hasError) {
        final error = next.error.toString();
        if (!error.contains('sign_in_cancelled')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign-in failed: $error')),
          );
        }
        ref.read(signInProvider.notifier).reset();
      } else if (next is AsyncData) {
        context.go(AppConstants.routeDashboard);
      }
    });

    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top nav bar
          _NavBar(),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 80,
                ),
                child: isDesktop
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 11, child: _AuthLeft()),
                            Container(width: 1, color: AppColors.outline),
                            Expanded(
                                flex: 10,
                                child:
                                    _AuthRight(isLoading: isLoading, ref: ref)),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          _AuthLeft(),
                          Container(height: 1, color: AppColors.outline),
                          _AuthRight(isLoading: isLoading, ref: ref),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.outline, width: 1)),
        title: Text(
          title,
          style: GoogleFonts.fraunces(
              color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w400),
        ),
        content: Text(
          content,
          style: GoogleFonts.inter(color: AppColors.inkMuted, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outline, width: 1)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'FairTerms',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: AppColors.ink,
                  letterSpacing: -0.02,
                ),
              ),
            ],
          ),
          // Right nav links
          Row(
            children: [
              _NavLink(
                'How it works',
                onTap: () => _showInfoDialog(
                  context,
                  'How FairTerms Works',
                  'FairTerms uses AI to detect and mitigate bias in payment contracts. \n\n'
                      '1. Upload your payment terms.\n'
                      '2. Our AI engine analyzes for fairness and transparency.\n'
                      '3. Receive a detailed bias report with actionable recommendations.\n'
                      '4. Generate AI-assisted grievances for unfair terms.',
                ),
              ),
              SizedBox(width: 24),
              _NavLink(
                'Research',
                onTap: () => _showInfoDialog(
                  context,
                  'Research Study',
                  'This project is part of a research study focusing on India SMEs. '
                      'We aim to bridge the fairness gap in standard payment contracts '
                      'using advanced NLP and Fairness-aware AI models.',
                ),
              ),
              SizedBox(width: 24),
              _NavLink(
                'Contact',
                onTap: () => _showInfoDialog(
                  context,
                  'Contact Us',
                  'Have questions or feedback?\n\n'
                      'Email: support@fairterms.ai\n'
                      'Phone: +91 98765 43210\n'
                      'Office: Bangalore, KA, India',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _NavLink(this.label, {this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: _isHovered ? AppColors.ink : AppColors.inkMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _AuthLeft extends StatefulWidget {
  const _AuthLeft();

  @override
  State<_AuthLeft> createState() => _AuthLeftState();
}

class _AuthLeftState extends State<_AuthLeft> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _slideController =
        AnimationController(duration: Duration(milliseconds: 600), vsync: this);
    _fadeController.forward();
    Future.delayed(
        Duration(milliseconds: 80), () => _slideController.forward());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 72 : 28,
        vertical: isDesktop ? 88 : 56,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Eyebrow
          FadeTransition(
            opacity: _fadeController,
            child: Text(
              'Payment bias detection · India SME',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.inkFaint,
                letterSpacing: 0.12,
              ),
            ),
          ),
          SizedBox(height: 22),
          // Hero title
          SlideTransition(
            position: Tween<Offset>(begin: Offset(0, 0.02), end: Offset.zero)
                .animate(_slideController),
            child: FadeTransition(
              opacity: _fadeController,
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.fraunces(
                    fontSize: 64,
                    fontWeight: FontWeight.w300,
                    color: AppColors.ink,
                    letterSpacing: -0.03,
                    height: 1.02,
                  ),
                  children: [
                    TextSpan(text: 'Fair terms for every '),
                    TextSpan(
                      text: 'invoice',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          // Description
          FadeTransition(
            opacity: _fadeController,
            child: SizedBox(
              width: 460,
              child: Text(
                'FairTerms analyses the payment terms your buyers offer and benchmarks them against peers in your state and industry — so you know, before you sign, whether you\'re being squeezed.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.inkMuted,
                  height: 1.55,
                ),
              ),
            ),
          ),
          SizedBox(height: 40),
          // Stats
          FadeTransition(
            opacity: _fadeController,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.outline, width: 1),
                ),
              ),
              padding: EdgeInsets.only(top: 28),
              child: Row(
                children: [
                  Expanded(
                    child: _StatBlock('12,480', 'Contracts analysed'),
                  ),
                  Expanded(
                    child: _StatBlock('₹4.2cr', 'Interest recovered'),
                  ),
                  Expanded(
                    child: _StatBlock('28', 'States covered'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String number;
  final String label;

  const _StatBlock(this.number, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: GoogleFonts.fraunces(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: AppColors.ink,
            letterSpacing: -0.02,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.inkFaint,
            letterSpacing: 0.12,
          ),
        ),
      ],
    );
  }
}

class _AuthRight extends StatefulWidget {
  final bool isLoading;
  final WidgetRef ref;

  const _AuthRight({required this.isLoading, required this.ref});

  @override
  State<_AuthRight> createState() => _AuthRightState();
}

class _AuthRightState extends State<_AuthRight> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _slideController =
        AnimationController(duration: Duration(milliseconds: 600), vsync: this);
    Future.delayed(Duration(milliseconds: 160), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 72 : 28,
        vertical: isDesktop ? 88 : 56,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SlideTransition(
            position: Tween<Offset>(begin: Offset(0, 0.02), end: Offset.zero)
                .animate(_slideController),
            child: FadeTransition(
              opacity: _fadeController,
              child: Text(
                'Sign in',
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: AppColors.ink,
                  letterSpacing: -0.02,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          FadeTransition(
            opacity: _fadeController,
            child: Text(
              'Use your Google account to continue. We never post or email on your behalf.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.inkFaint,
              ),
            ),
          ),
          SizedBox(height: 32),
          // Google button
          FadeTransition(
            opacity: _fadeController,
            child: _AnimatedButton(
              onTap: widget.isLoading
                  ? null
                  : () => widget.ref
                      .read(signInProvider.notifier)
                      .signInWithGoogle(),
              isLoading: widget.isLoading,
              isPrimary: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleIcon(),
                  SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.background,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          // Divider
          FadeTransition(
            opacity: _fadeController,
            child: Row(
              children: [
                Expanded(child: Container(height: 1, color: AppColors.outline)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or use email',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ),
                Expanded(child: Container(height: 1, color: AppColors.outline)),
              ],
            ),
          ),
          SizedBox(height: 24),
          // Email field
          FadeTransition(
            opacity: _fadeController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.inkMuted,
                    letterSpacing: 0.1,
                  ),
                ),
                SizedBox(height: 6),
                TextField(
                  enabled: !widget.isLoading,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: 'you@company.in',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.inkFaint,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppColors.outline, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppColors.outline, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.ink, width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Password field
          FadeTransition(
            opacity: _fadeController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.inkMuted,
                    letterSpacing: 0.1,
                  ),
                ),
                SizedBox(height: 6),
                TextField(
                  enabled: !widget.isLoading,
                  obscureText: true,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.inkFaint,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppColors.outline, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppColors.outline, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.ink, width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          // Sign in button (secondary outline)
          FadeTransition(
            opacity: _fadeController,
            child: _AnimatedButton(
              onTap: widget.isLoading
                  ? null
                  : () => widget.ref
                      .read(signInProvider.notifier)
                      .signInWithGoogle(),
              isLoading: widget.isLoading,
              isPrimary: false,
              child: Text(
                'Sign in',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          SizedBox(height: 22),
          // Create account link
          FadeTransition(
            opacity: _fadeController,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'New to FairTerms? ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.inkFaint,
                      ),
                      children: [
                        TextSpan(
                          text: 'Create an account',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      widget.ref.read(guestModeProvider.notifier).state = true;
                      context.go(AppConstants.routeDashboard);
                    },
                    child: Text(
                      'Continue as Guest',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkMuted,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isPrimary;
  final Widget child;

  const _AnimatedButton({
    required this.onTap,
    required this.isLoading,
    required this.isPrimary,
    required this.child,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedTranslate(
          offset: _isHovered && widget.onTap != null ? -1.0 : 0.0,
          duration: Duration(milliseconds: 180),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: widget.isPrimary ? AppColors.ink : Colors.transparent,
              border: widget.isPrimary
                  ? null
                  : Border.all(color: AppColors.outline, width: 1),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class AnimatedTranslate extends StatelessWidget {
  final double offset;
  final Duration duration;
  final Widget child;

  const AnimatedTranslate({
    super.key,
    required this.offset,
    required this.duration,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: Offset(0, 0), end: Offset(0, offset)),
      duration: duration,
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: SvgGoogleIcon(),
    );
  }
}

class SvgGoogleIcon extends StatelessWidget {
  const SvgGoogleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GoogleLogoPainter(),
      size: Size(16, 16),
    );
  }
}

class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Simplified Google logo
    final paint = Paint()..style = PaintingStyle.fill;

    // Blue arc
    paint.color = Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.9),
      -0.35,
      1.4,
      false,
      paint
        ..strokeWidth = radius * 0.25
        ..style = PaintingStyle.stroke,
    );

    // Red arc
    paint.color = Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.9),
      3.9,
      1.6,
      false,
      paint..strokeWidth = radius * 0.25,
    );

    // Yellow arc
    paint.color = Color(0xFFFBBC04);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.9),
      2.4,
      1.5,
      false,
      paint..strokeWidth = radius * 0.25,
    );

    // Green arc
    paint.color = Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.9),
      1.05,
      1.35,
      false,
      paint..strokeWidth = radius * 0.25,
    );

    // White center
    paint.color = AppColors.background;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, paint);

    // Blue inner
    paint.color = Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 0.4, center.dy - size.height * 0.1,
          radius * 0.8, size.height * 0.2),
      paint,
    );
  }

  @override
  bool shouldRepaint(GoogleLogoPainter oldDelegate) => false;
}
