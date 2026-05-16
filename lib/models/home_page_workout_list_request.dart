// =======================================================
// HOME PAGE WORKOUT MODEL
// UPDATED + NULL SAFE + BACKWARD COMPATIBLE
// =======================================================

class HomePage {
  bool? success;
  int? userId;
  String? userName;
  String? todayIs;
  int? currentWeek;
  int? currentCycle;
  int? workoutDaysPlan;
  int? completedDaysThisWeek;
  int? selectedLanguageId;
  int? trialRemainingDays;
  List<WorkoutsForToday> workoutsForToday;

  HomePage({
    this.success,
    this.userId,
    this.userName,
    this.todayIs,
    this.currentWeek,
    this.currentCycle,
    this.workoutDaysPlan,
    this.completedDaysThisWeek,
    this.selectedLanguageId,
    this.trialRemainingDays,
    List<WorkoutsForToday>? workoutsForToday,
  }) : workoutsForToday = workoutsForToday ?? [];

  HomePage.fromJson(Map<String, dynamic> json)
      : success = json['success'],
        userId = json['user_id'],
        userName = json['user_name'],
        todayIs = json['today_is'],
        currentWeek = json['current_week'],
        currentCycle = json['current_cycle'],
        workoutDaysPlan = json['workout_days_plan'],
        completedDaysThisWeek = json['completed_days_this_week'],
        selectedLanguageId = json['selected_language_id'],
        trialRemainingDays = json['trial_remaining_days'],
        workoutsForToday = (json['workouts_for_today'] as List?)
                ?.map((e) => WorkoutsForToday.fromJson(e))
                .toList() ??
            [];

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'user_id': userId,
      'user_name': userName,
      'today_is': todayIs,
      'current_week': currentWeek,
      'current_cycle': currentCycle,
      'workout_days_plan': workoutDaysPlan,
      'completed_days_this_week': completedDaysThisWeek,
      'selected_language_id': selectedLanguageId,
      'trial_remaining_days': trialRemainingDays,
      'workouts_for_today': workoutsForToday.map((v) => v.toJson()).toList(),
    };
  }
}

// =======================================================
// WORKOUTS FOR TODAY
// =======================================================

class WorkoutsForToday {
  int? workoutId;
  String? workoutName;
  String? dayName;
  String? workoutWeek;
  String? workoutDayNumber;
  String? warmupVideo;
  String? stretchVideo;
  List<Exercises> exercises;

  WorkoutsForToday({
    this.workoutId,
    this.workoutName,
    this.dayName,
    this.workoutWeek,
    this.workoutDayNumber,
    this.warmupVideo,
    this.stretchVideo,
    List<Exercises>? exercises,
  }) : exercises = exercises ?? [];

  WorkoutsForToday.fromJson(Map<String, dynamic> json)
      : workoutId = json['workout_id'],
        workoutName = json['workout_name'],
        dayName = json['day_name'],
        workoutWeek = json['workout_week'],
        workoutDayNumber = json['workout_day_number'],
        warmupVideo = json['warmup_video'],
        stretchVideo = json['stretch_video'],
        exercises = (json['exercises'] as List?)
                ?.map((e) => Exercises.fromJson(e))
                .toList() ??
            [];

  Map<String, dynamic> toJson() {
    return {
      'workout_id': workoutId,
      'workout_name': workoutName,
      'day_name': dayName,
      'workout_week': workoutWeek,
      'workout_day_number': workoutDayNumber,
      'warmup_video': warmupVideo,
      'stretch_video': stretchVideo,
      'exercises': exercises.map((v) => v.toJson()).toList(),
    };
  }

  /// ✅ ADD THIS (TYPO SUPPORT)
  String? get stetchVideo => stretchVideo;
}

// =======================================================
// EXERCISES
// =======================================================

class Exercises {
  int? id;
  String? title;
  String? exerciseTitle;
  String? instruction;
  String? exerciseImage;
  String? exerciseGif;
  String? exerciseGifPosterUrl;
  List<ExerciseVideos> exerciseVideos;
  String? selectedVideoUrl;
  AlternateExercise? alternateExercise;

  Exercises({
    this.id,
    this.title,
    this.exerciseTitle,
    this.instruction,
    this.exerciseImage,
    this.exerciseGif,
    this.exerciseGifPosterUrl,
    List<ExerciseVideos>? exerciseVideos,
    this.selectedVideoUrl,
    this.alternateExercise,
  }) : exerciseVideos = exerciseVideos ?? [];

