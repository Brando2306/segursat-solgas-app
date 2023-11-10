import 'dart:convert';

class DirectionDto {
  int placeId;
  String licence;
  String osmType;
  int osmId;
  String latitude;
  String longitude;
  String direction;
  int placeRank;
  String category;
  String type;
  double importance;
  String icon;

  DirectionDto(
      this.placeId,
      this.licence,
      this.osmType,
      this.osmId,
      this.latitude,
      this.longitude,
      this.direction,
      this.placeRank,
      this.category,
      this.type,
      this.importance,
      this.icon);

  factory DirectionDto.fromJson(json) {
    return DirectionDto(
      json['place_id'] as int? ?? 0,
      json['licence'] as String? ?? '',
      json['osm_type'] as String? ?? '',
      json['osm_id'] as int? ?? 0,
      json['lat'] as String? ?? '',
      json['lon'] as String? ?? '',
      utf8.decode((json['display_name'] as String? ?? '').runes.toList()),
      json['place_rank'] as int? ?? 0,
      json['category'] as String? ?? '',
      json['type'] as String? ?? '',
      json['importance'] as double? ?? 0.0,
      json['icon'] as String? ?? '',
    );
  }
}
