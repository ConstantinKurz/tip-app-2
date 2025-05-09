import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/teams/form/teamsform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/forms/create_team.dart';

enum TeamAction { create, update, delete }

class TeamDialog extends StatelessWidget {
  final String dialogText;
  final TeamAction teamAction;

  const TeamDialog({
    Key? key,
    required this.dialogText,
    required this.teamAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider<TeamsformBloc>(
      create: (context) => sl<TeamsformBloc>(),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(dialogText,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              SizedBox(
                width: screenWidth * 0.3,
                height: screenHeight * 0.6,
                child: Builder(
                  builder: (context) {
                    switch (teamAction) {
                      default:
                        return const CreateTeamForm();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
