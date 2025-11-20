class User {
  final String userId;
  final String userName;
  final String userType;
  final String firstName;
  final String? lastName;
  final String email;
  final String? avatar;
  final String? dob;
  final String? phoneNum;

  User({
    required this.userId,
    required this.userName,
    required this.userType,
    required this.firstName,
    this.lastName,
    required this.email,
    this.avatar,
    this.dob,
    this.phoneNum,
  });

  bool get isAdmin => userType == 'Admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userType: json['userType']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString(),
      email: json['email']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      dob: json['dob']?.toString(),
      phoneNum: json['phoneNum']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userType': userType,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'avatar': avatar,
      'dob': dob,
      'phoneNum': phoneNum,
    };
  }

  User copyWith({
    String? userId,
    String? userName,
    String? userType,
    String? firstName,
    String? lastName,
    String? email,
    String? avatar,
    String? dob,
    String? phoneNum,
  }) {
    return User(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userType: userType ?? this.userType,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      dob: dob ?? this.dob,
      phoneNum: phoneNum ?? this.phoneNum,
    );
  }
}
