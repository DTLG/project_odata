class PriceType {
  PriceType({
    required this.id,
    required this.description,
  });
  final String id;
  final String description;
  static final empty = PriceType(id: '', description: '');

  factory PriceType.fromJson(Map<String, dynamic> json) {
    return PriceType(
      id: json['Ref_Key'] as String? ?? '',
      description: json['Description'] as String? ?? '',
    );
  }

  static List<PriceType> fromJsonList(List<dynamic> json) {
    return json.map((e) => PriceType.fromJson(e)).toList();
  }
}
