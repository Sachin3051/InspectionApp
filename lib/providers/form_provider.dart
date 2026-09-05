import 'package:flutter/foundation.dart';
import '../models/form_model.dart';
import '../models/answer_model.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FormProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool isRemarkAndUploadVisible(String? selectedOption) {
    if (selectedOption == null) return false;
    final value = selectedOption.trim().toUpperCase();
    if (value == 'NA' || value == 'NOT APPLICABLE') {
      return false;
    }
    return true;
  }

  InspectionForm? _form;
  bool _isLoading = false;
  bool _isReadOnly = false;
  final Map<String, QuestionAnswer> _answers = {};
  final Map<String, String?> _errors = {};

  InspectionForm? get form => _form;
  bool get isLoading => _isLoading;
  bool get isReadOnly => _isReadOnly;
  Map<String, String?> get errors => _errors;

  QuestionAnswer answerFor(String questionId) {
    return _answers.putIfAbsent(questionId, () => QuestionAnswer());
  }

  Future<void> loadForm({String? entryId, bool readOnly = false}) async {
    _isLoading = true;
    _isReadOnly = readOnly;
    notifyListeners();



    try {
      _form = await _apiService.getInspectionForm();
      _answers.clear();
      _errors.clear();

      if (entryId != null) {
        final entryData = await _apiService.getInspectionEntry(entryId);
        _bindEntryData(entryData);
      } else {
        _setDefaultAcceptedValuesInternal();
      }
    } catch (e) {
      print('Error in loadForm: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _bindEntryData(Map<String, dynamic> data) {
    if (_form == null) return;

    final List<dynamic> entrySections = data['sections'] ?? [];
    final Map<String, dynamic> savedQuestionsById = {};

    for (var sec in entrySections) {
      final List<dynamic> qs = sec['questions'] ?? [];
      for (var q in qs) {
        final qId = q['questionId']?.toString() ?? '';
        final qNum = qId.replaceAll(RegExp(r'[^0-9]'), '');
        if (qNum.isNotEmpty) {
          savedQuestionsById[qNum] = q;
        }
      }
    }

    for (var section in _form!.sections) {
      for (var q in section.questions) {
        final qNum = q.questionId.replaceAll(RegExp(r'[^0-9]'), '');
        final savedQ = savedQuestionsById[qNum];
        if (savedQ == null) continue;

        final text = savedQ['savedAnswerText']?.toString();
        final selectedOptionIds = savedQ['selectedOptionIds'] as List<dynamic>?;
        final files = savedQ['savedFiles'] as List<dynamic>?;

        final hasText = text != null && text.isNotEmpty;
        final hasOptions = selectedOptionIds != null && selectedOptionIds.isNotEmpty;
        final hasFiles = files != null && files.isNotEmpty;
        if (!hasText && !hasOptions && !hasFiles) continue;

        final ans = answerFor(q.questionId);

        if (q.controlType == 'Date') {
          ans.dateValue = hasText ? DateTime.tryParse(text!) : null;
        } else if (q.controlType == 'Radio' || q.controlType == 'Checkbox') {
          if (hasOptions) {
            final selectedOptId = selectedOptionIds!.first.toString().replaceAll(RegExp(r'[^0-9]'), '');
            for (var opt in q.options) {
              final optIdClean = opt.optionId.replaceAll(RegExp(r'[^0-9]'), '');
              if (optIdClean == selectedOptId || opt.optionValue == selectedOptId) {
                ans.selectedOptionValue = opt.optionValue;
                break;
              }
            }
          }
          ans.remark = text;
        } else if (q.controlType == 'Dropdown') {
          String? selectedValue;

          // 1. First preference: selectedOptionIds se option find karo
          if (hasOptions) {
            final selectedOptId = selectedOptionIds!
                .first
                .toString()
                .replaceAll(RegExp(r'[^0-9]'), '');

            for (var opt in q.options) {
              final optIdClean = opt.optionId
                  .toString()
                  .replaceAll(RegExp(r'[^0-9]'), '');

              if (optIdClean == selectedOptId) {
                selectedValue = opt.optionValue;
                break;
              }
            }
          }

          // 2. Agar ID se nahi mila, savedAnswerText se option find karo
          if (selectedValue == null && text != null && text.isNotEmpty) {
            for (var opt in q.options) {
              if (opt.optionText.trim().toLowerCase() ==
                  text.trim().toLowerCase()) {
                selectedValue = opt.optionValue;
                break;
              }

              if (opt.optionValue.trim().toLowerCase() ==
                  text.trim().toLowerCase()) {
                selectedValue = opt.optionValue;
                break;
              }
            }
          }

          // 3. Final value
          ans.selectedOptionValue = selectedValue;
        } else {
          ans.textValue = text;
        }

        if (hasFiles) {
          ans.images = files!.map((f) => PickedImage(
            name: f['fileName'] ?? 'image',
            url: f['filePath'] ?? f['fileUrl'],
          )).toList();
        }
      }
    }
  }

  void setDefaultAcceptedValues() {
    _setDefaultAcceptedValuesInternal();
    notifyListeners();
  }

  void _setDefaultAcceptedValuesInternal() {
    if (_form == null) return;

    for (var section in _form!.sections) {
      for (var q in section.questions) {
        final control = q.controlType.toString().trim();

        if (control == 'Radio' || control == 'Checkbox') {
          final ans = answerFor(q.questionId);

          var targetOpt = q.options.cast<dynamic>().firstWhere(
                (opt) {
              final val = opt.optionValue.toString().trim().toUpperCase();
              return val == 'ACCEPTED' || val == 'ACCEPT';
            },
            orElse: () => null,
          );

          if (targetOpt == null && q.options.isNotEmpty) {
            targetOpt = q.options.first;
          }

          if (targetOpt != null) {
            ans.selectedOptionValue = targetOpt.optionValue;
          }
        }
      }
    }
  }

  void setText(String questionId, String value) {
    if (_isReadOnly) return;
    answerFor(questionId).textValue = value;
    _errors.remove(questionId);
  }

  void setRadio(String questionId, String value) {
    if (_isReadOnly) return;
    answerFor(questionId).selectedOptionValue = value;
    _errors.remove(questionId);
    notifyListeners();
  }

  void setDate(String questionId, DateTime date) {
    if (_isReadOnly) return;
    answerFor(questionId).dateValue = date;
    _errors.remove(questionId);
    notifyListeners();
  }

  void setRemark(String questionId, String value) {
    if (_isReadOnly) return;
    answerFor(questionId).remark = value;
  }

  void addImage(String questionId, PickedImage image) {
    if (_isReadOnly) return;
    answerFor(questionId).images.add(image);
    _errors.remove(questionId);
    notifyListeners();
  }
  void addImages(String questionId, List<PickedImage> newImages) {
    if (_isReadOnly) return;
    answerFor(questionId).images.addAll(newImages);
    _errors.remove(questionId);
    notifyListeners();
  }

  void removeImage(String questionId, PickedImage image) {
    if (_isReadOnly) return;
    answerFor(questionId).images.remove(image);
    notifyListeners();
  }

  bool validateAll() {
    if (_form == null) return false;
    _errors.clear();
    for (final section in _form!.sections) {
      for (final q in section.questions) {
        if (!q.isRequired) continue;
        final ans = _answers[q.questionId];
        switch (q.controlType) {
          case 'Textbox':
          case 'Textarea':
            if (ans == null || (ans.textValue ?? '').trim().isEmpty) {
              _errors[q.questionId] = 'This field is required';
            }
            break;
          case 'Dropdown':
          case 'Radio':
          case 'Checkbox':
            if (ans == null || (ans.selectedOptionValue ?? '').trim().isEmpty) {
              _errors[q.questionId] = 'Please select an option';
            }
            break;
          case 'Date':
            if (ans == null || ans.dateValue == null) {
              _errors[q.questionId] = 'Please select a date';
            }
            break;
          case 'ImageUpload':
            if (ans == null || ans.images.isEmpty) {
              _errors[q.questionId] = 'Please upload an image';
            }
            break;
        }
      }
    }
    notifyListeners();
    return _errors.isEmpty;
  }
  /*bool validateDraft() {
    if (_form == null) return false;
    _errors.clear();

    for (final section in _form!.sections) {
      for (final q in section.questions) {

        // HARDCODE CHECK: Sirf Container No (CONT_NO) par validation chalegi
        final isContainerNoField = q.questionCode.trim().toUpperCase() == 'CONT_NO';

        // Agar Container No field NAHI hai, toh isko sidha skip karo
        if (!isContainerNoField) continue;

        final ans = _answers[q.questionId];

        // Sirf Container No validation
        final text = ans?.textValue?.trim() ?? '';
        if (text.isEmpty) {
          _errors[q.questionId] = 'Container No is required for saving draft';
        }
      }
    }

    notifyListeners();
    return _errors.isEmpty;
  }*/
  bool validateDraft() {
    if (_form == null) return false;

    _errors.clear();

    for (final section in _form!.sections) {
      for (final q in section.questions) {

        print(
            'DRAFT CHECK: ${q.questionText} | '
                'isDraftRequired=${q.isDraftRequired} | '
                'type=${q.controlType} | '
                'text=${_answers[q.questionId]?.textValue} | '
                'selected=${_answers[q.questionId]?.selectedOptionValue}'
        );

        if (!q.isDraftRequired) continue;

        final ans = _answers[q.questionId];

        switch (q.controlType.trim()) {

          case 'Textbox':
          case 'Textarea':
            if (ans == null ||
                (ans.textValue ?? '').trim().isEmpty) {
              _errors[q.questionId] = 'This field is required';
            }
            break;

          case 'Dropdown':
          case 'Radio':
          case 'Checkbox':
            if (ans == null ||
                (ans.selectedOptionValue ?? '').trim().isEmpty) {
              _errors[q.questionId] = 'Please select an option';
            }
            break;

          case 'Date':
            if (ans == null || ans.dateValue == null) {
              _errors[q.questionId] = 'Please select a date';
            }
            break;

          case 'ImageUpload':
            if (ans == null || ans.images.isEmpty) {
              _errors[q.questionId] = 'Please upload an image';
            }
            break;
        }
      }
    }

    notifyListeners();

    return _errors.isEmpty;
  }

  String? getFirstInvalidQuestionId() {
    if (_form == null) return null;
    for (final section in _form!.sections) {
      for (final q in section.questions) {
        if (_errors.containsKey(q.questionId)) {
          return q.questionId;
        }
      }
    }
    return _errors.keys.isNotEmpty ? _errors.keys.first : null;
  }

  Future<void> submitForm({String? entryId, String status = 'Submitted'}) async {
    final List<Map<String, dynamic>> answerPayload = [];
    final List<PickedImage> newImages = [];

    for (var section in _form!.sections) {
      for (var q in section.questions) {
        final ans = _answers[q.questionId];
        if (ans == null) continue;

        String? answerText;
        List<int> selectedOptions = [];

        if (q.controlType == 'Date' && ans.dateValue != null) {
          answerText = ans.dateValue!.toIso8601String().split('T')[0];
        }
        else if (q.controlType == 'Radio' || q.controlType == 'Checkbox' || q.controlType == 'Dropdown') {
          if (ans.selectedOptionValue != null && ans.selectedOptionValue!.isNotEmpty) {
            // Option object find karein
            final opt = q.options.firstWhere(
                  (o) => o.optionValue == ans.selectedOptionValue || o.optionText == ans.selectedOptionValue,
              orElse: () => q.options.isNotEmpty ? q.options.first : FormOption(optionId: '0', optionText: '', optionValue: '', displayOrder: 0),
            );

            final optIdClean = opt.optionId.replaceAll(RegExp(r'[^0-9]'), '');
            final parsedId = int.tryParse(optIdClean) ?? 0;
            if (parsedId > 0) {
              selectedOptions.add(parsedId);
            }

            // Full Text save ho, iske liye OptionText/Value pass karein
            answerText = opt.optionText.isNotEmpty ? opt.optionText : ans.selectedOptionValue;
          }

          // Radio/Checkbox ka extra remark text
          if (q.controlType != 'Dropdown' && ans.remark != null && ans.remark!.isNotEmpty) {
            answerText = ans.remark;
          }
        }
        else {
          answerText = ans.textValue;
        }

        answerPayload.add({
          "questionId": int.tryParse(q.questionId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
          "answerText": answerText,
          "selectedOptions": selectedOptions,
          "files": ans.images.map((img) => {
            "fileName": img.name,
            "filePath": img.url ?? img.name,
          }).toList(),
        });

        for (var img in ans.images) {
          if (img.bytes != null) {
            newImages.add(img);
          }
        }
      }
    }
    final int userId = await _getLoggedInUserId();
    final payload = {
      "entryId": entryId != null ? int.tryParse(entryId.replaceAll(RegExp(r'[^0-9]'), '')) : null,
      "formId": int.tryParse(_form!.formId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
      "status": status,
      "createdBy": userId,
      "answers": answerPayload,
    };

    await _apiService.saveInspection(payload, newImages);
  }

  Future<int> _getLoggedInUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // AuthProvider ne 'userId' key me integer save kiya hai
      final int? userId = prefs.getInt('userId');
      if (userId != null && userId > 0) {
        return userId;
      }
    } catch (e) {
      debugPrint('Error reading userId: $e');
    }
    return 1; // Fallback default
  }
}