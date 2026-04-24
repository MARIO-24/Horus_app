import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:horus_app/services/chatbot_service.dart';

/// Proveedor del chatbot — gestiona los mensajes por usuario con persistencia en Firestore
class ChatbotProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String? _currentUid;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;

  static const _welcomeText =
      '¡Hola! Soy Horus 🏋️, tu entrenador personal virtual. Estoy aquí para ayudarte con consejos de entrenamiento, nutrición y motivación. ¡Pregúntame lo que quieras!';

  ChatbotProvider() {
    _messages.add(ChatMessage(
      text: _welcomeText,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  /// Carga el historial de chat del usuario desde Firestore
  Future<void> loadChat(String uid) async {
    _currentUid = uid;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(uid)
          .get();

      _messages.clear();

      if (doc.exists) {
        final List<dynamic> raw =
            (doc.data()?['messages'] as List<dynamic>?) ?? [];
        for (final m in raw) {
          _messages.add(ChatMessage(
            text: m['text'] as String,
            isUser: m['isUser'] as bool,
            timestamp: (m['timestamp'] as Timestamp).toDate(),
          ));
        }
      }

      if (_messages.isEmpty) {
        _messages.add(ChatMessage(
          text: _welcomeText,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    } catch (_) {
      if (_messages.isEmpty) {
        _messages.add(ChatMessage(
          text: _welcomeText,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    }
    notifyListeners();
  }

  /// Envía un mensaje del usuario y genera la respuesta del bot
  Future<void> sendMessage(String text, {bool isEnglish = false}) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isTyping = true;
    notifyListeners();

    // Construir historial: excluir el mensaje recién añadido y garantizar que
    // empiece por un mensaje del usuario (Gemini lo requiere).
    final allPrev = _messages.take(_messages.length - 1).toList();
    final firstUserIdx = allPrev.indexWhere((m) => m.isUser);
    final relevant =
        firstUserIdx >= 0 ? allPrev.skip(firstUserIdx).toList() : <ChatMessage>[];
    final history = relevant
        .skip(relevant.length > 6 ? relevant.length - 6 : 0)
        .map((m) => {'role': m.isUser ? 'user' : 'model', 'text': m.text})
        .toList();

    final response = await ChatbotService.generateResponse(
      text.trim(), history,
      isEnglish: isEnglish,
    );
    _messages.add(ChatMessage(
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    _isTyping = false;
    notifyListeners();

    _saveToFirestore();
  }

  /// Limpia el historial del chat (UI + Firestore)
  void clearChat({bool isEnglish = false}) {
    _messages.clear();
    _messages.add(ChatMessage(
      text: isEnglish
          ? 'Chat cleared! How can I help you? 💪'
          : '¡Chat reiniciado! ¿En qué te puedo ayudar? 💪',
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
    _saveToFirestore();
  }

  /// Resetea el estado local al cerrar sesión (sin tocar Firestore)
  void clear() {
    _currentUid = null;
    _messages.clear();
    _messages.add(ChatMessage(
      text: _welcomeText,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  /// Elimina el historial del chat del usuario de Firestore y limpia el estado local
  Future<void> deleteChat(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('chats').doc(uid).delete();
    } catch (_) {}
    clear();
  }

  Future<void> _saveToFirestore() async {
    if (_currentUid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_currentUid)
          .set({
        'messages': _messages
            .map((m) => {
                  'text': m.text,
                  'isUser': m.isUser,
                  'timestamp': Timestamp.fromDate(m.timestamp),
                })
            .toList(),
      });
    } catch (_) {
      // No es crítico si falla el guardado
    }
  }
}
