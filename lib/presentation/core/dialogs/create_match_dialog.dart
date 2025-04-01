import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/form/matchesform_bloc.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/injections.dart';

import '../forms/create_match_form.dart';

class CreateMatchDialog extends StatelessWidget {
  final List<Team> teams;

  const CreateMatchDialog({Key? key, required this.teams}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => sl<MatchesformBloc>(),
        child: AlertDialog(
          title: const Text('Neues Match'),
          content: SizedBox(
            width: 400,
            child: FractionallySizedBox(
              heightFactor: 0.50,
              child: Builder(
                builder: (context) {
                  return  CreateMatchForm(teams: teams);}
                    ),
                  )
              ),
            ),
          );
  }
}
