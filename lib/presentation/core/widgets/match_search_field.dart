import 'package:flutter/material.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';

class MatchSearchField extends StatefulWidget {
  final List<CustomMatch> matches;
  final List<Team> teams;
  final Function(List<CustomMatch>) onFilteredMatchesChanged;
  final String? hintText;
  final bool showHelpDialog;

  const MatchSearchField({
    Key? key,
    required this.matches,
    required this.teams,
    required this.onFilteredMatchesChanged,
    this.hintText,
    this.showHelpDialog = true,
  }) : super(key: key);

  @override
  State<MatchSearchField> createState() => _MatchSearchFieldState();
}

class _MatchSearchFieldState extends State<MatchSearchField> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _activeFilter; // Aktiver Filter-Chip
  bool _isExpanded = false; // Suche eingeklappt/ausgeklappt
  bool _isButtonHovered = false; // Hover-Status des Filter-Buttons

  // Aliase für Suchbegriffe
  static const Map<String, List<String>> _searchAliases = {
    'gruppenphase': ['gruppe', 'vorrunde', 'group'],
    'sechszehntelfinale': ['16tel', 'runde der 32', 'round of 32'],
    'achtelfinale': ['8tel', 'achtel', 'runde der 16', 'round of 16'],
    'viertelfinale': ['4tel', 'viertel', 'quarter'],
    'halbfinale': ['halb', 'semi', 'semifinale'],
    'finale': ['endspiel', 'final', 'end'],
    'spiel um platz 3': ['platz 3', 'dritter platz', 'third place', 'bronze'],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initial call with all matches - defer until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onFilteredMatchesChanged(widget.matches);
    });
  }

  /// Expandiert den Suchbegriff mit Aliase
  String _expandSearchTerm(String search) {
    final searchLower = search.toLowerCase().trim();
    
    // Prüfe ob der Suchbegriff ein Alias ist
    for (final entry in _searchAliases.entries) {
      if (entry.value.any((alias) => alias == searchLower)) {
        return entry.key;
      }
    }
    return searchLower;
  }

  /// Prüft ob ein Suchbegriff als ganzes Wort im Text vorkommt
  bool _containsWholeWord(String text, String searchTerm) {
    final pattern = RegExp(r'\b' + RegExp.escape(searchTerm) + r'\b', caseSensitive: false);
    return pattern.hasMatch(text);
  }

  /// Berechnet den Relevanz-Score für ein Match
  int _calculateRelevanceScore(CustomMatch match, String searchTerm, Team homeTeam, Team guestTeam) {
    final stageName = match.getStageNameInContext(widget.matches).toLowerCase();
    final homeTeamName = homeTeam.name.toLowerCase();
    final guestTeamName = guestTeam.name.toLowerCase();
    final matchDayStr = 'spieltag ${match.matchDay}';
    
    // Expandiere Suchbegriff mit Aliase
    final expandedSearch = _expandSearchTerm(searchTerm);
    
    // Höchste Priorität: Exakte Übereinstimmung mit Spielphase
    if (stageName == expandedSearch) {
      return 1000;
    }
    
    // Exakte Übereinstimmung mit Teamnamen
    if (homeTeamName == expandedSearch || guestTeamName == expandedSearch) {
      return 950;
    }
    
    // Spieltag-Nummer Match (z.B. "spieltag 1", "tag 1", "md1")
    if (matchDayStr.contains(expandedSearch) || 
        'tag ${match.matchDay}' == expandedSearch ||
        'md${match.matchDay}' == expandedSearch) {
      return 900;
    }
    
    // Spielphase beginnt mit Suchbegriff
    if (stageName.startsWith(expandedSearch)) {
      return 850;
    }
    
    // Teamname beginnt mit Suchbegriff
    if (homeTeamName.startsWith(expandedSearch) || guestTeamName.startsWith(expandedSearch)) {
      return 800;
    }
    
    // Spielphase enthält Suchbegriff als ganzes Wort (wichtig für "finale" vs "viertelfinale")
    if (_containsWholeWord(stageName, expandedSearch)) {
      return 700;
    }
    
    // Teamname enthält Suchbegriff als ganzes Wort
    if (_containsWholeWord(homeTeamName, expandedSearch) || _containsWholeWord(guestTeamName, expandedSearch)) {
      return 650;
    }
    
    // Spielpaarung enthält Suchbegriff
    final fullMatch = '$homeTeamName vs $guestTeamName';
    if (fullMatch.contains(expandedSearch)) {
      return 500;
    }
    
    // Teamname enthält Suchbegriff als Teilstring
    if (homeTeamName.contains(expandedSearch) || guestTeamName.contains(expandedSearch)) {
      return 200;
    }
    
    // NICHT: Spielphase als Teilstring - das würde "finale" in "viertelfinale" finden
    // Das lassen wir bewusst weg, um präzisere Ergebnisse zu haben
    
    return 0;
  }

  void _filterMatches() {
    if (_searchQuery.isEmpty && _activeFilter == null) {
      widget.onFilteredMatchesChanged(widget.matches);
      return;
    }

    final searchTerm = _activeFilter ?? _searchQuery.toLowerCase().trim();
    
    // Berechne Relevanz-Score für jedes Match
    final matchesWithScore = widget.matches.map((match) {
      final homeTeam = widget.teams.firstWhere(
        (t) => t.id == match.homeTeamId,
        orElse: () => Team.empty(),
      );
      final guestTeam = widget.teams.firstWhere(
        (t) => t.id == match.guestTeamId,
        orElse: () => Team.empty(),
      );
      
      final score = _calculateRelevanceScore(match, searchTerm, homeTeam, guestTeam);
      
      return {'match': match, 'score': score};
    }).where((item) => (item['score'] as int) > 0).toList();
    
    // Sortiere nach Score (höher = relevanter), dann nach Datum
    matchesWithScore.sort((a, b) {
      final scoreCompare = (b['score'] as int).compareTo(a['score'] as int);
      if (scoreCompare != 0) return scoreCompare;
      return (a['match'] as CustomMatch).matchDate.compareTo((b['match'] as CustomMatch).matchDate);
    });
    
    final filteredMatches = matchesWithScore.map((item) => item['match'] as CustomMatch).toList();
    widget.onFilteredMatchesChanged(filteredMatches);
  }

  void _onFilterChipSelected(String? filter) {
    setState(() {
      if (_activeFilter == filter) {
        _activeFilter = null; // Toggle off
      } else {
        _activeFilter = filter;
      }
      _searchController.clear();
      _searchQuery = '';
    });
    _filterMatches();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text(
            'Suchhinweise',
            style: TextStyle(color: Colors.white),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Du kannst suchen nach:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                '• Teamnamen (z.B. "Deutschland", "Frankreich")',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                '• Spielphasen (exakt: "Finale" findet nur das Finale)',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                '• Spielpaarungen (z.B. "Deutschland vs Frankreich")',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                '• Spieltag-Nummer (z.B. "Spieltag 1", "MD1")',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 12),
              Text(
                '💡 Tipp: Nutze die Filter-Chips für schnellen Zugriff!',
                style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Verstanden',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Button rechts ausrichten mit Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _isExpanded
                        ? MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onEnter: (_) => setState(() => _isButtonHovered = true),
                            onExit: (_) => setState(() => _isButtonHovered = false),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isExpanded = !_isExpanded;
                                  if (!_isExpanded) {
                                    // Reset bei Einklappen
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _activeFilter = null;
                                    _filterMatches();
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: _isButtonHovered ? Colors.white : Colors.transparent,
                                  border: Border.all(color: _isButtonHovered ? Colors.black : Colors.white),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: _isButtonHovered ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Tooltip(
                            message: _activeFilter != null 
                                ? 'Filter: ${_getFilterDisplayName(_activeFilter!)}'
                                : _searchQuery.isNotEmpty
                                    ? 'Suche: $_searchQuery'
                                    : 'Spiele filtern',
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              onEnter: (_) => setState(() => _isButtonHovered = true),
                              onExit: (_) => setState(() => _isButtonHovered = false),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isExpanded = !_isExpanded;
                                    if (!_isExpanded) {
                                      // Reset bei Einklappen
                                      _searchController.clear();
                                      _searchQuery = '';
                                      _activeFilter = null;
                                      _filterMatches();
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: _isButtonHovered ? Colors.white : Colors.transparent,
                                    border: Border.all(color: _isButtonHovered ? Colors.black : Colors.white),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.filter_list,
                                    color: _isButtonHovered ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
                // Einklappbarer Suchbereich
                ClipRect(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    heightFactor: _isExpanded ? 1.0 : 0.0,
                    child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                        // Suchfeld
                        TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: widget.hintText ?? "Nach Teams, Spielphase oder Matchtag suchen...",
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: const Icon(Icons.search, color: Colors.white),
                            suffixIcon: (_searchQuery.isNotEmpty || _activeFilter != null)
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.white),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                        _activeFilter = null;
                                      });
                                      _filterMatches();
                                    },
                                  )
                                : widget.showHelpDialog
                                    ? IconButton(
                                        icon: const Icon(Icons.help_outline, color: Colors.white70),
                                        onPressed: _showHelpDialog,
                                      )
                                    : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white, width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _activeFilter = null; // Deaktiviere Filter bei Texteingabe
                            });
                            _filterMatches();
                          },
                        ),
                        const SizedBox(height: 12),
                        // Filter-Chips - Responsive: Dropdown on mobile, chips on desktop
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 500;
                            
                            if (isMobile) {
                              // Mobile: Compact dropdown button
                              return _buildMobileFilterDropdown(themeData);
                            }
                            
                            // Desktop: Horizontal scrolling chips
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip('Gruppe', 'gruppenphase', themeData),
                                  const SizedBox(width: 7),
                                  _buildFilterChip('16tel', 'sechszehntelfinale', themeData),
                                  const SizedBox(width: 7),
                                  _buildFilterChip('8tel', 'achtelfinale', themeData),
                                  const SizedBox(width: 7),
                                  _buildFilterChip('4tel', 'viertelfinale', themeData),
                                  const SizedBox(width: 7),
                                  _buildFilterChip('1/2', 'halbfinale', themeData),
                                  const SizedBox(width: 7),
                                  _buildFilterChip('Platz 3', 'spiel um platz 3', themeData),
                                  const SizedBox(width: 7),
                                  _buildFilterChip('Finale', 'finale', themeData),
                                ],
                              ),
                            );
                          },
                        ),
                            ],
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'gruppenphase':
        return 'Gruppe';
      case 'sechszehntelfinale':
        return '16tel';
      case 'achtelfinale':
        return '8tel';
      case 'viertelfinale':
        return '4tel';
      case 'halbfinale':
        return 'Halb';
      case 'spiel um platz 3':
        return 'Platz 3';
      case 'finale':
        return 'Finale';
      default:
        return filter;
    }
  }

  /// Mobile: Compact dropdown for filter selection
  Widget _buildMobileFilterDropdown(ThemeData themeData) {
    final filters = [
      ('Alle Spiele', null),
      ('Gruppenphase', 'gruppenphase'),
      ('16tel Finale', 'sechszehntelfinale'),
      ('Achtelfinale', 'achtelfinale'),
      ('Viertelfinale', 'viertelfinale'),
      ('Halbfinale', 'halbfinale'),
      ('Platz 3', 'spiel um platz 3'),
      ('Finale', 'finale'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: themeData.colorScheme.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _activeFilter != null ? Colors.white : Colors.white.withOpacity(0.5),
          width: _activeFilter != null ? 2 : 1,
        ),
      ),
      child: PopupMenuButton<String?>(
        initialValue: _activeFilter,
        onSelected: (filter) {
          _onFilterChipSelected(filter);
        },
        offset: const Offset(0, 40),
        color: Colors.black,
        surfaceTintColor: Colors.transparent,
        splashRadius: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white24),
        ),
        itemBuilder: (context) => filters.map((filter) {
          final isSelected = _activeFilter == filter.$2;
          return PopupMenuItem<String?>(
            value: filter.$2,
            child: Row(
              children: [
                if (isSelected) 
                  const Icon(Icons.check, color: Colors.white, size: 18)
                else 
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Text(
                  filter.$1,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_list,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _activeFilter == null ? 'Alle' : _getFilterDisplayName(_activeFilter!),
              style: TextStyle(
                color: Colors.white,
                fontWeight: _activeFilter != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter, ThemeData themeData) {
    final isSelected = _activeFilter == filter;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? themeData.colorScheme.primary : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => _onFilterChipSelected(filter),
      backgroundColor: themeData.colorScheme.primary.withOpacity(0.3),
      selectedColor: Colors.white,
      checkmarkColor: themeData.colorScheme.primary,
      side: BorderSide(
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
      ),
    );
  }
}