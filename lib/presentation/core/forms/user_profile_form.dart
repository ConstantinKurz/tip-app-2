import 'package:flag/Flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/form/authform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';

class UserProfileForm extends StatefulWidget {
  final AppUser user;
  final List<Team> teams;

  const UserProfileForm({
    Key? key,
    required this.user,
    required this.teams,
  }) : super(key: key);

  @override
  State<UserProfileForm> createState() => _UserProfileFormState();
}

class _UserProfileFormState extends State<UserProfileForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController currentPasswordController;
  late final TextEditingController newPasswordController;
  late final TextEditingController confirmPasswordController;
  
  bool _showPasswordFields = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.name);
    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Bitte geben Sie einen Namen ein";
    }
    if (value.trim().length < 2) {
      return "Name muss mindestens 2 Zeichen lang sein";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (!_showPasswordFields) return null;
    if (value == null || value.isEmpty) {
      return "Bitte geben Sie ein Passwort ein";
    }
    if (value.length < 6) {
      return "Passwort muss mindestens 6 Zeichen lang sein";
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_showPasswordFields) return null;
    if (value != newPasswordController.text) {
      return "Passwörter stimmen nicht überein";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider<AuthformBloc>(
      create: (context) => sl<AuthformBloc>(),
      child: BlocConsumer<AuthformBloc, AuthformState>(
        listener: (context, state) {
          if (state.authFailureOrSuccessOption != null) {
            state.authFailureOrSuccessOption!.fold(
              () {},
              (result) => result.fold(
                (failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(
                        _getFailureMessage(failure),
                        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  );
                },
                (_) {
                  final message = _showPasswordFields 
                      ? "Profil und Passwort erfolgreich aktualisiert!"
                      : "Profil erfolgreich aktualisiert!";
                      
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(
                        message,
                        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  );
                  
                  if (_showPasswordFields) {
                    setState(() {
                      _showPasswordFields = false;
                      currentPasswordController.clear();
                      newPasswordController.clear();
                      confirmPasswordController.clear();
                    });
                  }
                },
              ),
            );
          }
        },
        builder: (context, state) {
          return Form(
            key: formKey,
            autovalidateMode: state.showValidationMessages
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Field
                Text(
                  'Name',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  validator: _validateName,
                  decoration: InputDecoration(
                    hintText: "Dein Name",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.person, color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                  onChanged: (value) => context
                      .read<AuthformBloc>()
                      .add(UserFormFieldUpdatedEvent(username: value)),
                ),
                const SizedBox(height: 16),
                
                // Champion Selection
                Text(
                  'Champion',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                
                DropdownButtonFormField<String>(
                  value: widget.teams.any((t) => t.id == (state.championId ?? widget.user.championId))
                      ? (state.championId ?? widget.user.championId)
                      : null,
                  decoration: InputDecoration(
                    hintText: "Champion wählen",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.grey.shade800,
                  elevation: 16,
                  items: widget.teams.map((team) {
                    return DropdownMenuItem<String>(
                      value: team.id,
                      child: Row(
                        children: [
                          ClipOval(
                            child: Flag.fromString(
                              team.flagCode,
                              height: 20,
                              width: 20,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            team.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? selectedChampionId) {
                    context.read<AuthformBloc>().add(
                      UserFormFieldUpdatedEvent(championId: selectedChampionId),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Password Change Section
                InkWell(
                  onTap: () {
                    setState(() {
                      _showPasswordFields = !_showPasswordFields;
                      if (!_showPasswordFields) {
                        currentPasswordController.clear();
                        newPasswordController.clear();
                        confirmPasswordController.clear();
                        _showCurrentPassword = false;
                        _showNewPassword = false;
                        _showConfirmPassword = false;
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Row(
                      children: [
                        Text(
                          'Passwort ändern',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        AnimatedRotation(
                          turns: _showPasswordFields ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (_showPasswordFields) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: currentPasswordController,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    obscureText: !_showCurrentPassword,
                    validator: _validatePassword,
                    decoration: InputDecoration(
                      labelText: "Aktuelles Passwort",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showCurrentPassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _showCurrentPassword = !_showCurrentPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: newPasswordController,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    obscureText: !_showNewPassword,
                    validator: _validatePassword,
                    decoration: InputDecoration(
                      labelText: "Neues Passwort",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showNewPassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _showNewPassword = !_showNewPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: confirmPasswordController,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    obscureText: !_showConfirmPassword,
                    validator: _validateConfirmPassword,
                    decoration: InputDecoration(
                      labelText: "Passwort bestätigen",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _showConfirmPassword = !_showConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomButton(
                      buttonText: state.isSubmitting ? 'Speichert...' : 'Speichern',
                      backgroundColor: theme.colorScheme.primary,
                      borderColor: primaryDark,
                      hoverColor: primaryDark,
                      callback: state.isSubmitting
                          ? () {}
                          : () {
                              if (formKey.currentState!.validate()) {
                                final updatedUser = widget.user.copyWith(
                                  name: state.name ?? nameController.text,
                                  championId: state.championId ?? widget.user.championId,
                                );
                                
                                context.read<AuthformBloc>().add(
                                  UpdateUserWithPasswordEvent(
                                    user: updatedUser,
                                    currentUser: widget.user,
                                    currentPassword: _showPasswordFields && currentPasswordController.text.isNotEmpty 
                                        ? currentPasswordController.text 
                                        : null,
                                    newPassword: _showPasswordFields && newPasswordController.text.isNotEmpty 
                                        ? newPasswordController.text 
                                        : null,
                                  ),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Hilfsmethode für bessere Fehlermeldungen
  String _getFailureMessage(AuthFailure failure) {
    if (failure is InvalidCredential) {
      return failure.message;
    } else if (failure is InvalidEmailAndPasswordCombinationFailure) {
      return "Das aktuelle Passwort ist falsch";
    } else {
      return "Fehler beim Aktualisieren des Profils";
    }
  }
}