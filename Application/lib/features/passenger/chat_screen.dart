import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <_Msg>[
    const _Msg('Bonjour, je suis a 5 min', false, '10:12'),
    const _Msg('Merci ! Je vous attends au portail bleu.', true, '10:13'),
    const _Msg('Je suis coince dans un petit embouteillage.', false, '10:15'),
  ];
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.classSerenity,
                child: Icon(Icons.person, color: Colors.white, size: 18)),
            SizedBox(width: 8),
            Text('Kevin Kamga'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.phone_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: m.mine
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft:
                            Radius.circular(m.mine ? 14 : 2),
                        bottomRight:
                            Radius.circular(m.mine ? 2 : 14),
                      ),
                      border: !m.mine
                          ? Border.all(color: AppColors.divider)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.text,
                            style: TextStyle(
                                color: m.mine ? Colors.white : Colors.black)),
                        const SizedBox(height: 4),
                        Text(m.time,
                            style: TextStyle(
                                fontSize: 10,
                                color: m.mine
                                    ? Colors.white70
                                    : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.attach_file)),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                          hintText: 'Message', border: OutlineInputBorder()),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_ctrl.text.isEmpty) return;
                      setState(() {
                        _messages.add(_Msg(_ctrl.text, true, 'now'));
                        _ctrl.clear();
                      });
                    },
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
  const _Msg(this.text, this.mine, this.time);
  final String text;
  final bool mine;
  final String time;
}
