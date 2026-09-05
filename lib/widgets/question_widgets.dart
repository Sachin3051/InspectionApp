import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';
import '../models/answer_model.dart';
import '../models/form_model.dart';
import '../providers/form_provider.dart';
import '../services/api_service.dart';

// ---------------- Field (Textbox / Textarea / Dropdown / Date) ----------------

class FieldQuestion extends StatefulWidget {
  final FormQuestion question;
  final FormProvider provider;

  const FieldQuestion({super.key, required this.question, required this.provider});

  @override
  State<FieldQuestion> createState() => _FieldQuestionState();
}

class _FieldQuestionState extends State<FieldQuestion> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final answer = widget.provider.answerFor(widget.question.questionId);
    final initialText = answer.textValue ?? '';
    _controller = TextEditingController(text: initialText);
  }

  @override
  void didUpdateWidget(covariant FieldQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    final answer = widget.provider.answerFor(widget.question.questionId);
    final newText = answer.textValue ?? '';

    if (_controller.text != newText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.text = newText;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.provider.errors[widget.question.questionId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(text: widget.question.questionText, required: widget.question.isRequired),
        const SizedBox(height: 6),
        _buildControl(context, error),
      ],
    );
  }

  Widget _buildControl(BuildContext context, String? error) {
    final isReadOnly = widget.provider.isReadOnly;
    final answer = widget.provider.answerFor(widget.question.questionId);

    switch (widget.question.controlType) {
      case 'Dropdown':
        final selectedValue = answer.selectedOptionValue;
        final hasOption = widget.question.options.any((o) => o.optionValue == selectedValue);
        final validValue = hasOption ? selectedValue : null;

        return DropdownButtonFormField<String>(
          value: validValue,
          isExpanded: true,
          decoration: InputDecoration(errorText: error, isDense: true),
          items: widget.question.options
              .map((o) => DropdownMenuItem(
            value: o.optionValue,
            child: Text(o.optionText, overflow: TextOverflow.ellipsis),
          ))
              .toList(),
          onChanged: isReadOnly
              ? null
              : (v) {
            if (v != null) widget.provider.setRadio(widget.question.questionId, v);
          },
        );

      case 'Date':
        final date = answer.dateValue;
        return InkWell(
          onTap: isReadOnly
              ? null
              : () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) widget.provider.setDate(widget.question.questionId, picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              errorText: error,
              isDense: true,
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              date == null ? 'Select date' : '${date.day}/${date.month}/${date.year}',
              style: TextStyle(
                color: date == null ? AppColors.textSecondary : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        );

      case 'Textarea':
        return TextFormField(
          controller: _controller,
          maxLines: 3,
          readOnly: isReadOnly,
          decoration: InputDecoration(errorText: error, isDense: true, hintText: 'Enter details'),
          onChanged: (v) {
            widget.provider.setText(widget.question.questionId, v);
          },
        );

      default: // Textbox
        return TextFormField(
          controller: _controller,
          readOnly: isReadOnly,
          decoration: InputDecoration(errorText: error, isDense: true, hintText: 'Enter value'),
          onChanged: (v) {
            widget.provider.setText(widget.question.questionId, v);
          },
        );
    }
  }
}

class _Label extends StatelessWidget {
  final String text;
  final bool required;
  const _Label({required this.text, required this.required});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        children: [
          TextSpan(text: text),
          if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.danger)),
        ],
      ),
    );
  }
}

// ---------------- Radio Question Row ----------------

class RadioQuestionRow extends StatelessWidget {
  final FormQuestion question;
  final FormProvider provider;
  const RadioQuestionRow({super.key, required this.question, required this.provider});

