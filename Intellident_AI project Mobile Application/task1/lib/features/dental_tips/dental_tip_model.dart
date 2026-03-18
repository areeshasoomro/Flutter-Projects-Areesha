class DentalTip {
  final int id;
  final String title;
  final String shortDescription;
  final String detail;

  DentalTip({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.detail,
  });

  factory DentalTip.fromJson(Map<String, dynamic> json) {
    return DentalTip(
      id: json['id'],
      title: json['title'],
      shortDescription: json['shortDescription'],
      detail: json['detail'],
    );
  }
}
