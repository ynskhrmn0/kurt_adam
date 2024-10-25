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
    'wolf': Colors.orange,
    'doctor': Colors.blue,
    'jester': Colors.purple,
    'matchmaker': Colors.pink,
    'seer': Colors.indigo,
    'thief': Colors.orange,
    'bomber': Colors.black,
  };

  String? _wolfTarget;
  String? _doctorSelfHeal;
  String? _doctorTarget;
  List<String> _deadPlayers = [];
  List<String> _currentNightQueue = [];
  String? _currentActor;
  String? _selectedPlayer;
  String? _currentTarget;
  List<String> _wolfPlayers = [];
  bool _showRoles = false;
  bool _rolesDistributed = false;
  bool _isNight = true;
  bool _isTimerActive = false;
  Map<String, String> _bomberTargets = {};
  List<String> _matchedPlayers = [];
  Map<String, String> _seerDiscoveries = {};
  bool _isVoting = false;
  String? _selectedForVote;
  int _remainingSeconds = 180;
  String? _thiefNewRole;
  bool _showSeerHistory = false;

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
        _playerRoles[player] =
            RoleService.defaultRoles.firstWhere((role) => role.id == 'wolf');
      }
    }

    for (var role in availableRoles) {
      if (players.isNotEmpty) {
        String player = players.removeAt(random.nextInt(players.length));
        _playerRoles[player] = role;
      }
    }

    for (String player in players) {
      _playerRoles[player] =
          RoleService.defaultRoles.firstWhere((role) => role.id == 'villager');
    }

    _setupNightQueue();

    setState(() {
      _rolesDistributed = true;
    });
  }

  void _setupNightQueue() {
    _currentNightQueue.clear();

    List<String> roleOrder = [
      'thief',
      'matchmaker',
      'wolf',
      'bomber',
      'doctor',
      'seer'
    ];

    for (String roleId in roleOrder) {
      if (roleId == 'wolf') {
        // Kurt rolüne sahip tüm oyuncuları bul
        _wolfPlayers = _playerRoles.entries
            .where((entry) =>
                entry.value.id == 'wolf' && !_deadPlayers.contains(entry.key))
            .map((entry) => entry.key)
            .toList();

        // Eğer hayatta olan kurt varsa, sıraya ekle
        if (_wolfPlayers.isNotEmpty) {
          _currentNightQueue
              .add(_wolfPlayers.first); // Sadece bir kurt ekliyoruz
        }
      } else {
        // Diğer roller için normal kontrol
        for (var entry in _playerRoles.entries) {
          if (entry.value.id == roleId && !_deadPlayers.contains(entry.key)) {
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
    }

    if (_currentNightQueue.isNotEmpty) {
      _currentActor = _currentNightQueue.first;
    }
  }

  void _handlePlayerTap(String player) {
    if (_deadPlayers.contains(player)) return;

    if (_isVoting) {
      setState(() {
        // Eğer zaten seçili olan kişiye tıklandıysa seçimi kaldır
        if (_selectedForVote == player) {
          _selectedForVote = null;
        } else {
          _selectedForVote = player;
        }
      });
      return;
    }

    if (!_isNight || _currentActor == null) return;

    final currentRole = _playerRoles[_currentActor]?.id;

    setState(() {
      if (_selectedPlayer == player) {
        _selectedPlayer = null;
        _currentTarget =
            null; // Seçimi iptal ettiğimizde hedefi de temizleyelim
        // Role özgü seçimleri iptal et
        switch (currentRole) {
          case 'wolf':
            _wolfTarget = null;
            break;
          case 'doctor':
            _doctorTarget = null;
            if (player == _currentActor) {
              _doctorSelfHeal = null;
            }
            break;
          case 'matchmaker':
            _matchedPlayers.remove(player);
            break;
          case 'bomber':
            _bomberTargets.remove(player);
            break;
        }
        return;
      }

      _selectedPlayer = player;
      _currentTarget = player;

      switch (currentRole) {
        case 'wolf':
          if (player != _currentActor && !_wolfPlayers.contains(player)) {
            _wolfTarget = player; // Hedefi kaydet ama hemen öldürme
            _selectedPlayer = player;
          }
          break;

        case 'doctor':
          if (player == _currentActor) {
            if (_doctorSelfHeal != null) {
              _selectedPlayer = null;
              return;
            }
            _doctorSelfHeal = player;
          }
          _doctorTarget = player;
          break;

        case 'matchmaker':
          if (_matchedPlayers.length < 2 && !_matchedPlayers.contains(player)) {
            _matchedPlayers.add(player);
            if (_matchedPlayers.length == 2) {
              _nextNightAction();
            }
          }
          break;

        case 'seer':
          _seerDiscoveries[player] = _playerRoles[player]?.name ?? 'Bilinmiyor';
          _nextNightAction();
          break;

        case 'thief':
          if (player != _currentActor && _thiefNewRole == null) {
            _thiefNewRole = _playerRoles[player]?.id;
            _playerRoles[_currentActor!] = _playerRoles[player]!;
            _deadPlayers.add(player);
            _nextNightAction();
          }
          break;

        case 'bomber':
          if (player != _currentActor) {
            _bomberTargets[player] = player;
            _nextNightAction();
          }
          break;
      }
    });
  }

  void _nextNightAction() {
    if (_currentNightQueue.isEmpty) return;

    _currentNightQueue.removeAt(0);
    setState(() {
      _selectedPlayer = null;
      _currentTarget = null; // Yeni role geçerken hedefi temizle
      _currentActor =
          _currentNightQueue.isNotEmpty ? _currentNightQueue.first : null;
      if (_currentActor == null) {
        _processNightResults();
      }
    });
  }

  void _processNightResults() {
    setState(() {
      // Kurt hedefini öldür
      if (_wolfTarget != null) {
        // Doktor koruması kontrolü
        if (_doctorTarget != _wolfTarget) {
          _deadPlayers.add(_wolfTarget!);
        }
      }

      _wolfTarget = null;
      _doctorTarget = null;

      // Çöpçatan kontrolü
      _checkMatchedPlayersDeaths();
      _isNight = false;
    });

    _checkGameEnd();
  }

  void _checkMatchedPlayersDeaths() {
    if (_matchedPlayers.length == 2) {
      if (_deadPlayers.contains(_matchedPlayers[0]) &&
          !_deadPlayers.contains(_matchedPlayers[1])) {
        _deadPlayers.add(_matchedPlayers[1]);
      } else if (_deadPlayers.contains(_matchedPlayers[1]) &&
          !_deadPlayers.contains(_matchedPlayers[0])) {
        _deadPlayers.add(_matchedPlayers[0]);
      }
    }
  }

  void _detonateBombs() {
    setState(() {
      _deadPlayers.addAll(_bomberTargets.values);
      _bomberTargets.clear();
      _checkMatchedPlayersDeaths();
      _checkGameEnd();
    });
  }

  void _startVoting() {
    setState(() {
      _isVoting = true;
      _selectedForVote = null;
    });
  }

  void _endVoting() {
    if (_selectedForVote == null) {
      setState(() {
        _isVoting = false;
      });
      return;
    }
    if (_selectedForVote != null) {
      setState(() {
        if (_playerRoles[_selectedForVote]?.id == 'jester') {
          _showGameEndDialog('Soytarı $_selectedForVote kazandı!');
        } else {
          _deadPlayers.add(_selectedForVote!);
          _checkMatchedPlayersDeaths();
          _checkGameEnd();
        }
        _isVoting = false;
        _selectedForVote = null;
      });
    }
  }

  void _executeVoted() {
    if (_selectedForVote != null) {
      setState(() {
        _deadPlayers.add(_selectedForVote!);
        if (_playerRoles[_selectedForVote]?.id == 'jester') {
          _showGameEndDialog('Soytarı ${_selectedForVote} kazandı!');
        }
        _checkMatchedPlayersDeaths();
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
      setState(() {
        _remainingSeconds = 180; // Reset timer to 3 minutes
      });
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer?.cancel();
            _isTimerActive = false;
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
      _selectedPlayer = null;
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (!_showRoles) // Eğer roller zaten gösterilmiyorsa butonu göster
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showRoles = true;
                  });
                  Navigator.of(context).pop(); // Dialogu kapat
                  _showGameEndDialog(message); // Yeni dialog göster
                },
                child: Text('Rolleri Göster'),
              ),
            if (_showRoles) // Roller gösteriliyorsa listeyi göster
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _buildPlayerList(),
              ),
          ],
        ),
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

  Widget _buildPlayerList() {
    // Rolleri sıralamak için map oluştur
    Map<String, List<String>> roleGroups = {};

    _playerRoles.forEach((player, role) {
      if (!roleGroups.containsKey(role.id)) {
        roleGroups[role.id] = [];
      }
      roleGroups[role.id]!.add(player);
    });

    // Her rol grubu için widget listesi oluştur
    List<Widget> roleWidgets = [];

    // Önemli rolleri başa al
    final roleOrder = [
      'wolf',
      'doctor',
      'seer',
      'matchmaker',
      'bomber',
      'thief',
      'jester',
      'villager'
    ];

    for (var roleId in roleOrder) {
      if (roleGroups.containsKey(roleId)) {
        var players = roleGroups[roleId]!;
        roleWidgets.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${_playerRoles[players.first]?.name}: ${players.join(", ")}',
              style: TextStyle(
                color: _roleColors[roleId],
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: roleWidgets,
    );
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
          if (_playerRoles[_currentActor]?.id == 'bomber' &&
              _bomberTargets.isNotEmpty)
            IconButton(
              icon: Icon(Icons.flash_on),
              onPressed: _detonateBombs,
            ),
          if (_playerRoles[_currentActor]?.id == 'seer' &&
              _seerDiscoveries.isNotEmpty)
            IconButton(
              icon: Icon(Icons.history),
              onPressed: () =>
                  setState(() => _showSeerHistory = !_showSeerHistory),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isNight && _currentActor != null && !_showRoles)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_playerRoles[_currentActor]?.id == 'wolf')
                    Text(
                      'Kurtlar sırası: ${_wolfPlayers.join(", ")}',
                      style: TextStyle(fontSize: 24),
                    )
                  else
                    Text(
                      'Sıradaki: $_currentActor (${_playerRoles[_currentActor]?.name})',
                      style: TextStyle(fontSize: 24),
                    ),
                ],
              ),
            ),
          if (_showRoles)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: _buildPlayerList(),
            ),
          if (_showSeerHistory && _seerDiscoveries.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: _seerDiscoveries.entries
                    .map(
                      (entry) => Text(
                        '${entry.key}: ${entry.value}',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (_isNight && _currentActor != null)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Sıradaki: $_currentActor (${_playerRoles[_currentActor]?.name})',
                    style: TextStyle(fontSize: 24),
                  ),
                  if (_selectedPlayer != null &&
                      _playerRoles[_currentActor]?.id == 'seer')
                    Text(
                      'Seçilen: $_selectedPlayer (${_playerRoles[_selectedPlayer]?.name})',
                      style: TextStyle(fontSize: 20, color: Colors.blue),
                    ),
                ],
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
                Color playerColor;

                if (_deadPlayers.contains(player)) {
                  playerColor = Colors.red;
                } else if (_isVoting && player == _selectedForVote) {
                  playerColor = Colors.brown;
                } else if (_showRoles) {
                  playerColor =
                      _roleColors[_playerRoles[player]?.id] ?? Colors.grey;
                } else if (player == _currentTarget) {
                  // Hedef seçilmişse kahverengi yap
                  playerColor = Colors.brown;
                } else {
                  playerColor = Colors.grey;
                }
                return GestureDetector(
                  onTap: () => _handlePlayerTap(player),
                  child: Container(
                    decoration: BoxDecoration(
                      color: playerColor,
                      borderRadius: BorderRadius.circular(16.0),
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
                  if (!_isVoting) ...[
                    ElevatedButton(
                      onPressed: _toggleTimer,
                      child: Text(
                          _isTimerActive ? 'Sayacı Durdur' : 'Sayaç Başlat'),
                    ),
                    ElevatedButton(
                      onPressed: _startVoting,
                      child: Text('Oylama Başlat'),
                    ),
                    ElevatedButton(
                      onPressed: _startNight,
                      child: Text('Geceye Git'),
                    ),
                  ] else
                    ElevatedButton(
                      onPressed: _endVoting,
                      child: Text('Oylamayı Bitir'),
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
