class BodyMeasurements {
  final double? heightCm;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? inseamCm;
  final double? shoulderCm;

  const BodyMeasurements({
    this.heightCm,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.inseamCm,
    this.shoulderCm,
  });

  bool get hasEnoughDataForPreview =>
      heightCm != null && chestCm != null && waistCm != null && hipsCm != null;

  factory BodyMeasurements.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const BodyMeasurements();
    }

    return BodyMeasurements(
      heightCm: _toDouble(json['heightCm']),
      chestCm: _toDouble(json['chestCm']),
      waistCm: _toDouble(json['waistCm']),
      hipsCm: _toDouble(json['hipsCm']),
      inseamCm: _toDouble(json['inseamCm']),
      shoulderCm: _toDouble(json['shoulderCm']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heightCm': heightCm,
      'chestCm': chestCm,
      'waistCm': waistCm,
      'hipsCm': hipsCm,
      'inseamCm': inseamCm,
      'shoulderCm': shoulderCm,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}
