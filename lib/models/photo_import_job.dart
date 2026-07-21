enum PhotoImportJobStatus { queued, processing, completed, failed, cancelled }

enum PhotoImportJobMode {
  ownerLibrarySelection,
  ownerLibraryAutoScan,
  bulkWardrobeSelection,
  manualCapture,
}

class PhotoImportJob {
  final String jobId;
  final String userId;
  final PhotoImportJobStatus status;
  final PhotoImportJobMode mode;
  final int totalImages;
  final int processedImages;
  final int createdDrafts;
  final String title;
  final String? sessionId;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PhotoImportJob({
    required this.jobId,
    required this.userId,
    required this.status,
    required this.mode,
    required this.totalImages,
    required this.processedImages,
    required this.createdDrafts,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.sessionId,
    this.errorMessage,
  });

  factory PhotoImportJob.fromJson(Map<String, dynamic> json) {
    return PhotoImportJob(
      jobId: json['jobId'] ?? '',
      userId: json['userId'] ?? '',
      status: PhotoImportJobStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => PhotoImportJobStatus.queued,
      ),
      mode: PhotoImportJobMode.values.firstWhere(
        (value) => value.name == json['mode'],
        orElse: () => PhotoImportJobMode.ownerLibrarySelection,
      ),
      totalImages: json['totalImages'] ?? 0,
      processedImages: json['processedImages'] ?? 0,
      createdDrafts: json['createdDrafts'] ?? 0,
      title: json['title'] ?? 'Photo Import',
      sessionId: json['sessionId'],
      errorMessage: json['errorMessage'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'userId': userId,
      'status': status.name,
      'mode': mode.name,
      'totalImages': totalImages,
      'processedImages': processedImages,
      'createdDrafts': createdDrafts,
      'title': title,
      'sessionId': sessionId,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PhotoImportJob copyWith({
    PhotoImportJobStatus? status,
    int? totalImages,
    int? processedImages,
    int? createdDrafts,
    String? title,
    String? sessionId,
    String? errorMessage,
    DateTime? updatedAt,
  }) {
    return PhotoImportJob(
      jobId: jobId,
      userId: userId,
      status: status ?? this.status,
      mode: mode,
      totalImages: totalImages ?? this.totalImages,
      processedImages: processedImages ?? this.processedImages,
      createdDrafts: createdDrafts ?? this.createdDrafts,
      title: title ?? this.title,
      sessionId: sessionId ?? this.sessionId,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
