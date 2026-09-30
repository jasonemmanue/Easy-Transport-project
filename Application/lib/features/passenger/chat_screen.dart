import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Messagerie style WhatsApp, rattachee a une course (historique par course).
/// Partagee entre passager et chauffeur via [peerName].
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.peerName = 'Kevin Kamga',
    this.rideLabel = 'Course du jour - Akwa > Aeroport',
  });

  final String peerName;
  final String rideLabel;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <_Msg>[
    const _Msg('Bonjour, je suis a 5 min', false, '10:12'),
    const _Msg('Merci ! Je vous attends au portail bleu.', true, '10:13'),
    const _Msg('Voici l\'entree', true, '10:13', photo: true),
    const _Msg('Je suis coince dans un petit embouteillage.', false, '10:15'),
  ];
  final _ctrl = TextEditingController();

  static const _quickReplies = [
    'J\'arrive',
    'Je suis devant',
    'Pouvez-vous m\'appeler ?',
    'Merci !',
  ];

  String get _now {
    final t = TimeOfDay.now();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  void _send(String text, {bool photo = false}) {
    if (text.trim().isEmpty && !photo) return;
    setState(() {
      _messages.add(_Msg(text.trim(), true, _now, photo: photo));
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.classSerenity,
                child: Icon(Icons.person, color: Colors.white, size: 18)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.peerName, style: const TextStyle(fontSize: 16)),
                const Text('en ligne',
                    style: TextStyle(fontSize: 11, color: AppColors.classEco)),
              ],
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
              icon: const Icon(Icons.phone_outlined),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appel masque en cours...')))),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: AppColors.primary.withOpacity(0.06),
            child: Row(
              children: [
                const Icon(Icons.receipt_long,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(widget.rideLabel,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.primary)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                return Align(
                  alignment:
                      m.mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(8),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.72),
                    decoration: BoxDecoration(
                      color: m.mine ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(m.mine ? 14 : 2),
                        bottomRight: Radius.circular(m.mine ? 2 : 14),
                      ),
                      border:
                          !m.mine ? Border.all(color: AppColors.divider) : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (m.photo)
                          Container(
                            width: 180,
                            height: 120,
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(colors: [
                                Color(0xFF90A4AE),
                                Color(0xFF546E7A)
                              ]),
                            ),
                            child: const Icon(Icons.photo,
                                color: Colors.white70, size: 40),
                          ),
                        if (m.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(m.text,
                                style: TextStyle(
                                    color: m.mine
                                        ? Colors.white
                                        : AppColors.textPrimary)),
                          ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(m.time,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: m.mine
                                          ? Colors.white70
                                          : AppColors.textSecondary)),
                              if (m.mine) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.done_all,
                                    size: 14, color: Colors.lightBlueAccent),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: _quickReplies
                  .map((q) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                            label: Text(q), onPressed: () => _send(q)),
                      ))
                  .toList(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  IconButton(
                      tooltip: 'Envoyer une photo',
                      onPressed: () => _send('', photo: true),
                      icon: const Icon(Icons.photo_camera_outlined)),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: _send,
                      decoration: const InputDecoration(
                          hintText: 'Message', border: OutlineInputBorder()),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _send(_ctrl.text),
                    icon: const Icon(Icons.send, color: AppColors.primary),
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

class _Msg {
  const _Msg(this.text, this.mine, this.time, {this.photo = false});
  final String text;
  final bool mine;
  final String time;
  final bool photo;
}
