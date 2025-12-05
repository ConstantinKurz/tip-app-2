import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/form/authform_bloc.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/dialogs/custom_dialog.dart';
import 'package:flutter_web/presentation/core/forms/admin_create_user_form.dart';
import 'package:flutter_web/presentation/core/forms/update_user_form.dart';

enum UserAction { create, update, delete }

class UserDialog extends StatelessWidget {
  final List<Team>? teams;
  final String dialogText;
  final UserAction userAction;
  final AppUser? user;

  const UserDialog({
    Key? key,
    this.teams,
    required this.dialogText,
    required this.userAction,
    this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider<AuthformBloc>(
      create: (context) => sl<AuthformBloc>(),
      child: CustomDialog(
        dialogText: dialogText,
        width: screenWidth * 0.3,
        height: screenHeight * 0.6,
        borderColor: Colors.white,
        content: Builder(
          builder: (context) {
            switch (userAction) {
              case UserAction.update:
                return UpdateUserForm(teams: teams!, user: user!);
              case UserAction.create:
                return const CreateUserForm();
              case UserAction.delete:
                return const Center(
                  child: Text(
                    "Delete action not implemented yet.",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              default:
                return const CreateUserForm();
            }
          },
        ),
      ),
    );
  }
}
