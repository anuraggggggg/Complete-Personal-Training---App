import 'package:collection/collection.dart';

/// ===============================================================
///               ROOT MODEL
/// ===============================================================

class GetAllExerciseModel {
  bool? hasAccess;
  String? message;
  List<ExerciseItem>? data;

  GetAllExerciseModel({
    this.hasAccess,
    this.message,
    this.data,
  });

  factory GetAllExerciseModel.fromJson(Map<String, dynamic> json) {
    return GetAllExerciseModel(
      hasAccess: json['has_access'] ?? false,
      message: json['message'],
      data: (json['data'] as List?)
          ?.map((e) => ExerciseItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'has_access': hasAccess,
        'message': message,
        if (data != null) 'data': data!.map((e) => e.toJson()).toList(),
      };
}

/// ===============================================================
///               EXERCISE ITEM
/// ===============================================================

class ExerciseItem {
  int? id;

  int? equipmentId;
  String? equipmentTitle;

  /// 🔥 NEW FIELD (ACTUAL API KEY)
  String? exerciseTitle;

  /// OLD UI SUPPORT
  String? title;

  String? selectedVideoUrl;
  String? thumbnailUrl;
  bool isLocked;

  List<ExerciseVideo> exerciseVideos;

  ExerciseItem({
    this.id,
    this.equipmentId,
    this.equipmentTitle,
    this.exerciseTitle,
    this.title,
    this.selectedVideoUrl,
    this.thumbnailUrl,
    this.isLocked = false,
    List<ExerciseVideo>? exerciseVideos,
  }) : exerciseVideos = exerciseVideos ?? [];

  factory ExerciseItem.fromJson(Map<String, dynamic> json) {
    return ExerciseItem(
      id: json['id'],
      equipmentId: json['equipment_id'],
      equipmentTitle: json['equipment_title'],

      /// 🔥 DIRECT API KEY MAP
      exerciseTitle: json['exercise_title'],

      /// 🔥 UI SAFE (OLD CODE WILL NOT BREAK)
      title: json['exercise_title'],

      selectedVideoUrl: json['video_url'],
      thumbnailUrl: json['thumbnail_url'],
      isLocked: json['is_locked'] ?? false,

      exerciseVideos: [
        ExerciseVideo.fromJson(json),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'equipment_id': equipmentId,
        'equipment_title': equipmentTitle,
        'exercise_title': exerciseTitle,   // 🔥 Added
        'video_url': selectedVideoUrl,
        'thumbnail_url': thumbnailUrl,
        'is_locked': isLocked,
      };

  String get finalVideoUrl {
    if (selectedVideoUrl != null && selectedVideoUrl!.isNotEmpty) {
      return selectedVideoUrl!;
    }

    if (exerciseVideos.isNotEmpty) {
      return exerciseVideos.first.videoUrl ?? "";
    }

    return "";
  }

  bool get hasVideo => finalVideoUrl.isNotEmpty;
}

/// ===============================================================
///               EXERCISE VIDEO
/// ===============================================================

class ExerciseVideo {
  int? id;
  int? languageId;
  String? languageName;
  String? videoUrl;

  ExerciseVideo({
    this.id,
    this.languageId,
    this.languageName,
    this.videoUrl,
  });

  factory ExerciseVideo.fromJson(Map<String, dynamic> json) {
    return ExerciseVideo(
      id: json['id'],
      languageId: json['language_id'],
      languageName: json['language_name'],
      videoUrl: json['video_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'language_id': languageId,
        'language_name': languageName,
        'video_url': videoUrl,
      };
}

/// ===============================================================
///               EXTENSION – LANGUAGE SELECTOR
/// ===============================================================

extension ExerciseItemVideoSelector on ExerciseItem {
  String getVideoByLanguage(int languageId) {
    final matched = exerciseVideos.firstWhereOrNull(
      (v) => v.languageId == languageId && (v.videoUrl ?? "").isNotEmpty,
    );

    if (matched != null) return matched.videoUrl!;

    if (selectedVideoUrl != null && selectedVideoUrl!.isNotEmpty) {
      return selectedVideoUrl!;
    }

    if (exerciseVideos.isNotEmpty) {
      return exerciseVideos.first.videoUrl ?? "";
    }

    return "";
  }
}
