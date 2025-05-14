import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/teams/form/teamsform_bloc.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/dialogs/custom_dialog.dart';
import 'package:flutter_web/presentation/core/dialogs/team_delete_dialog.dart';
import 'package:flutter_web/presentation/core/forms/create_team_form.dart';
import 'package:flutter_web/presentation/core/forms/update_team_form.dart';

enum TeamAction { create, update, delete }

class TeamDialog extends StatelessWidget {
  final Team? team;
  final String dialogText;
  final TeamAction teamAction;

  const TeamDialog({
    Key? key,
    this.team,
    required this.dialogText,
    required this.teamAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider<TeamsformBloc>(
      create: (context) => sl<TeamsformBloc>(),
      child: CustomDialog(
        dialogText: dialogText,
        content: Builder(
          builder: (context) {
            switch (teamAction) {
              case TeamAction.update:
                return UpdateTeamForm(team: team!);
              case TeamAction.create:
                return const CreateTeamForm();
              case TeamAction.delete:
                return DeleteTeamDialog(team: team!);
              default:
                return const CreateTeamForm();
            }
          },
        ),
        width: screenWidth * 0.3,
        height: screenHeight * 0.6,
        borderColor: Colors.white,
      ),
    );
  }
}
