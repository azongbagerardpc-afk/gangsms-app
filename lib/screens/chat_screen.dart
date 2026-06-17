import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String pseudo;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.pseudo,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = Supabase.instance.client;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  List<Message> _messages = [];
  bool _isRecording = false;
  bool _sending = false;
  String? _playingId;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
    _updatePresence();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _updatePresence() async {
    try {
      await _supabase.from('presence').upsert({
        'pseudo': widget.pseudo,
        'last_seen': DateTime.now().toIso8601String(),
        'current_room': widget.roomId,
      });
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    try {
      final data = await _supabase
          .from('messages')
          .select()
          .eq('room_id', widget.roomId)
          .order('created_at', ascending: true)
          .limit(100);
      if (mounted) {
        setState(() {
          _messages = (data as List).map((m) => Message.fromMap(m)).toList();
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Erreur chargement: $e');
    }
  }

  void _subscribeToMessages() {
    _channel = _supabase
        .channel('chat_${widget.roomId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: widget.roomId,
          ),
          callback: (payload) {
            if (mounted) {
              final msg = Message.fromMap(payload.newRecord);
              setState(() => _messages.add(msg));
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);
    try {
      await _supabase.from('messages').insert({
        'room_id': widget.roomId,
        'sender': widget.pseudo,
        'content': text,
        'type': 'text',
      });
    } catch (e) {
      debugPrint('Erreur envoi texte: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image == null) return;

      setState(() => _sending = true);
      final file = File(image.path);
      final fileName = '${widget.roomId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('media').upload(fileName, file);
      final url = _supabase.storage.from('media').getPublicUrl(fileName);

      await _supabase.from('messages').insert({
        'room_id': widget.roomId,
        'sender': widget.pseudo,
        'type': 'image',
        'file_url': url,
      });
    } catch (e) {
      debugPrint('Erreur image: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path == null) return;

      setState(() => _sending = true);
      try {
        final file = File(path);
        final fileName = '${widget.roomId}/${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _supabase.storage.from('media').upload(fileName, file);
        final url = _supabase.storage.from('media').getPublicUrl(fileName);

        await _supabase.from('messages').insert({
          'room_id': widget.roomId,
          'sender': widget.pseudo,
          'type': 'audio',
          'file_url': url,
        });
      } catch (e) {
        debugPrint('Erreur audio: $e');
      } finally {
        if (mounted) setState(() => _sending = false);
      }
    } else {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission micro refusée')),
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() => _isRecording = true);
    }
  }

  Future<void> _togglePlay(String id, String url) async {
    if (_playingId == id) {
      await _audioPlayer.stop();
      setState(() => _playingId = null);
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() => _playingId = id);
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingId = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun message. Sois le premier !',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildMessage(_messages[i]),
                  ),
          ),
          if (_sending)
            const LinearProgressIndicator(
              backgroundColor: Color(0xFF1E1E1E),
              color: Color(0xFF00E676),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessage(Message msg) {
    final isMe = msg.sender == widget.pseudo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF444444),
              child: Text(
                msg.sender[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF00C060)
                    : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        msg.sender,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00E676),
                        ),
                      ),
                    ),
                  _buildContent(msg, isMe),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(msg.createdAt.toLocal()),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.black45 : Colors.white38,
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

  Widget _buildContent(Message msg, bool isMe) {
    final textColor = isMe ? Colors.black87 : Colors.white;
    switch (msg.type) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            msg.fileUrl!,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
                  ),
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 48),
          ),
        );
      case 'audio':
        final isPlaying = _playingId == msg.id;
        return GestureDetector(
          onTap: () => _togglePlay(msg.id, msg.fileUrl!),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPlaying ? Icons.stop_circle : Icons.play_circle,
                color: isMe ? Colors.black87 : const Color(0xFF00E676),
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                isPlaying ? 'En cours...' : 'Message vocal',
                style: TextStyle(color: textColor, fontSize: 13),
              ),
            ],
          ),
        );
      default:
        return Text(
          msg.content ?? '',
          style: TextStyle(color: textColor, fontSize: 14),
        );
    }
  }

  Widget _buildInputBar() {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 28),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, color: Color(0xFF00E676)),
            onPressed: _sending ? null : _sendImage,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendText(),
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isRecording ? Icons.stop_circle : Icons.mic,
              color: _isRecording ? Colors.red : const Color(0xFF00E676),
              size: 28,
            ),
            onPressed: _sending ? null : _toggleRecording,
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF00E676)),
            onPressed: _sending ? null : _sendText,
          ),
        ],
      ),
    );
  }
}