  @override
  Widget build(BuildContext context) {
    final answer = provider.answerFor(question.questionId);
    final selected = answer.selectedOptionValue;

    final showExtra = provider.isRemarkAndUploadVisible(selected);

    final error = provider.errors[question.questionId];
    final remarkError = provider.errors['${question.questionId}_remark'];
    final imageError = provider.errors['${question.questionId}_image'];

    final label = Text(
      question.questionText,
      style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
    );

    final optionsRow = Wrap(
      spacing: 16,
      runSpacing: 8,
      children: question.options.map((o) {
        return InkWell(
          onTap: provider.isReadOnly ? null : () => provider.setRadio(question.questionId, o.optionValue),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: o.optionValue,
                groupValue: selected,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: provider.isReadOnly
                    ? null
                    : (v) {
                  if (v != null) provider.setRadio(question.questionId, v);
                },
              ),
              Text(o.optionText, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            ],
          ),
        );
      }).toList(),
    );

    final extra = !showExtra
        ? const SizedBox.shrink()
        : Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Responsive.isMobile(context)
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RemarkField(
              key: ValueKey('remark_${question.questionId}_${answer.remark}'),
              question: question,
              provider: provider,
              error: remarkError),
          const SizedBox(height: 8),
          _UploadButton(question: question, provider: provider, error: imageError),
        ],
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: _RemarkField(
                  key: ValueKey('remark_${question.questionId}_${answer.remark}'),
                  question: question,
                  provider: provider,
                  error: remarkError)),
          const SizedBox(width: 12),
          _UploadButton(question: question, provider: provider, error: imageError),
        ],
      ),
    );

    if (Responsive.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const SizedBox(height: 8),
          optionsRow,
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(error, style: const TextStyle(color: AppColors.danger, fontSize: 11)),
            ),
          extra,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: Padding(padding: const EdgeInsets.only(top: 10), child: label)),
            Expanded(flex: 6, child: optionsRow),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(error, style: const TextStyle(color: AppColors.danger, fontSize: 11)),
          ),
        extra,
      ],
    );
  }
}

class _RemarkField extends StatefulWidget {
  final FormQuestion question;
  final FormProvider provider;
  final String? error;

  const _RemarkField({super.key, required this.question, required this.provider, required this.error});

  @override
  State<_RemarkField> createState() => _RemarkFieldState();
}

class _RemarkFieldState extends State<_RemarkField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final remark = widget.provider.answerFor(widget.question.questionId).remark;
    _controller = TextEditingController(text: remark ?? '');
  }

  @override
  void didUpdateWidget(covariant _RemarkField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final remark = widget.provider.answerFor(widget.question.questionId).remark;
    final newText = remark ?? '';

    if (_controller.text != newText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.text = newText;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: widget.provider.isReadOnly,
      decoration: InputDecoration(hintText: 'Remarks', isDense: true, errorText: widget.error),
      onChanged: (v) => widget.provider.setRemark(widget.question.questionId, v),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final FormQuestion question;
  final FormProvider provider;
  final String? error;
  const _UploadButton({required this.question, required this.provider, required this.error});

  @override
  Widget build(BuildContext context) {
    final images = provider.answerFor(question.questionId).images;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!provider.isReadOnly)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () => pickImage(context, question.questionId, provider),
                icon: const Icon(Icons.upload_outlined, size: 16),
                label: const Text('Choose Files'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12.5),
                ),
              ),
              if (images.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('${images.length} file(s)',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ],
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 11)),
          ),
        if (images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ImageThumbRow(
              images: images,
              isReadOnly: provider.isReadOnly,
              onRemove: (img) => provider.removeImage(question.questionId, img),
            ),
          ),
      ],
    );
  }
}

// ---------------- Standalone ImageUpload question ----------------

class ImageUploadQuestionRow extends StatelessWidget {
  final FormQuestion question;
  final FormProvider provider;
  const ImageUploadQuestionRow({super.key, required this.question, required this.provider});

