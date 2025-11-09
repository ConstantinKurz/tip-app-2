import 'package:flutter/material.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/presentation/tip_page/widgets/modern_tip_card.dart';

class TipList extends StatefulWidget {
  final String userId;
  final List<Tip> tips;
  final List<Team> teams;
  final List<CustomMatch> matches;
  final bool showSearchBar;

  const TipList({
    Key? key,
    required this.userId,
    required this.tips,
    required this.teams,
    required this.matches,
    this.showSearchBar = false,
  }) : super(key: key);

  @override
  State<TipList> createState() => _TipListState();
}

class _TipListState extends State<TipList> {
  final TextEditingController _searchController = TextEditingController();
  List<CustomMatch> _filteredMatches = [];

  @override
  void initState() {
    super.initState();
    _filteredMatches = widget.matches;
    if (widget.showSearchBar) {
      _searchController.addListener(_filterMatches);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMatches() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredMatches = widget.matches;
      });
      return;
    }

    setState(() {
      _filteredMatches = widget.matches.where((match) {
        final homeTeam = widget.teams.firstWhere((team) => team.id == match.homeTeamId);
        final guestTeam = widget.teams.firstWhere((team) => team.id == match.guestTeamId);
        
        return homeTeam.name.toLowerCase().contains(query) ||
               guestTeam.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double contentWidth = screenWidth > 600 ? screenWidth * 0.6 : screenWidth * 0.95;

    return Center(
      child: SizedBox(
        width: contentWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar (wenn aktiviert)
            if (widget.showSearchBar) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSearchBar(),
              ),
            ],
            
            // Anzahl der Matches
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                '${_filteredMatches.length} Spiele',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),

            // Match Liste
            ..._filteredMatches.asMap().entries.map((entry) {
              final index = entry.key;
              final match = entry.value;
              final homeTeam = widget.teams.firstWhere((team) => team.id == match.homeTeamId);
              final guestTeam = widget.teams.firstWhere((team) => team.id == match.guestTeamId);
              final tip = widget.tips.firstWhere(
                (t) => t.matchId == match.id,
                orElse: () => Tip.empty(widget.userId),
              );

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  16.0, 
                  index == 0 ? 8.0 : 4.0, 
                  16.0, 
                  index == _filteredMatches.length - 1 ? 24.0 : 4.0
                ),
                child:TipCard(
                  userId: widget.userId,
                  match: match,
                  homeTeam: homeTeam,
                  guestTeam: guestTeam,
                  tip: tip,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Teams suchen...',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
      ),
    );
  }
}
