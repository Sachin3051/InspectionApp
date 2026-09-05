class InspectionForm {
  final String formId;
  final String formName;
  final String versionNo;
  final List<FormSection> sections;

  InspectionForm({
    required this.formId,
    required this.formName,
    required this.versionNo,
    required this.sections,
  });

  factory InspectionForm.fromJson(Map<String, dynamic> json) {
    final sectionsList = (json['sections'] as List<dynamic>? ?? [])
        .map((e) => FormSection.fromJson(e as Map<String, dynamic>))
        .toList();
    sectionsList.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return InspectionForm(
      formId: json['formId']?.toString() ?? '',
      formName: json['formName']?.toString() ?? '',
      versionNo: json['versionNo']?.toString() ?? '',
      sections: sectionsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'formId': formId,
      'formName': formName,
      'versionNo': versionNo,
      'sections': sections.map((e) => e.toJson()).toList(),
    };
  }
}

class FormSection {
  final String sectionId;
  final String sectionName;
  final int displayOrder;
  final List<FormQuestion> questions;

  FormSection({
    required this.sectionId,
    required this.sectionName,
    required this.displayOrder,
    required this.questions,
  });

  factory FormSection.fromJson(Map<String, dynamic> json) {
    final questionsList = (json['questions'] as List<dynamic>? ?? [])
        .map((e) => FormQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
    questionsList.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return FormSection(
      sectionId: json['sectionId']?.toString() ?? '',
      sectionName: json['sectionName']?.toString() ?? '',
      displayOrder: int.tryParse(json['displayOrder']?.toString() ?? '0') ?? 0,
      questions: questionsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sectionId': sectionId,
      'sectionName': sectionName,
      'displayOrder': displayOrder,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }
}

class FormQuestion {
  final String questionId;
  final String questionCode;
  final String questionText;
  final String controlType; // Textbox, Textarea, Dropdown, Radio, Date, ImageUpload
  final bool isRequired;
  final bool isDraftRequired; // Naya field add ho gaya hai
  final int displayOrder;
  final String? placeholder;
  final String? helpText;
  final List<FormOption> options;

  FormQuestion({
    required this.questionId,
    required this.questionCode,
    required this.questionText,
    required this.controlType,
    required this.isRequired,
    this.isDraftRequired = false, // Default false set kar diya hai
    required this.displayOrder,
    this.placeholder,
    this.helpText,
    required this.options,
  });

  factory FormQuestion.fromJson(Map<String, dynamic> json) {
    final optionsList = (json['options'] as List<dynamic>? ?? [])
        .map((e) => FormOption.fromJson(e as Map<String, dynamic>))
        .toList();
    optionsList.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    // Dynamic Parsing Function for BIT / Boolean Columns
    bool parseBool(dynamic value) {
      if (value == null) return false;

      if (value is bool) return value;

      if (value is int) {
        return value == 1;
      }

      if (value is double) {
        return value == 1;
      }

      if (value is String) {
        final clean = value.trim().toLowerCase();

        return clean == 'true' ||
            clean == '1' ||
            clean == 'yes' ||
            clean == 'y';
      }

      return false;
    }

    return FormQuestion(
      questionId: json['questionId']?.toString() ?? json['QuestionID']?.toString() ?? '',
      questionCode: json['questionCode']?.toString() ?? json['QuestionCode']?.toString() ?? '',
      questionText: json['questionText']?.toString() ?? json['QuestionText']?.toString() ?? '',
      controlType: json['controlType']?.toString() ?? json['ControlType']?.toString() ?? 'Textbox',
      isRequired: parseBool(json['isRequired'] ?? json['IsRequired']),
      isDraftRequired: parseBool(
        json['isDraftRequired'] ??
            json['IsDraftRequired'] ??
            json['is_draft_required'],
      ),
      displayOrder: int.tryParse(json['displayOrder']?.toString() ?? json['DisplayOrder']?.toString() ?? '0') ?? 0,
      placeholder: json['placeholder']?.toString() ?? json['Placeholder']?.toString(),
      helpText: json['helpText']?.toString() ?? json['HelpText']?.toString(),
      options: optionsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionCode': questionCode,
      'questionText': questionText,
      'controlType': controlType,
      'isRequired': isRequired,
      'isDraftRequired': isDraftRequired,
      'displayOrder': displayOrder,
      'placeholder': placeholder,
      'helpText': helpText,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }
}

class FormOption {
  final String optionId;
  final String optionText;
  final String optionValue;
  final int displayOrder;

  FormOption({
    required this.optionId,
    required this.optionText,
    required this.optionValue,
    required this.displayOrder,
  });

  factory FormOption.fromJson(Map<String, dynamic> json) {
    return FormOption(
      optionId: json['optionId']?.toString() ?? json['OptionID']?.toString() ?? '',
      optionText: json['optionText']?.toString() ?? json['OptionText']?.toString() ?? '',
      optionValue: json['optionValue']?.toString() ?? json['OptionValue']?.toString() ?? '',
      displayOrder: int.tryParse(json['displayOrder']?.toString() ?? json['DisplayOrder']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'optionId': optionId,
      'optionText': optionText,
      'optionValue': optionValue,
      'displayOrder': displayOrder,
    };
  }
}