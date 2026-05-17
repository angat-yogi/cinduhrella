enum TryOnJobStatus { queued, rendering, completed, failed }

class TryOnJob {
  final String tryOnJobId;
  final String uid;
  final String bodyProfileId;
  final String topGarmentId;
  final String bottomGarmentId;
  final String outputView;
  final TryOnJobStatus status;
  final String? resultImageUrl;
  final String summary;
  final String renderPrompt;
  final DateTime createdAt;

  const TryOnJob({
    required this.tryOnJobId,
    required this.uid,
    required this.bodyProfileId,
    required this.topGarmentId,
    required this.bottomGarmentId,
    required this.outputView,
    required this.status,
    required this.summary,
    required this.renderPrompt,
    required this.createdAt,
    this.resultImageUrl,
  });

  factory TryOnJob.fromJson(Map<String, dynamic> json) {
    return TryOnJob(
      tryOnJobId: json['tryOnJobId'] ?? '',
      uid: json['uid'] ?? '',
      bodyProfileId: json['bodyProfileId'] ?? '',
      topGarmentId: json['topGarmentId'] ?? '',
      bottomGarmentId: json['bottomGarmentId'] ?? '',
      outputView: json['outputView'] ?? 'front',
      status: TryOnJobStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => TryOnJobStatus.queued,
      ),
      resultImageUrl: json['resultImageUrl'],
      summary: json['summary'] ?? '',
      renderPrompt: json['renderPrompt'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tryOnJobId': tryOnJobId,
      'uid': uid,
      'bodyProfileId': bodyProfileId,
      'topGarmentId': topGarmentId,
      'bottomGarmentId': bottomGarmentId,
      'outputView': outputView,
      'status': status.name,
      'resultImageUrl': resultImageUrl,
      'summary': summary,
      'renderPrompt': renderPrompt,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
