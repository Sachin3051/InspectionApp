import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';
import '../models/form_model.dart';
import '../providers/form_provider.dart';
import 'question_widgets.dart';

class SectionCard extends StatelessWidget {
  final FormSection section;
  final FormProvider provider;

  const SectionCard({
    super.key,
    required this.section,
    required this.provider,
  });

  static const _fieldTypes = [
    'Textbox',
    'Textarea',
    'Dropdown',
    'Date',
  ];

  @override
  Widget build(BuildContext context) {
    final fieldQuestions = section.questions
        .where((q) => _fieldTypes.contains(q.controlType))
        .toList();

    final radioQuestions = section.questions
        .where((q) => q.controlType == 'Radio')
        .toList();

    final imageQuestions = section.questions
        .where((q) => q.controlType == 'ImageUpload')
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            color: AppColors.primary,
            child: Text(
              section.sectionName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),

          // CONTENT
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (fieldQuestions.isNotEmpty)
                  _FieldGrid(
                    questions: fieldQuestions,
                    provider: provider,
                  ),

                if (radioQuestions.isNotEmpty) ...[
                  if (fieldQuestions.isNotEmpty) const SizedBox(height: 16),
                  const _RadioTableHeader(),
                  const Divider(height: 20),
                  for (int i = 0; i < radioQuestions.length; i++) ...[
                    RadioQuestionRow(
                      key: ValueKey(
                        'radio_${radioQuestions[i].questionId}_${provider.answerFor(radioQuestions[i].questionId).selectedOptionValue}',
                      ),
                      question: radioQuestions[i],
                      provider: provider,
                    ),
                    if (i != radioQuestions.length - 1) const Divider(height: 24),
                  ],
                ],

                if (imageQuestions.isNotEmpty) ...[
                  if (fieldQuestions.isNotEmpty || radioQuestions.isNotEmpty)
                    const SizedBox(height: 16),
                  for (int i = 0; i < imageQuestions.length; i++) ...[
                    ImageUploadQuestionRow(
                      key: ValueKey(
                        'img_${imageQuestions[i].questionId}_${provider.answerFor(imageQuestions[i].questionId).images.length}',
                      ),
                      question: imageQuestions[i],
                      provider: provider,
                    ),
                    if (i != imageQuestions.length - 1) const Divider(height: 20),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioTableHeader extends StatelessWidget {
  const _RadioTableHeader();

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return const SizedBox.shrink();
    }

    return const Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            'Touch Points',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            'Decision',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldGrid extends StatelessWidget {
  final List<FormQuestion> questions;
  final FormProvider provider;

  const _FieldGrid({
    required this.questions,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = Responsive.isDesktop(context)
            ? 3
            : (Responsive.isTablet(context) ? 2 : 1);

        final width = (constraints.maxWidth - (columns - 1) * 16) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: questions.map((q) {
            final answer = provider.answerFor(q.questionId);

            return SizedBox(
              width: width,
              child: FieldQuestion(
                key: ValueKey(
                  'field_${q.questionId}_${answer.textValue}_${answer.selectedOptionValue}_${answer.dateValue}',
                ),
                question: q,
                provider: provider,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}