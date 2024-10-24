import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math';
import '../models/template.dart';
import '../models/role.dart';
import '../services/role_service.dart';

class GameScreen extends StatefulWidget {
  final Template template;
  final List<String> selectedPlayers;

  GameScreen({
    required this.template,
    required this.selectedPlayers,
  });

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Map<String, Role> _playerRoles = {};
  final Map<String, Color> _roleColors = {
    'villager': Colors.brown,
    'wolf': Colors.red,
    'doctor': Colors.blue,
    'jester': Colors.purple,
    'matchmaker': Colors.pink,
    'seer': Colors.indigo,
    'thief': Colors.orange,
    'bomber': Colors.black,
  };
  
  bool _showRoles = false;
  bool _rolesDistributed = false;
  bool _isNight = true;
  bool _isTimerActive = false;
  List<String> _deadPlayers = [];
  List<String> _currentNightQueue = [];
  String? _currentActor;
  Map<String, String> _bomberTargets = {};
  String? _doctorSelfHeal;
  List<String> _matchedPlayers = [];
  Map<String, String> _seerDiscoveries = {};
  bool _isVoting = false;
  String? _selectedForVote;
  int _remainingSeconds = 180;

  // Timer için
  Timer? _timer;
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _distributeRoles() {
    if (_rolesDistributed) return;

    final random = Random();
    List<String> players = List.from(widget.selectedPlayers);
    List<Role> availableRoles = [];

    for (var role in RoleService.defaultRoles) {
      if (widget.template.enabledRoles[role.id] ?? true) {
        if (role.id != 'villager' && role.id != 'wolf') {
          availableRoles.add(role);
        }
      }
    }

    availableRoles.shuffle(random);

    int wolfCount = players.length >= 8 ? (random.nextBool() ? 2 : 1) : 1;
    for (int i = 0; i < wolfCount; i++) {
      if (players.isNotEmpty) {
        String player = players.removeAt(random.nextInt(players.length));
        _playerRoles[player] = RoleService.defaultRoles
            .firstWhere((role) => role.id == 'wolf');
      }
    }

    for (var role in availableRoles) {
      if (players.isNotEmpty) {
        String player = players.removeAt(random.nextInt(players.length));
        _playerRoles[player] = role;
      }
    }

    for (String player in players) {
      _playerRoles[player] = RoleService.defaultRoles
          .firstWhere((role) => role.id == 'villager');
    }

    _setupNightQueue();

    setState(() {
      _rolesDistributed = true;
    });
  }

  void _setupNightQueue() {
    _currentNightQueue.clear();
    
    // Sıralama: Hırsız > Çöpçatan > Kurt > Bombacı > Doktor > Gözcü
    List<String> roleOrder = ['thief', 'matchmaker', 'wolf', 'bomber', 'doctor', 'seer'];
    
    for (String roleId in roleOrder) {
      for (var entry in _playerRoles.entries) {
        if (entry.value.id == roleId && !_deadPlayers.contains(entry.key)) {
          // Özel durumlar için kontroller
          if (roleId == 'thief' && _currentNightQueue.isEmpty) {
            _currentNightQueue.add(entry.key);
          } else if (roleId == 'matchmaker' && _matchedPlayers.isEmpty) {
            _currentNightQueue.add(entry.key);
          } else if (roleId != 'thief' && roleId != 'matchmaker') {
            _currentNightQueue.add(entry.key);
          }
        }
      }
    }
    
    if (_currentNightQueue.isNotEmpty) {
      _currentActor = _currentNightQueue.first;
    }
  }

  void _nextNightAction() {
    if (_currentNightQueue.isEmpty) return;
    
    _currentNightQueue.removeAt(0);
    setState(() {
      _currentActor = _currentNightQueue.isNotEmpty ? _currentNightQueue.first : null;
      if (_currentActor == null) {
        _processNightResults();
      }
    });
  }

  void _processNightResults() {
    setState(() {
      _isNight = false;
      // Ölümleri işle ve renkleri güncelle
    });
  }

  void _startVoting() {
    setState(() {
      _isVoting = true;
      _selectedForVote = null;
    });
  }

  void _executeVoted() {
    if (_selectedForVote != null) {
      setState(() {
        _deadPlayers.add(_selectedForVote!);
        if (_playerRoles[_selectedForVote]?.id == 'jester') {
          _showGameEndDialog('Soytarı ${_selectedForVote} kazandı!');
        }
        _checkGameEnd();
      });
    }
  }

  void _toggleTimer() {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
      setState(() {
        _isTimerActive = false;
      });
    } else {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer?.cancel();
            _isTimerActive = false;
            _remainingSeconds = 180;
          }
        });
      });
      setState(() {
        _isTimerActive = true;
      });
    }
  }

  void _startNight() {
    setState(() {
      _isNight = true;
      _setupNightQueue();
    });
  }

  void _checkGameEnd() {
    int aliveWolves = 0;
    int aliveVillagers = 0;

    for (var entry in _playerRoles.entries) {
      if (!_deadPlayers.contains(entry.key)) {
        if (entry.value.id == 'wolf') {
          aliveWolves++;
        } else {
          aliveVillagers++;
        }
      }
    }

    if (aliveWolves == 0) {
      _showGameEndDialog('Köy kazandı!');
    } else if (aliveWolves >= aliveVillagers) {
      _showGameEndDialog('Kurtlar kazandı!');
    }
  }

  void _showGameEndDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Oyun Bitti'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('Ana Menüye Dön'),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesList() {
    List<Widget> roleWidgets = [];
    _playerRoles.forEach((player, role) {
      if (role.id != 'villager') {
        roleWidgets.add(
          Container(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '$player = ${role.name}',
              style: TextStyle(
                color: _roleColors[role.id],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
    });
    return Column(children: roleWidgets);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNight ? 'Gece' : 'Gündüz'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_rolesDistributed)
            IconButton(
              icon: Icon(_showRoles ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showRoles = !_showRoles),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_showRoles && _rolesDistributed)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: _buildRolesList(),
            ),
          if (_isNight && _currentActor != null)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Sıradaki: $_currentActor (${_playerRoles[_currentActor]?.name})',
                style: TextStyle(fontSize: 24),
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 3,
              ),
              itemCount: widget.selectedPlayers.length,
              itemBuilder: (ctx, index) {
                final player = widget.selectedPlayers[index];
                Color playerColor = _deadPlayers.contains(player)
                    ? Colors.red
                    : _showRoles
                        ? _roleColors[_playerRoles[player]?.id] ?? Colors.grey
                        : Colors.grey;

                return GestureDetector(
                  onTap: () {
                    // Oyuncu seçme mantığı
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: playerColor,
                      borderRadius: BorderRadius.circular(16.0),
                      border: _selectedForVote == player
                          ? Border.all(color: Colors.yellow, width: 3)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        player,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (!_rolesDistributed)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _distributeRoles,
                child: Text('Rolleri Dağıt'),
              ),
            ),
          if (_rolesDistributed && _isNight && _currentActor != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _nextNightAction,
                child: Text('Sıradaki Rol'),
              ),
            ),
          if (_rolesDistributed && !_isNight)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _toggleTimer,
                    child: Text(_isTimerActive ? 'Sayacı Durdur' : 'Sayaç Başlat'),
                  ),
                  ElevatedButton(
                    onPressed: _startVoting,
                    child: Text('Oylama Yap'),
                  ),
                  ElevatedButton(
                    onPressed: _startNight,
                    child: Text('Geceye Git'),
                  ),
                ],
              ),
            ),
          if (_isTimerActive)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Kalan Süre: ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 20),
              ),
            ),
        ],
      ),
    );
  }
}