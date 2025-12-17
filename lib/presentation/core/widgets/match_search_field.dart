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

  void _filterMatches() {
    final filteredMatches = widget.matches.where((match) {
      if (_searchQuery.isEmpty) return true;
      
      final homeTeam = widget.teams.firstWhere(
        (t) => t.id == match.homeTeamId,
        orElse: () => Team.empty(),
      );
      final guestTeam = widget.teams.firstWhere(
        (t) => t.id == match.guestTeamId,
        orElse: () => Team.empty(),
      );
      
      final searchLower = _searchQuery.toLowerCase();
      final stageName = match.getStageName(match.matchDay).toLowerCase();
      
      // Suche nach Teamnamen (auch Teilwörtern), Spieltag oder Spielphase
      return homeTeam.name.toLowerCase().contains(searchLower) ||
             guestTeam.name.toLowerCase().contains(searchLower) ||
             stageName.contains(searchLower) ||
             '${homeTeam.name} vs ${guestTeam.name}'.toLowerCase().contains(searchLower) ||
             '${homeTeam.name} gegen ${guestTeam.name}'.toLowerCase().contains(searchLower);
    }).toList();
    
    widget.onFilteredMatchesChanged(filteredMatches);
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
                '• Spieltage (z.B. "Halbfinale", "Finale")',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                '• Spielpaarungen (z.B. "Deutschland vs Frankreich")',
                style: TextStyle(color: Colors.white70),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: widget.hintText ?? "Nach Teams, Spielphase oder Matchtag suchen...",
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
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
          });
          _filterMatches();
        },
            ),
          ),
        ),
      ),
    );
  }
}