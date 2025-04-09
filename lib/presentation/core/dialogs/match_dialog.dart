import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/form/matchesform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/dialogs/match_delete_dialog.dart';
import 'package:flutter_web/presentation/core/forms/update_match_form.dart';

import '../forms/create_match_form.dart';

enum MatchAction { create, update, delete }
class MatchDialog extends StatelessWidget {
  final List<Team>? teams;
  final String dialogText;
  final MatchAction matchAction;
  final CustomMatch? match;

  const MatchDialog({
    Key? key,
    this.teams,
    required this.dialogText,
    required this.matchAction,
    this.match,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider<MatchesformBloc>(
      create: (context) => sl<MatchesformBloc>(),
      child: AlertDialog(
        title: Text(dialogText),
        content: SizedBox(
          width: screenWidth * 0.3,
          height: screenHeight * 0.5,
          child: Builder(
            builder: (context) {
              switch (matchAction) {
                case MatchAction.update:
                  return UpdateMatchForm(teams: teams!, match: match!);
                case MatchAction.delete:
                  return DeleteMatchDialog(match: match!);
                case MatchAction.create:
                  return CreateMatchForm(teams: teams!);
                default:
                  return CreateMatchForm(teams: teams!);
              }
            },
          ),
        ),
      ),
    );
  }
}
