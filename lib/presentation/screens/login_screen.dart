import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@priostack.local');
  final _passCtrl = TextEditingController(text: 'AdminPrio2026!');
  final _nameCtrl = TextEditingController();
  late final TextEditingController _apiUrlCtrl;
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _showServerConfig = false;

  @override
  void initState() {
    super.initState();
    _apiUrlCtrl = TextEditingController(text: ref.read(authApiUrlProvider));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _apiUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // S'assurer que l'URL saisie est bien appliquée
    ref.read(authApiUrlProvider.notifier).setApiUrl(_apiUrlCtrl.text);

    final authNotifier = ref.read(authProvider.notifier);
    if (_isRegisterMode) {
      if (_nameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez renseigner votre nom complet.')),
        );
        return;
      }
      await authNotifier.register(
        _emailCtrl.text,
        _passCtrl.text,
        _nameCtrl.text,
      );
    } else {
      await authNotifier.login(
        _emailCtrl.text,
        _passCtrl.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
            decoration: AppTheme.neumorphicCard(
              color: AppTheme.surfaceCard,
              radius: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Titre
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentBlue.withValues(alpha: 0.4),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.layers_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PrioStack',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Text(
                          'Neon.tech Cloud Edition',
                          style: TextStyle(
                            color: AppTheme.neonGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                Text(
                  _isRegisterMode ? 'Créer un nouveau compte' : 'Connexion à votre espace',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _isRegisterMode
                      ? 'Rejoignez votre cockpit d\'architecture et synchronisez vos appareils'
                      : 'Accédez à votre Call Stack, Agenda et Tâches sauvegardées',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Message d'erreur
                if (authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.neonPink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.neonPink),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: const TextStyle(color: AppTheme.neonPink, fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Champ Nom complet (si inscription)
                if (_isRegisterMode) ...[
                  Text(
                    'Nom complet',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ex: Thomas Durant',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                      filled: true,
                      fillColor: AppTheme.surfaceInput,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.borderSubtle),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Champ Email
                Text(
                  'Adresse email',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'admin@priostack.local',
                    prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
                    filled: true,
                    fillColor: AppTheme.surfaceInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.borderSubtle),
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),

                // Champ Mot de passe
                Text(
                  'Mot de passe',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '••••••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.borderSubtle),
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 22),

                // Bouton Valider
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isRegisterMode ? 'Créer mon compte' : 'Se connecter',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                ),
                const SizedBox(height: 16),

                // Bascule Inscription / Connexion
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegisterMode = !_isRegisterMode;
                    });
                  },
                  child: Text(
                    _isRegisterMode
                        ? 'Déjà un compte ? Se connecter'
                        : 'Pas encore de compte ? S\'inscrire',
                    style: const TextStyle(color: AppTheme.accentBlue, fontSize: 12),
                  ),
                ),

                const SizedBox(height: 10),

                // Paramètres du serveur API (Autre PC / Wi-Fi / Cloud)
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    setState(() {
                      _showServerConfig = !_showServerConfig;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.dns_outlined,
                          size: 13,
                          color: _showServerConfig ? AppTheme.accentBlue : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Serveur API : ${ref.watch(authApiUrlProvider)}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _showServerConfig ? AppTheme.accentBlue : AppTheme.textMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showServerConfig ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showServerConfig) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.settings_ethernet_rounded, size: 14, color: AppTheme.accentBlue),
                            const SizedBox(width: 6),
                            Text(
                              'Connexion distante / Autre PC',
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pour vous connecter depuis un autre PC sur le réseau local ou depuis Internet, indiquez l\'adresse du backend :',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _apiUrlCtrl,
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 11.5),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'http://192.168.1.68:4000/api ou https://.../api',
                            hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            filled: true,
                            fillColor: AppTheme.bgDeep,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.borderSubtle),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppTheme.accentBlue),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.cloud_done_rounded, size: 14, color: AppTheme.neonGreen),
                              label: const Text('Cloud (Render)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                              onPressed: () {
                                setState(() {
                                  _apiUrlCtrl.text = 'https://priostack-api.onrender.com/api';
                                  ref.read(authApiUrlProvider.notifier).setApiUrl(_apiUrlCtrl.text);
                                });
                              },
                            ),
                            ActionChip(
                              label: const Text('Wi-Fi (192.168.1.68)', style: TextStyle(fontSize: 10)),
                              onPressed: () {
                                setState(() {
                                  _apiUrlCtrl.text = 'http://192.168.1.68:4000/api';
                                  ref.read(authApiUrlProvider.notifier).setApiUrl(_apiUrlCtrl.text);
                                });
                              },
                            ),
                            ActionChip(
                              label: const Text('Localhost (ce PC)', style: TextStyle(fontSize: 10)),
                              onPressed: () {
                                setState(() {
                                  _apiUrlCtrl.text = 'http://localhost:4000/api';
                                  ref.read(authApiUrlProvider.notifier).setApiUrl(_apiUrlCtrl.text);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            onPressed: () {
                              ref.read(authApiUrlProvider.notifier).setApiUrl(_apiUrlCtrl.text);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Serveur configuré : ${_apiUrlCtrl.text}'),
                                  backgroundColor: AppTheme.neonGreen,
                                ),
                              );
                            },
                            child: const Text('Appliquer', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Divider(height: 28),

                // Info Compte Admin
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded, size: 14, color: AppTheme.neonAmber),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Identifiants Administrateur Neon :',
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email : admin@priostack.local\nPass  : AdminPrio2026!',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
