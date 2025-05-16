import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/id.dart';
import 'package:meta/meta.dart';

import '../../../domain/entities/tip.dart';

part 'tipform_event.dart';
part 'tipform_state.dart';

class TipFormBloc extends Bloc<TipFormEvent, TipFormState> {
  TipFormBloc() : super(TipFormState.initial()) {
    on<InitializeTipFormPage>((event, emit) {
      if (event.tip != null) {
        emit(state.copyWith(tip: event.tip, isEditing: true));
      } else {
        emit(state);
      }
    });

    on<TipChangedEvent>((event, emit) {

      emit(state.copyWith(isSaving: true, failureOrSuccessOption: none()));

      if (event.tip?.tipGuest != null && event.tip?.tipHome != null) {
        final Tip editedTip = state.tip.copyWith(tipHome: event.tip?.tipHome ,tipGuest: event.tip?.tipGuest);
        print("Saving!!!!!");
        print(editedTip);
      }
      //TODO: implement this!

      // if (state.isEditing) {
      //     failureOrSuccess = await todoRepository.update(editedTodo);
      //   } else {
      //     failureOrSuccess = await todoRepository.create(editedTodo);
      //   }
      // failureOrSuccess is null from beginning and in this case none is emitted since option of null is none
      // showErrorMessage is only necessary for validator
      //   emit(state.copyWith(
      //       isSaving: false,
      //       showErrorMessages: true,
      //       failureOrSuccessOption: optionOf(failureOrSuccess)));
      // });
    });

    // on<JokerChangedEvent>((event, emit)) {
    //   emit("test")
    // };
  }
}
