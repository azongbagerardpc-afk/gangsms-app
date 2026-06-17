import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class RoomsScreen extends StatefulWidget {
  final String pseudo;
  const RoomsScreen({super.key, required this.pseudo});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _onlineUsers = [];
  Timer? _presenceTimer;

  @override
  void initState() {
    super.initState();
    _updatePresence();
    _loadOnlineUsers();
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updatePresence();
      _loadOnlineUsers();
    });
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    super.dispose();
  }

  Future<void> _updatePresence() async {
    try {
      await _supabase.from('presence').upsert({
        'pseudo': widget.pseudo,
        'last_seen': DateTime.now().toIso8601String(),
        'current_room': null,
      });
    } catch (_) {}
  }

  Future<void> _loadOnlineUsers() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(minutes: 2));
      final data = await _supabase
          .from('presence')
          .select()
          .gte('last_seen', cutoff.toIso8601String());
      if (mounted) {
        setState(() => _onlineUsers = List<Map<String, dynamic>>.from(data));
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    try {
      await _supabase.from('presence').delete().eq('pseudo', widget.pseudo);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pseudo');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GangSMS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _updatePresence();
              _loadOnlineUsers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_onlineUsers.isNotEmpty) _buildOnlineBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Salons',
              style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kRooms.length,
              itemBuilder: (_, i) => _buildRoomCard(kRooms[i]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildOnlineBar() {
    return Container(
      height: 76,
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 0, 4),
            child: Text(
              '${_onlineUsers.length} en ligne',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _onlineUsers.length,
              itemBuilder: (_, i) {
                final user = _onlineUsers[i];
                final isMe = user['pseudo'] == widget.pseudo;
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isMe
                                ? const Color(0xFF00E676)
                                : const Color(0xFF444444),
                            child: Text(
                              (user['pseudo'] as String)[0].toUpperCase(),
                              style: TextStyle(
                                color: isMe ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF1E1E1E), width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isMe ? 'Toi' : user['pseudo'],
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Map<String, String> room) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                roomId: room['id']!,
                roomName: room['name']!,
                pseudo: widget.pseudo,
              ),
            ),
          ).then((_) {
            _updatePresence();
            _loadOnlineUsers();
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Text(room['emoji']!, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Text(
                room['name']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF00E676),
            child: Text(
              widget.pseudo[0].toUpperCase(),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.pseudo,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00E676),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text('En ligne', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
