// =======================
// CIRCUITE EXERCISE RESPONSE
// =======================
class CircuiteExercise {
  final bool? success;
  final String? message;
  final List<Workout>? workouts;

  CircuiteExercise({
    this.success,
    this.message,
    this.workouts,
  });

  factory CircuiteExercise.fromJson(Map<String, dynamic> json) {
    return CircuiteExercise(
      success: json['success'],
      message: json['message'],
      workouts: (json['workouts'] as List<dynamic>?)
          ?.map((e) => Workout.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'workouts': workouts?.map((e) => e.toJson()).toList(),
      };
}

// =======================
// WORKOUT MODEL
// =======================
class Workout {
  final int? workoutId;
  final String? workoutName;
  final String? workoutType;
  final String? warmupVideo;
  final List<Exercise>? exercises;

  Workout({
    this.workoutId,
    this.workoutName,
    this.workoutType,
    this.warmupVideo,
    this.exercises,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      workoutId: json['workout_id'],
      workoutName: json['workout_name'],
      workoutType: json['workout_type'],
      warmupVideo: json['warmup_video'],
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((e) => Exercise.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'workout_id': workoutId,
        'workout_name': workoutName,
        'workout_type': workoutType,
        'warmup_video': warmupVideo,
        'exercises': exercises?.map((e) => e.toJson()).toList(),
      };
}

// =======================
// EXERCISE MODEL
// =======================
class Exercise {
  final int? id;
  final String? title;

  /// 🔹 NEW API FIELD
  final String? description;

  /// 🔹 VIDEO (NEW API)
  final String? selectedVideoUrl;

  /// 🔹 IMAGE / GIF
  final String? thumbnailUrl;

  Exercise({
    this.id,
    this.title,
    this.description,
    this.selectedVideoUrl,
    this.thumbnailUrl,
  });

  // ===================== BACKWARD COMPATIBILITY =====================

  /// ✅ OLD UI expects `instruction`
  String? get instruction => description;

  /// ✅ OLD UI expects `exerciseGifUrl`
  String? get exerciseGifUrl => thumbnailUrl;

  /// ✅ OLD UI expects `exerciseVideos`
  /// We fake it using selectedVideoUrl
  List<_FakeExerciseVideo>? get exerciseVideos {
    if (selectedVideoUrl == null || selectedVideoUrl!.isEmpty) {
      return null;
    }
    return [_FakeExerciseVideo(videoUrl: selectedVideoUrl!)];
  }

  // ===================== JSON =====================

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      selectedVideoUrl: json['selected_video_url'],
      thumbnailUrl: json['thumbnail_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'selected_video_url': selectedVideoUrl,
        'thumbnail_url': thumbnailUrl,
      };
}

/// 🔹 INTERNAL helper class (ONLY for UI compatibility)
class _FakeExerciseVideo {
  final String? videoUrl;
  _FakeExerciseVideo({this.videoUrl});
}
