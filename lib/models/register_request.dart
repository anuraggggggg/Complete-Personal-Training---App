class RegisterRequest {
  String? username;
  String? firstName;
  String? lastName;
  String? email;
  String? password;
  String? passwordConfirmation;
  String? playerId; // FIXED
  UserProfile? userProfile;

  RegisterRequest({
    this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.password,
    this.passwordConfirmation,
    this.playerId,
    this.userProfile,
  });

  RegisterRequest.fromJson(Map<String, dynamic> json) {
    username = json['username']?.toString();
    firstName = json['first_name']?.toString();
    lastName = json['last_name']?.toString();
    email = json['email']?.toString();
    password = json['password']?.toString();
    passwordConfirmation = json['password_confirmation']?.toString();
    playerId = json['player_id']?.toString(); // FIXED
    userProfile = json['user_profile'] != null
        ? UserProfile.fromJson(json['user_profile'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['username'] = username;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['email'] = email;
    data['password'] = password;
    data['password_confirmation'] = passwordConfirmation;
    data['player_id'] = playerId;
    if (userProfile != null) {
      data['user_profile'] = userProfile!.toJson();
    }
    return data;
  }
}

class UserProfile {
  String? age;
  String? weight;
  String? weightUnit;
  String? height;
  String? heightUnit;
  int? goal;
  int? workoutMode;
  int? workoutLevel;
  String? workoutDaysNo;
  String? workoutDays;
  int? workoutTime;
  int? hasInjury;
  String? injuryInfo;
  String? equipmentIds;

  UserProfile({
    this.age,
    this.weight,
    this.weightUnit,
    this.height,
    this.heightUnit,
    this.goal,
    this.workoutMode,
    this.workoutLevel,
    this.workoutDaysNo,
    this.workoutDays,
    this.workoutTime,
    this.hasInjury,
    this.injuryInfo,
    this.equipmentIds,
  });

  UserProfile.fromJson(Map<String, dynamic> json) {
    age = json['age']?.toString(); // FIX
    weight = json['weight']?.toString(); // FIX
    weightUnit = json['weight_unit']?.toString();
    height = json['height']?.toString(); // FIX
    heightUnit = json['height_unit']?.toString();

    goal = json['goal'];
    workoutMode = json['workout_mode'];
    workoutLevel = json['workout_level'];

    workoutDaysNo = json['workout_days_no']?.toString();
    workoutDays = json['workout_days']?.toString();

    workoutTime = json['workout_time'];
    hasInjury = json['has_injury'];

    injuryInfo = json['injury_info']?.toString(); // FIX
    equipmentIds = json['equipment_ids']?.toString(); // FIX
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['age'] = age;
    data['weight'] = weight;
    data['weight_unit'] = weightUnit;
    data['height'] = height;
    data['height_unit'] = heightUnit;
    data['goal'] = goal;
    data['workout_mode'] = workoutMode;
    data['workout_level'] = workoutLevel;
    data['workout_days_no'] = workoutDaysNo;
    data['workout_days'] = workoutDays;
    data['workout_time'] = workoutTime;
    data['has_injury'] = hasInjury;
    data['injury_info'] = injuryInfo;
    data['equipment_ids'] = equipmentIds;
    return data;
  }
}
