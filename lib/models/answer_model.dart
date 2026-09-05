import 'dart:typed_data';

class PickedImage {
  final String name;
  final Uint8List? bytes;
  final String? url; // Support for existing images from API

  PickedImage({required this.name, this.bytes, this.url});
}

class QuestionAnswer {
  String? textValue;
  String? selectedOptionValue;
  DateTime? dateValue;
  String? remark;
  List<PickedImage> images;

  QuestionAnswer({
    this.textValue,
    this.selectedOptionValue,
    this.dateValue,
    this.remark,
    List<PickedImage>? images,
  }) : images = images ?? [];
}
