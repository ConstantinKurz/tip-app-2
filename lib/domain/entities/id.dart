import 'package:uuid/uuid.dart';

//TODO: Delete!
class UniqueID {
  const UniqueID._(this.value);

  final String value;

  factory UniqueID() {
    return UniqueID._(const Uuid().v1());
  }

  factory UniqueID.fromUniqueString(String uniqueID){
    return UniqueID._(uniqueID);
  }
}