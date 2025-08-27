import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'ranking_event.dart';
part 'ranking_state.dart';

class RankingBloc extends Bloc<RankingEvent, RankingState> {
  RankingBloc() : super(const RankingState(expanded: false)) {
    on<ToggleRankingViewEvent>(_onToggleRankingView);
  }

  void _onToggleRankingView(
    ToggleRankingViewEvent event,
    Emitter<RankingState> emit,
  ) {
    emit(state.copyWith(expanded: !state.expanded));
  }
}
