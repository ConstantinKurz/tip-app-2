import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';

class TipCardMatchInfo extends StatelessWidget {
  final CustomMatch match;
  final Team homeTeam;
  final Team guestTeam;
  final bool hasResult;

  const TipCardMatchInfo({
    Key? key,
    required this.match,
    required this.homeTeam,
    required this.guestTeam,
    required this.hasResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
      buildWhen: (previous, current) {
        if (previous.runtimeType != current.runtimeType) return true;

        if (previous is MatchesControllerLoaded &&
            current is MatchesControllerLoaded) {
          final prevMatch = previous.matches.firstWhere(
            (m) => m.id == match.id,
            orElse: () => match,
          );
          final currMatch = current.matches.firstWhere(
            (m) => m.id == match.id,
            orElse: () => match,
          );

          return prevMatch.homeScore != currMatch.homeScore ||
              prevMatch.guestScore != currMatch.guestScore;
        }

        return true;
      },
      builder: (context, matchState) {
        CustomMatch currentMatch = match;
        if (matchState is MatchesControllerLoaded) {
          currentMatch = matchState.matches.firstWhere(
            (m) => m.id == match.id,
            orElse: () => match,
          );
        }

        final currentHasResult =
            currentMatch.homeScore != null && currentMatch.guestScore != null;

        return Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ClipOval(
                    child: Flag.fromString(
                      homeTeam.flagCode,
                      height: 32,
                      width: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      homeTeam.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 80,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: currentHasResult
                    ? Text(
                        '${currentMatch.homeScore} : ${currentMatch.guestScore}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : Text(
                        'vs',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      guestTeam.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipOval(
                    child: Flag.fromString(
                      guestTeam.flagCode,
                      height: 32,
                      width: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}