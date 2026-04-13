class PhotoModel {
  final String id;
  final String? tripId;
  final String url;
  final String? caption;
  final String? dayId;

  PhotoModel({
    required this.id,
    this.tripId,
    required this.url,
    this.caption,
    this.dayId,
  });

  PhotoModel copyWith({String? url, String? caption, String? dayId}) =>
      PhotoModel(
        id: id,
        tripId: tripId,
        url: url ?? this.url,
        caption: caption ?? this.caption,
        dayId: dayId ?? this.dayId,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tripId': tripId,
    'url': url,
    'caption': caption,
    'dayId': dayId,
  };

  factory PhotoModel.fromJson(Map<String, dynamic> json) => PhotoModel(
    id: json['id'] ?? DateTime.now().toString(),
    tripId: json['tripId'],
    url: json['url'] ?? '',
    caption: json['caption'],
    dayId: json['dayId'],
  );
}
