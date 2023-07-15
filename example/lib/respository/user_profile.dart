/// userId : 1234
/// userName : "daohp"
/// fullName : "Hầu Phi Dao"
/// sex : "male"
/// dob : 1991

class UserProfile {
  UserProfile({
    this.userId,
    this.userName,
    this.fullName,
    this.sex,
    this.dob,
  });

  UserProfile.fromJson(dynamic json) {
    userId = json['userId'];
    userName = json['userName'];
    fullName = json['fullName'];
    sex = json['sex'];
    dob = json['dob'];
  }
  int? userId;
  String? userName;
  String? fullName;
  String? sex;
  int? dob;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['userId'] = userId;
    map['userName'] = userName;
    map['fullName'] = fullName;
    map['sex'] = sex;
    map['dob'] = dob;
    return map;
  }
}