  Exercises.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        exerciseTitle = json['exercise_title'],
        instruction = json['instruction'],
        exerciseImage = json['exercise_image'],
        exerciseGif = json['exercise_gif'],
        exerciseGifPosterUrl = json['exercise_gif_poster_url'],
        exerciseVideos = (json['exercise_videos'] as List?)
                ?.map((e) => ExerciseVideos.fromJson(e))
                .toList() ??
            [],
        selectedVideoUrl = json['selected_video_url'],
        alternateExercise = json['alternate_exercise'] is Map<String, dynamic>
            ? AlternateExercise.fromJson(json['alternate_exercise'])
            : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'exercise_title': exerciseTitle,
      'instruction': instruction,
      'exercise_image': exerciseImage,
      'exercise_gif': exerciseGif,
      'exercise_gif_poster_url': exerciseGifPosterUrl,
      'exercise_videos': exerciseVideos.map((v) => v.toJson()).toList(),
      'selected_video_url': selectedVideoUrl,
      'alternate_exercise': alternateExercise?.toJson(),
    };
  }

  /// 🧼 Instruction cleaner (already used)
  String get cleanInstruction =>
      instruction?.replaceAll(RegExp(r'<[^>]*>'), '') ?? "";

  /// 🎥 Best video resolver
  String get resolvedVideoUrl {
    if (selectedVideoUrl?.isNotEmpty == true) {
      return selectedVideoUrl!;
    }
    for (final v in exerciseVideos) {
      if (v.hlsMasterUrl?.isNotEmpty == true) {
        return v.hlsMasterUrl!;
      }
      if (v.videoUrl?.isNotEmpty == true) {
        return v.videoUrl!;
      }
    }
    return "";
  }

  String _normalizedMediaPath(String? rawUrl) {
    final raw = rawUrl?.trim() ?? "";
    if (raw.isEmpty) return "";

    final uri = Uri.tryParse(raw);
    if (uri != null && uri.path.isNotEmpty) {
      return uri.path.toLowerCase();
    }
    return raw.toLowerCase();
  }

  bool _isAnimatedAsset(String? rawUrl) {
    final path = _normalizedMediaPath(rawUrl);
    return path.endsWith('.gif') ||
        path.endsWith('.mp4') ||
        path.endsWith('.webm') ||
        path.endsWith('.m3u8');
  }

  String get homePreviewUrl {
    if (_isAnimatedAsset(exerciseGif)) {
      return exerciseGif!.trim();
    }

    if (resolvedVideoUrl.isNotEmpty) {
      return resolvedVideoUrl;
    }

    if ((exerciseGif ?? '').trim().isNotEmpty) {
      return exerciseGif!.trim();
    }

    if ((exerciseGifPosterUrl ?? '').trim().isNotEmpty) {
      return exerciseGifPosterUrl!.trim();
    }

    return (exerciseImage ?? '').trim();
  }

  /// 🖼️ 🔥 FIX FOR YOUR CRASH
  String? get exerciseImageUrl =>
      exerciseImage?.isNotEmpty == true
          ? exerciseImage
          : exerciseGif;

  factory Exercises.empty() => Exercises(
        id: 0,
        title: "",
        instruction: "",
        exerciseImage: "",
        exerciseGif: "",
        exerciseVideos: const [],
      );
}

// =======================================================
// EXERCISE VIDEOS
// =======================================================

class ExerciseVideos {
  int? id;
  int? languagelistId;
  int? exerciseId;
  String? videoUrl;
  String? hlsMasterUrl;
  String? posterUrl;

  ExerciseVideos({
    this.id,
    this.languagelistId,
    this.exerciseId,
    this.videoUrl,
    this.hlsMasterUrl,
    this.posterUrl,
  });

  ExerciseVideos.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        languagelistId = json['languagelist_id'],
        exerciseId = json['exercise_id'],
        videoUrl = json['video_url'],
        hlsMasterUrl = json['hls_master_url'],
        posterUrl = json['poster_url'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'languagelist_id': languagelistId,
      'exercise_id': exerciseId,
      'video_url': videoUrl,
      'hls_master_url': hlsMasterUrl,
      'poster_url': posterUrl,
    };
  }
}

// =======================================================
// ALTERNATE EXERCISE
// =======================================================

class AlternateExercise {
  int? id;
  String? title;
  String? description;
  String? exerciseImage;
  String? exerciseGif;
  String? selectedVideoUrl;

  AlternateExercise({
    this.id,
    this.title,
    this.description,
    this.exerciseImage,
    this.exerciseGif,
    this.selectedVideoUrl,
  });

  AlternateExercise.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        description = json['description'],
        exerciseImage = json['exercise_image'],
        exerciseGif = json['exercise_gif'],
        selectedVideoUrl = json['selected_video_url'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'exercise_image': exerciseImage,
      'exercise_gif': exerciseGif,
      'selected_video_url': selectedVideoUrl,
    };
  }

  // ================= FIXES =================

  /// 🔹 OLD SCREEN COMPATIBILITY
  String get cleanInstruction =>
      description?.replaceAll(RegExp(r'<[^>]*>'), '') ?? "";

  /// 🔹 OLD FIELD SUPPORT
  String? get videoUrl => selectedVideoUrl;

  /// 🔹 USED IN OLD YOUTUBE SCREENS (SAFE)
  String get resolvedVideoId {
    final raw = selectedVideoUrl ?? "";
    if (raw.contains("v=")) {
      return raw.split("v=").last.split("&").first;
    }
    if (raw.contains("youtu.be/")) {
      return raw.split("youtu.be/").last;
    }
    return raw;
  }
}

/// ===============================
/// 🔥 ALTERNATE EXERCISE VIDEO RESOLVER
/// ===============================
extension AlternateExerciseResolver on AlternateExercise {

  /// ✅ USE THIS FOR VIDEO_PLAYER (NETWORK / HLS)
  String get resolvedVideoUrl {
    if (selectedVideoUrl?.isNotEmpty == true) {
      return selectedVideoUrl!;
    }
    return "";
  }
}
