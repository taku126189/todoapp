import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

//? Question 1
// ! ここで export を書いておくと、自動生成したファイル側で import しなくても
// Timestamp を利用できる
//* By convention, implementation code is stored under lib/src and they are private. You do not have to import  src/.. to other packages. To make APIs under lib/src public, use the export keyword. (e.g.,, export 'src/cascade.dart' show Cascade;)
export 'package:cloud_firestore/cloud_firestore.dart';

//* implements keyword: Every class has an implicit interface that contains all instance members of the class. If you want to create Class A that supports Class B without inheriting B's implementation, Class A should implement Class B's interface.
//* The DateTimeTimestampConverter class implements JsonConverter, which is provided by json annotation package. This class converts DataTime to Timestamp, which is provided by cloud firestore package
class DateTimeTimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const DateTimeTimestampConverter();

  @override
  DateTime fromJson(Timestamp json) {
    //* toDate converts TimeStamp to DateTime.
    return json.toDate();
  }

  @override
  Timestamp toJson(DateTime object) {
    //* fromDate converts JSON to Timestamp.
    return Timestamp.fromDate(object);
  }
}
