import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/anima_service.dart';
import '../services/translation_service.dart';
import '../src/rust/db.dart';
import '../widgets/main_drawer.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isFactoryResetting = false;

  String _userName = '';
  String _selectedLanguage = 'ES';
  double _temperature = 0.7;

  static const Map<String, String> _languageLabels = {
    'EN': 'English',
    'ES': 'Español',
    'DE': 'Deutsch',
    'RU': 'Русский',
    'JP': '日本語',
    'ZH': '中文',
    'AR': 'العربية',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  static const String _importModeMerge = 'merge';
  static const String _importModeReplace = 'replace';

  Future<void> _loadSettings() async {
    try {
      final animaService = context.read<AnimaService>();
      final userName = await animaService.getUserName().timeout(
        const Duration(seconds: 2),
        onTimeout: () => '',
      );
      final dbLanguage = await animaService.getAppLanguage().timeout(
        const Duration(seconds: 2),
        onTimeout: () => 'ES',
      );
      final normalizedLanguage = TranslationService.normalizeLanguageCode(dbLanguage);
      final temperature = await animaService.getTemperature().timeout(
        const Duration(seconds: 2),
        onTimeout: () => 0.7,
      );

      if (!mounted) return;
      context.read<TranslationService>().setLanguageLocal(normalizedLanguage);
      setState(() {
        _userName = userName;
        _selectedLanguage = normalizedLanguage;
        _temperature = temperature;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${tr(context, 'errorLoadingSettings')}: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showEditNameDialog() async {
    final controller = TextEditingController(text: _userName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          title: Text(tr(context, 'changeName')),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: tr(context, 'yourName'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr(context, 'cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: Text(tr(context, 'save')),
            ),
          ],
        );
      },
    );

    if (newName == null) return;
    if (!mounted) return;

    try {
      final animaService = context.read<AnimaService>();
      final saved = await animaService.setUserName(newName);
      if (!mounted) return;

      if (!saved) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr(context, 'nameSaveFailed'))));
        return;
      }

      setState(() {
        _userName = newName;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr(context, 'nameUpdated'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${tr(context, 'errorSavingName')}: $e')));
    }
  }

  Future<void> _updateLanguage(String code) async {
    final normalizedCode = TranslationService.normalizeLanguageCode(code);

    try {
      final saved = await context.read<TranslationService>().changeLanguage(normalizedCode);
      if (!mounted) return;

      if (!saved) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr(context, 'languageChangeFailed'))));
        return;
      }

      setState(() {
        _selectedLanguage = normalizedCode;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr(context, 'languageUpdated'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${tr(context, 'languageChangeFailed')}: $e')));
    }
  }

  Future<void> _saveTemperature(double value) async {
    try {
      final animaService = context.read<AnimaService>();
      final saved = await animaService.setTemperature(value);
      if (!mounted) return;

      if (!saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'creativitySaveFailed'))),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr(context, 'creativityUpdated'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${tr(context, 'errorSavingCreativity')}: $e')));
    }
  }

  Future<void> _exportBrainToFile() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final translationService = context.read<TranslationService>();
      String t(String key) => translationService.tr(key);

      final animaService = context.read<AnimaService>();
      final rawPayload = await animaService.exportBrain();
      final exportPayload = _ensureUsableBackupPayload(rawPayload);

      final password = await _askBackupPassword(t);
      if (password == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t('exportCancelled'))));
        return;
      }

      final isEncrypted = password.trim().isNotEmpty;
      final finalPayload = isEncrypted
          ? await _encryptBackupPayload(exportPayload, password.trim())
          : exportPayload;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final defaultFileName = isEncrypted
          ? 'anima_brain_$timestamp.encrypted.json'
          : 'anima_brain_$timestamp.json';

      final selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: t('exportBrain'),
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (selectedPath == null || selectedPath.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t('exportCancelled'))));
        return;
      }

      final targetPath = selectedPath.toLowerCase().endsWith('.json')
          ? selectedPath
          : '$selectedPath.json';

      final file = File(targetPath);
      await file.writeAsString(finalPayload, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t('brainExportedAt')}: $targetPath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'errorExportingBrain')}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _importBrainFromFile() async {
    if (_isImporting) return;

    setState(() {
      _isImporting = true;
    });

    try {
      final translationService = context.read<TranslationService>();
      String t(String key) => translationService.tr(key);

      final picked = await FilePicker.platform.pickFiles(
        dialogTitle: t('importBackup'),
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (picked == null || picked.files.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('importCancelled'))),
        );
        return;
      }

      final path = picked.files.single.path;
      if (path == null || path.trim().isEmpty) {
        throw Exception(t('invalidBackupFile'));
      }

      final rawPayload = await File(path).readAsString();
      final payload = await _resolveImportPayload(rawPayload, t);
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        throw Exception(t('invalidBackupFile'));
      }

      final importMode = await _askImportMode(t);
      if (importMode == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('importCancelled'))),
        );
        return;
      }

      await _applyImportedBackup(decoded, importMode: importMode);

      if (!mounted) return;
      await _loadSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('brainImported'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr(context, 'errorImportingBrain')}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<String> _resolveImportPayload(
    String rawPayload,
    String Function(String) t,
  ) async {
    final decoded = jsonDecode(rawPayload);
    if (decoded is! Map<String, dynamic>) {
      throw Exception(t('invalidBackupFile'));
    }

    final format = decoded['format']?.toString() ?? '';
    if (format != 'anima-backup-encrypted-v1') {
      return rawPayload;
    }

    final password = await _askDecryptPassword(t);
    if (password == null) {
      throw Exception(t('importCancelled'));
    }

    if (password.trim().isEmpty) {
      throw Exception(t('backupPasswordRequired'));
    }

    return _decryptBackupPayload(decoded, password.trim());
  }

  Future<String> _decryptBackupPayload(
    Map<String, dynamic> envelope,
    String password,
  ) async {
    final kdf = (envelope['kdf'] as Map?)?.cast<String, dynamic>() ?? {};
    final cipher = (envelope['cipher'] as Map?)?.cast<String, dynamic>() ?? {};

    final iterations = (kdf['iterations'] as num?)?.toInt() ?? 120000;
    final saltB64 = kdf['salt']?.toString() ?? '';
    final nonceB64 = cipher['nonce']?.toString() ?? '';
    final tagB64 = cipher['tag']?.toString() ?? '';
    final payloadB64 = envelope['payload']?.toString() ?? '';

    if (saltB64.isEmpty || nonceB64.isEmpty || tagB64.isEmpty || payloadB64.isEmpty) {
      throw const FormatException('Encrypted backup is missing required fields.');
    }

    final salt = base64Decode(saltB64);
    final nonce = base64Decode(nonceB64);
    final tag = base64Decode(tagB64);
    final cipherText = base64Decode(payloadB64);

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    final algorithm = AesGcm.with256bits();
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(tag),
    );

    final clearBytes = await algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(clearBytes);
  }

  Future<String?> _askDecryptPassword(String Function(String) t) async {
    final controller = TextEditingController();
    bool obscure = true;

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF18181B),
              title: Text(t('decryptBackupTitle')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t('decryptBackupHint'),
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: t('backupPassword'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: !obscure,
                        onChanged: (value) {
                          setDialogState(() {
                            obscure = !(value ?? false);
                          });
                        },
                      ),
                      Expanded(child: Text(t('showPassword'))),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: Text(t('cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(controller.text),
                  child: Text(t('continue')),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<String?> _askImportMode(String Function(String) t) async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          title: Text(t('importModeTitle')),
          content: Text(t('importModeHint')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(_importModeMerge),
              child: Text(t('importModeMerge')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(_importModeReplace),
              child: Text(t('importModeReplace')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _applyImportedBackup(
    Map<String, dynamic> backup, {
    required String importMode,
  }) async {
    final animaService = context.read<AnimaService>();
    final translationService = context.read<TranslationService>();

    final userName = (backup['user_name'] ?? '').toString().trim();
    final languageRaw = (backup['app_language'] ?? '').toString().trim();
    final language = languageRaw.isEmpty
        ? ''
        : TranslationService.normalizeLanguageCode(languageRaw);
    final temperatureRaw = backup['temperature'];
    final profileRaw = backup['user_profile'];

    if (userName.isNotEmpty) {
      await animaService.setUserName(userName);
    }

    if (language.isNotEmpty) {
      await translationService.changeLanguage(language);
    }

    if (temperatureRaw is num) {
      final temp = temperatureRaw.toDouble().clamp(0.1, 1.0);
      await animaService.setTemperature(temp);
    }

    final shouldReplace = importMode == _importModeReplace;
    final existingTraits = shouldReplace ? <ProfileTrait>[] : await animaService.getProfileTraits();
    final existingSet = existingTraits
        .map((item) => '${item.category.trim().toLowerCase()}||${item.content.trim().toLowerCase()}')
        .toSet();

    if (shouldReplace) {
      await animaService.clearProfile();
    }

    if (profileRaw is List) {
      for (final item in profileRaw) {
        if (item is! Map) continue;
        final category = (item['category'] ?? '').toString().trim();
        final content = (item['content'] ?? '').toString().trim();
        if (category.isEmpty || content.isEmpty) continue;

        final fingerprint = '${category.toLowerCase()}||${content.toLowerCase()}';
        if (existingSet.contains(fingerprint)) {
          continue;
        }

        await animaService.addProfileTrait(category, content);
        existingSet.add(fingerprint);
      }
    }
  }

  Future<String?> _askBackupPassword(String Function(String) t) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscure = true;
    String? validationError;

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF18181B),
              title: Text(t('encryptBackupTitle')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t('encryptBackupHint'),
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: t('backupPassword'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: t('backupPasswordConfirm'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: !obscure,
                        onChanged: (value) {
                          setDialogState(() {
                            obscure = !(value ?? false);
                          });
                        },
                      ),
                      Expanded(child: Text(t('showPassword'))),
                    ],
                  ),
                  if (validationError != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        validationError!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: Text(t('cancel')),
                ),
                TextButton(
                  onPressed: () {
                    final pass = passwordController.text;
                    final confirm = confirmController.text;

                    if (pass.isNotEmpty && pass != confirm) {
                      setDialogState(() {
                        validationError = t('passwordMismatch');
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(pass);
                  },
                  child: Text(t('save')),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    confirmController.dispose();
    return result;
  }

  Future<String> _encryptBackupPayload(String plainJson, String password) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final nonce = List<int>.generate(12, (_) => random.nextInt(256));

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 120000,
      bits: 256,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    final algorithm = AesGcm.with256bits();
    final secretBox = await algorithm.encrypt(
      utf8.encode(plainJson),
      secretKey: secretKey,
      nonce: nonce,
    );

    final encryptedEnvelope = {
      'format': 'anima-backup-encrypted-v1',
      'kdf': {
        'name': 'PBKDF2-HMAC-SHA256',
        'iterations': 120000,
        'salt': base64Encode(salt),
      },
      'cipher': {
        'name': 'AES-256-GCM',
        'nonce': base64Encode(secretBox.nonce),
        'tag': base64Encode(secretBox.mac.bytes),
      },
      'payload': base64Encode(secretBox.cipherText),
      'exported_at': DateTime.now().toIso8601String(),
    };

    return const JsonEncoder.withIndent('  ').convert(encryptedEnvelope);
  }

  String _ensureUsableBackupPayload(String rawPayload) {
    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is Map<String, dynamic>) {
        final profile = decoded['user_profile'];
        final memories = decoded['memories'];
        final userName = (decoded['user_name'] ?? '').toString().trim();

        final hasProfile = profile is List && profile.isNotEmpty;
        final hasMemories = memories is List && memories.isNotEmpty;
        final hasUserName = userName.isNotEmpty;

        if (hasProfile || hasMemories || hasUserName) {
          return rawPayload;
        }
      }
    } catch (_) {
      // If payload is malformed, fall back to template.
    }

    return jsonEncode({
      'user_name': _userName,
      'app_language': _selectedLanguage,
      'temperature': _temperature,
      'user_profile': <dynamic>[],
      'memories': <dynamic>[],
      'notes': 'Backup template generated because no profile/memory data was found.',
      'exported_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _runFactoryResetFlow() async {
    if (_isFactoryResetting) return;
    final translationService = context.read<TranslationService>();
    String t(String key) => translationService.tr(key);

    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          title: Text(t('warningTitle')),
          content: Text(t('factoryResetFirstConfirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t('continue')),
            ),
          ],
        );
      },
    );

    if (firstConfirm != true || !mounted) return;

    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          title: Text(t('finalWarningTitle')),
          content: Text(t('factoryResetSecondConfirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t('deleteAll')),
            ),
          ],
        );
      },
    );

    if (secondConfirm != true || !mounted) return;

    setState(() {
      _isFactoryResetting = true;
    });

    var flowFinished = false;
    final hardStopTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || flowFinished) return;
      debugPrint('[factory_reset_ui] watchdog forced spinner off');
      setState(() {
        _isFactoryResetting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('factoryResetError'))),
      );
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t('formattingAnima'))));

    try {
      debugPrint('[factory_reset_ui] request start');
      final animaService = context.read<AnimaService>();
      final resetOk = await animaService.factoryReset().timeout(
        const Duration(seconds: 4),
      );
      debugPrint('[factory_reset_ui] request completed result=$resetOk');
      if (!mounted) return;

      if (!resetOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('factoryResetFailed'))),
        );
        return;
      }

      setState(() {
        _userName = '';
        _temperature = 0.7;
        _selectedLanguage = 'ES';
      });

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('[factory_reset_ui] request failed error=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${t('factoryResetError')}: $e')));
    } finally {
      flowFinished = true;
      hardStopTimer.cancel();
      debugPrint('[factory_reset_ui] finally set loading false mounted=$mounted');
      if (mounted) {
        setState(() {
          _isFactoryResetting = false;
        });
      }
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 14, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _settingCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      drawer: const MainDrawer(currentSection: MainDrawerSection.settings),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: tr(context, 'openMenu'),
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
            );
          },
        ),
        title: Text(tr(context, 'settingsTitle')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                _sectionTitle(tr(context, 'identitySection')),
                _settingCard(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(tr(context, 'changeName')),
                    subtitle: Text(
                      _userName.trim().isEmpty ? tr(context, 'undefined') : _userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showEditNameDialog,
                  ),
                ),
                _settingCard(
                  child: ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: Text(tr(context, 'changeLanguage')),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        dropdownColor: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(12),
                        items: TranslationService.supportedLanguages
                            .map(
                              (code) => DropdownMenuItem<String>(
                                value: code,
                                child: Text(_languageLabels[code] ?? code),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          _updateLanguage(value);
                        },
                      ),
                    ),
                  ),
                ),
                _sectionTitle(tr(context, 'behaviorSection')),
                _settingCard(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology_outlined),
                            const SizedBox(width: 10),
                            Text(
                              tr(context, 'modelCreativity'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _temperature.toStringAsFixed(2),
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                        Slider(
                          value: _temperature,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          label: _temperature.toStringAsFixed(2),
                          onChanged: (value) {
                            setState(() {
                              _temperature = value;
                            });
                          },
                          onChangeEnd: _saveTemperature,
                        ),
                      ],
                    ),
                  ),
                ),
                _sectionTitle(tr(context, 'dataPrivacySection')),
                _settingCard(
                  child: ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: Text(tr(context, 'exportBrain')),
                    subtitle: Text(tr(context, 'saveLocalJson')),
                    trailing: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _isExporting ? null : _exportBrainToFile,
                  ),
                ),
                _settingCard(
                  child: ListTile(
                    leading: const Icon(Icons.upload_file_outlined),
                    title: Text(tr(context, 'importBackup')),
                    subtitle: Text(tr(context, 'restoreFromLocalJson')),
                    trailing: _isImporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _isImporting ? null : _importBrainFromFile,
                  ),
                ),
                _settingCard(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    title: Text(
                      tr(context, 'panicReset'),
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    subtitle: Text(tr(context, 'dangerZoneIrreversible')),
                    trailing: _isFactoryResetting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right, color: Colors.redAccent),
                    onTap: _isFactoryResetting ? null : _runFactoryResetFlow,
                  ),
                ),
              ],
            ),
    );
  }
}
