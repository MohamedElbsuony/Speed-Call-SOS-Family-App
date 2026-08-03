import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/native/direct_call_platform.dart';

class InCallScreen extends StatefulWidget {
  final String phoneNumber;
  final String contactName;
  final bool isIncoming;
  final String initialCallState; // "RINGING", "DIALING", "ACTIVE"

  const InCallScreen({
    super.key,
    required this.phoneNumber,
    required this.contactName,
    this.isIncoming = false,
    this.initialCallState = "DIALING",
  });

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  StreamSubscription<Map<String, dynamic>>? _callStateSubscription;

  String _callState = "DIALING"; // RINGING, DIALING, ACTIVE, HOLDING, DISCONNECTED
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _showKeypad = false;
  int _callDurationSeconds = 0;
  Timer? _durationTimer;
  String? _recordedFilePath;
  bool _hasPromptedRecording = false;

  final StringBuffer _dtmfBuffer = StringBuffer();

  @override
  void initState() {
    super.initState();
    _callState = widget.initialCallState;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_callState == "ACTIVE") {
      _startDurationTimer();
    }

    _listenToCallState();
  }

  void _listenToCallState() {
    _callStateSubscription = DirectCallPlatform.callStateStream.listen((data) {
      if (!mounted) return;
      final state = data['state'] as String? ?? 'UNKNOWN';
      final path = data['recordedFilePath'] as String?;

      if (path != null && path.isNotEmpty) {
        _recordedFilePath = path;
      }

      setState(() {
        _callState = state;
        if (data['callDuration'] != null) {
          _callDurationSeconds = data['callDuration'] as int;
        }
      });

      if (state == 'ACTIVE' && _durationTimer == null) {
        _startDurationTimer();
      } else if (state == 'DISCONNECTED') {
        _stopDurationTimer();
        _handleCallEnded();
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _callState == "ACTIVE") {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
  }

  void _handleCallEnded() {
    if (_hasPromptedRecording) return;
    _hasPromptedRecording = true;

    if (_recordedFilePath != null && File(_recordedFilePath!).existsSync()) {
      _showRecordingPromptDialog(_recordedFilePath!);
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
  }

  Future<void> _showRecordingPromptDialog(String tempPath) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.mic_rounded, color: Colors.indigoAccent),
              SizedBox(width: 10),
              Text("حفظ تسجيل المكالمة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            "تم تسجيل المكالمة بنجاح. هل تريد حفظ ملف التسجيل الصوتي لمكالمة (${widget.contactName.isNotEmpty ? widget.contactName : widget.phoneNumber})؟",
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Delete temp file
                try {
                  final file = File(tempPath);
                  if (file.existsSync()) file.deleteSync();
                } catch (_) {}
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("تم حذف التسجيل المؤقت"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text("حذف / عدم الحفظ", style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () {
                // Save recording permanently
                try {
                  final file = File(tempPath);
                  final targetDir = Directory('/storage/emulated/0/Download/SpeedCall_Recordings');
                  if (!targetDir.existsSync()) targetDir.createSync(recursive: true);

                  final targetPath = '${targetDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
                  file.copySync(targetPath);
                  file.deleteSync();
                } catch (_) {}

                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("تم حفظ تسجيل المكالمة بنجاح"),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("حفظ التسجيل", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _callStateSubscription?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    DirectCallPlatform.setMuted(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    DirectCallPlatform.setSpeaker(_isSpeakerOn);
  }

  void _onKeyPress(String digit) {
    _dtmfBuffer.write(digit);
    setState(() {});
    DirectCallPlatform.playDtmfTone(digit);
  }

  void _answerCall() {
    DirectCallPlatform.answerCall();
    setState(() {
      _callState = "ACTIVE";
    });
    _startDurationTimer();
  }

  void _rejectOrHangUp() {
    if (_callState == "RINGING") {
      DirectCallPlatform.rejectCall();
    } else {
      DirectCallPlatform.hangUp();
    }
    setState(() {
      _callState = "DISCONNECTED";
    });
    _stopDurationTimer();
    _handleCallEnded();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF020617),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Call Status Header
              _buildCallStatusHeader(loc),

              const Spacer(),

              // Caller Avatar / Animation
              if (!_showKeypad) _buildCallerAvatarSection(),

              if (_showKeypad) _buildDtmfKeypadOverlay(),

              const Spacer(),

              // Quick Action Bar (Mute, Keypad, Speaker)
              if (_callState != "DISCONNECTED") _buildQuickActionsRow(),

              const SizedBox(height: 32),

              // Bottom Call Action Buttons (Answer / Reject / Hangup)
              _buildBottomCallButtons(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallStatusHeader(AppLocalizations loc) {
    String statusText;
    Color statusColor = Colors.white70;

    switch (_callState) {
      case "RINGING":
        statusText = widget.isIncoming ? "مكالمة واردة..." : "جاري الاتصال...";
        statusColor = Colors.amberAccent;
        break;
      case "DIALING":
        statusText = "جاري الاتصال...";
        statusColor = Colors.lightBlueAccent;
        break;
      case "ACTIVE":
        statusText = _formatDuration(_callDurationSeconds);
        statusColor = Colors.greenAccent;
        break;
      case "HOLDING":
        statusText = "المكالمة قيد الانتظار";
        statusColor = Colors.orangeAccent;
        break;
      case "DISCONNECTED":
        statusText = "تم إنهاء المكالمة";
        statusColor = Colors.redAccent;
        break;
      default:
        statusText = "Speed Call";
    }

    return Column(
      children: [
        Text(
          widget.contactName.isNotEmpty ? widget.contactName : widget.phoneNumber,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.phoneNumber,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCallerAvatarSection() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.contactName.isNotEmpty ? widget.contactName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDtmfKeypadOverlay() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['*', '0', '#'],
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          if (_dtmfBuffer.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                _dtmfBuffer.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 2),
              ),
            ),
          for (var row in keys)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                return Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onKeyPress(key),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        child: Center(
                          child: Text(
                            key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute Button
          _buildActionButton(
            icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: _isMuted ? "مكتوم" : "كتم",
            isActive: _isMuted,
            onTap: _toggleMute,
          ),

          // Keypad Button
          _buildActionButton(
            icon: Icons.dialpad_rounded,
            label: "لوحة الرقم",
            isActive: _showKeypad,
            onTap: () {
              setState(() {
                _showKeypad = !_showKeypad;
              });
            },
          ),

          // Speaker Button
          _buildActionButton(
            icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
            label: "المكبر",
            isActive: _isSpeakerOn,
            onTap: _toggleSpeaker,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(32),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
              ),
              child: Icon(
                icon,
                color: isActive ? const Color(0xFF0F172A) : Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCallButtons() {
    if (_callState == "RINGING" && widget.isIncoming) {
      // Incoming Call: Show Accept (Green) and Decline (Red)
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Reject Button
          GestureDetector(
            onTap: _rejectOrHangUp,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
                boxShadow: [
                  BoxShadow(color: Colors.redAccent, blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 34),
            ),
          ),

          // Accept Button
          GestureDetector(
            onTap: _answerCall,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
                boxShadow: [
                  BoxShadow(color: Colors.greenAccent, blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.call_rounded, color: Colors.white, size: 34),
            ),
          ),
        ],
      );
    }

    // Active or Outgoing Call: Single Red Hang Up Button
    return GestureDetector(
      onTap: _rejectOrHangUp,
      child: Container(
        width: 76,
        height: 76,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent,
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 38),
      ),
    );
  }
}
