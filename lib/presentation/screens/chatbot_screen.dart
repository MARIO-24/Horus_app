import 'package:flutter/material.dart';
import 'package:horus_app/core/l10n/app_l10n.dart';
import 'package:horus_app/presentation/providers/chatbot_provider.dart';
import 'package:horus_app/presentation/widgets/chat_bubble.dart';
import 'package:horus_app/presentation/widgets/custom_drawer.dart';
import 'package:provider/provider.dart';

/// Pantalla del chatbot de entrenamiento personal simulado
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();

    final chatbotProvider = context.read<ChatbotProvider>();
    await chatbotProvider.sendMessage(text);

    // Scroll al último mensaje tras la respuesta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatbot = context.watch<ChatbotProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppL10n.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'iconos/Icono_ChatBot.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Horus Bot', style: TextStyle(fontSize: 16)),
                Text(
                  chatbot.isTyping ? l10n.typing : l10n.virtualTrainer,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpiar chat',
            onPressed: () => _showClearDialog(context),
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // ── Lista de mensajes ────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: chatbot.messages.length +
                  (chatbot.isTyping ? 1 : 0),
              itemBuilder: (context, i) {
                // Mostrar indicador de escritura al final
                if (chatbot.isTyping &&
                    i == chatbot.messages.length) {
                  return const TypingIndicator();
                }
                final msg = chatbot.messages[i];
                return ChatBubble(
                  text: msg.text,
                  isUser: msg.isUser,
                  timestamp: msg.timestamp,
                );
              },
            ),
          ),

          // ── Sugerencias rápidas ──────────────────────────────────────
          if (!chatbot.isTyping) _QuickSuggestions(onTap: _sendSuggestion),

          // ── Campo de entrada ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      focusNode: _focusNode,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Pregunta algo sobre fitness...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: chatbot.isTyping ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                    color: colorScheme.primary,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.1),
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

  void _sendSuggestion(String text) {
    _inputCtrl.text = text;
    _send();
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpiar chat'),
        content: const Text('¿Quieres borrar el historial de mensajes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatbotProvider>().clearChat();
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }
}

/// Widget de sugerencias rápidas predefinidas
class _QuickSuggestions extends StatelessWidget {
  final void Function(String) onTap;
  const _QuickSuggestions({required this.onTap});

  static const List<String> suggestions = [
    '¿Qué debo comer antes de entrenar?',
    'Dame motivación 💪',
    '¿Cuánto descanso entre series?',
    'Consejos para perder grasa',
    '¿Para qué sirve la creatina?',
    'Ejercicio para abdominales',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: suggestions.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ActionChip(
            label: Text(
              suggestions[i],
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () => onTap(suggestions[i]),
          ),
        ),
      ),
    );
  }
}
