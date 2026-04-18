import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../theme/app_theme.dart';
import 'main_app.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;

  // ── Google button constants — hardcoded, never theme-derived ──────────────
  // Root cause of the original bug: foregroundColor was onSurface which goes
  // WHITE in dark mode, making the "Sign in with Google" text invisible on the
  // always-white button background. These three values must never be changed
  // to Theme.of(context) calls.
  static const Color _googleTextColor       = Color(0xFF202124); // Google spec
  static const Color _googleBgColor         = Colors.white;      // always white
  static const Color _googleBorderColor     = Color(0xFFDADCE0); // Google spec

  static const String _googleLogoSvg = '''
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>''';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateIfLoggedIn();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _navigateIfLoggedIn() async {
    try {
      final AuthService authService = context.read<AuthService>();
      if (authService.currentUser == null || !mounted) {
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const MainApp(),
        ),
      );
    } catch (_) {
      // Tests may build the screen without initializing Firebase.
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final AuthService authService        = context.read<AuthService>();
    final AnalyticsService analyticsService = context.read<AnalyticsService>();
    final MessagingService messagingService = context.read<MessagingService>();
    final ScaffoldMessengerState messenger  = ScaffoldMessenger.of(context);
    final NavigatorState navigator          = Navigator.of(context);

    setState(() => _isLoading = true);

    try {
      await authService.login(
        email:    _emailController.text.trim(),
        password: _passwordController.text,
      );
      await analyticsService.logLogin();
      await messagingService.initialize();

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Login successful.')),
      );
      navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const MainApp(),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final String message;
      switch (error.code) {
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-not-found':
          message = 'No account found for this email.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Try again later.';
          break;
        default:
          message = error.message ?? 'Login failed. Please try again.';
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Login failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    final AuthService authService        = context.read<AuthService>();
    final AnalyticsService analyticsService = context.read<AnalyticsService>();
    final MessagingService messagingService = context.read<MessagingService>();
    final ScaffoldMessengerState messenger  = ScaffoldMessenger.of(context);
    final NavigatorState navigator          = Navigator.of(context);

    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb
            ? '217095734613-28leg5h7fmondvb45bs4rm8pvlb9mjbq.apps.googleusercontent.com'
            : null,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await analyticsService.logLogin();
      await messagingService.initialize();

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Google login successful.')),
      );
      navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const MainApp(),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final String message;
      switch (error.code) {
        case 'account-exists-with-different-credential':
          message = 'Account exists with different credentials.';
          break;
        case 'invalid-credential':
          message = 'Invalid credentials.';
          break;
        default:
          message = error.message ?? 'Google login failed. Please try again.';
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Google login failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
              colors: isDark
                  ? <Color>[darkBackground, darkCard]
                  : <Color>[lightBackground, Colors.white],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[

                        // ── Header ───────────────────────────────────────────
                        Text(
                          'Welcome Back',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Login by email and password.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                        ),
                        const SizedBox(height: 20),

                        // ── Email ────────────────────────────────────────────
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // ── Password ─────────────────────────────────────────
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscureText = !_obscureText),
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // ── Login button ─────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    width:  20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Login'),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Google Sign-In button ────────────────────────────
                        //
                        // WHY these values are hardcoded constants
                        // ----------------------------------------
                        // OutlinedButton.foregroundColor cascades into all
                        // child Text widgets as their default text colour.
                        // The old code set foregroundColor = onSurface, which
                        // is WHITE in dark mode → "Sign in with Google" label
                        // was rendered in white on a white button = invisible.
                        //
                        // Fix:
                        //  • backgroundColor  = Colors.white  (always)
                        //  • foregroundColor  = Color(0xFF202124)  (always)
                        //    — keeps the press-ripple dark and correct
                        //  • Text color       = Color(0xFF202124)  (always)
                        //    — explicit so no ancestor can override it
                        //  • Border           = Color(0xFFDADCE0)
                        //    — Google's official button border, legible on
                        //      both light and dark card backgrounds
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _handleGoogleLogin,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _googleBgColor,
                              foregroundColor: _googleTextColor,
                              side: const BorderSide(color: _googleBorderColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                // SVG colours are baked into the paths — always correct.
                                SvgPicture.string(
                                  _googleLogoSvg,
                                  height: 24,
                                  width:  24,
                                ),
                                const SizedBox(width: 10),
                                // color is explicitly set — do NOT remove it or
                                // replace it with a textTheme / onSurface value.
                                const Text(
                                  'Sign in with Google',
                                  style: TextStyle(
                                    fontSize:   16,
                                    fontWeight: FontWeight.w500,
                                    color:      _googleTextColor, // FIX
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // ── End Google Sign-In button ────────────────────────

                        const SizedBox(height: 8),

                        // ── Register button ──────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (BuildContext context) =>
                                      const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text('Create New Account'),
                          ),
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
    );
  }
}