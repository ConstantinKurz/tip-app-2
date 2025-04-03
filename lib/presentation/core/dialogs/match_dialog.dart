import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/form/matchesform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/forms/update_match_form.dart';

import '../forms/create_match_form.dart';

class MatchDialog extends StatelessWidget {
  final List<Team> teams;
  final String dialogText;
  final bool isUpdate;
  final CustomMatch? match;

  const MatchDialog({
    Key? key,
    required this.teams,
    required this.dialogText,
    this.isUpdate = false,
    this.match,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<MatchesformBloc>(),
      child: AlertDialog(
        title: Text(dialogText),
        content: SizedBox(
          width: 400,
          child: FractionallySizedBox(
            heightFactor: 0.50,
            child: Builder(
              builder: (context) {
                if (isUpdate) {
                  // Zeige das Update-Formular an
                  return UpdateMatchForm(teams: teams, match: match!); // Übergib das Match
                } else {
                  // Zeige das Create-Formular an
                  return CreateMatchForm(teams: teams);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}