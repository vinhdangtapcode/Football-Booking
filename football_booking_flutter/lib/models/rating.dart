import 'field.dart';

class Rating {
  int? id;
  int? customerId;
  int score;
  String? comment;
  Field field;
  String? userName;
  bool? isAnonymous;

  Rating({this.id, this.customerId, required this.score, this.comment, required this.field, this.userName, this.isAnonymous});

  factory Rating.fromJson(Map<String, dynamic> json){
    return Rating(
      id: json['id'],
      customerId: json['customerId'],
      score: json['score'],
      comment: json['comment'],
      field: Field.fromJson(json['field']),
      userName: json['customerName'],
      isAnonymous: json['isAnonymous'],
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'customerId': customerId,
      'score': score,
      'comment': comment,
      'field': field.toJson(),
      'customerName': userName,
      'isAnonymous': isAnonymous,
    };
  }
}