  @override
  Widget build(BuildContext context) {
    final images = provider.answerFor(question.questionId).images;
    final error = provider.errors[question.questionId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                question.questionText,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
            ),
            if (!provider.isReadOnly)
              OutlinedButton.icon(
                onPressed: () => pickImage(context, question.questionId, provider),
                icon: const Icon(Icons.upload_outlined, size: 16),
                label: const Text('Choose Files'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12.5),
                ),
              ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(error, style: const TextStyle(color: AppColors.danger, fontSize: 11)),
          ),
        if (images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ImageThumbRow(
              images: images,
              isReadOnly: provider.isReadOnly,
              onRemove: (img) => provider.removeImage(question.questionId, img),
            ),
          ),
      ],
    );
  }
}

// ---------------- Shared: image thumbnails ----------------

class ImageThumbRow extends StatelessWidget {
  final List<PickedImage> images;
  final bool isReadOnly;
  final void Function(PickedImage) onRemove;

  const ImageThumbRow({
    super.key,
    required this.images,
    required this.onRemove,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: images.map((img) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () {
                _showImagePreview(context, img);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: img.url != null && img.url!.isNotEmpty
                    ? _SafeNetworkImage(
                  url: ApiService.resolveImageUrl(img.url!),
                  width: 64,
                  height: 64,
                )
                    : (img.bytes != null
                    ? Image.memory(
                  img.bytes!,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                )
                    : const SizedBox(
                  width: 64,
                  height: 64,
                )),
              ),
            ),
            if (!isReadOnly)
              Positioned(
                top: -6,
                right: -6,
                child: InkWell(
                  onTap: () => onRemove(img),
                  child: const CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.danger,
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}

void _showImagePreview(BuildContext context, PickedImage image) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: image.url != null && image.url!.isNotEmpty
                      ? Image.network(
                    ApiService.resolveImageUrl(image.url!),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(30),
                        color: Colors.white,
                        child: const Icon(
                          Icons.broken_image,
                          size: 60,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                      : image.bytes != null
                      ? Image.memory(
                    image.bytes!,
                    fit: BoxFit.contain,
                  )
                      : const SizedBox(),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SafeNetworkImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;

  const _SafeNetworkImage({
    required this.url,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(
            Icons.broken_image,
            size: 32,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}

// ---------------- Multi-File Selection Handler ----------------

Future<void> pickImage(BuildContext context, String questionId, FormProvider provider) async {
  final isMobile = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  if (isMobile) {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickSingleCameraImage(questionId, provider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Gallery (Multi-select)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickMultiGalleryImages(questionId, provider);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  } else {
    // 🟡 FilePicker for Web / Desktop with allowMultiple: true (Shift/Ctrl Multi-select)
    // Desktop / Web File Explorer Picker
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, // 👈 'FileType.image' ki jagah 'custom' use karein
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'], // 👈 Allowed extensions explicitly dein
      allowMultiple: true, // 👈 Multi-select enable karta hai
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final List<PickedImage> selectedImages = [];
      for (var f in result.files) {
        if (f.bytes != null) {
          selectedImages.add(PickedImage(name: f.name, bytes: f.bytes!));
        }
      }
      if (selectedImages.isNotEmpty) {
        provider.addImages(questionId, selectedImages);
      }
    }
  }
}

// Mobile Camera
Future<void> _pickSingleCameraImage(String questionId, FormProvider provider) async {
  final picker = ImagePicker();
  final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
  if (file != null) {
    final bytes = await file.readAsBytes();
    provider.addImages(questionId, [PickedImage(name: file.name, bytes: bytes)]);
  }
}

// Mobile Gallery Multiple Selection
Future<void> _pickMultiGalleryImages(String questionId, FormProvider provider) async {
  final picker = ImagePicker();
  final List<XFile> pickedFiles = await picker.pickMultiImage(imageQuality: 80);

  if (pickedFiles.isNotEmpty) {
    final List<PickedImage> selectedImages = [];
    for (var file in pickedFiles) {
      final bytes = await file.readAsBytes();
      selectedImages.add(PickedImage(name: file.name, bytes: bytes));
    }
    provider.addImages(questionId, selectedImages);
  }
}