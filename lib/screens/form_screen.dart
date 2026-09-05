import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';
import '../providers/form_provider.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/section_card.dart';

class FormScreen extends StatefulWidget {
  final String? entryId;
  final bool readOnly;

  const FormScreen({super.key, this.entryId, this.readOnly = false});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> with TickerProviderStateMixin {
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, GlobalKey> _questionKeys = {};

  TabController? _tabController;
  PageController? _pageController;
  bool _isPageAnimating = false;

  FocusNode _getFocusNode(String questionId) {
    return _focusNodes.putIfAbsent(questionId, () => FocusNode());
  }

  GlobalKey _getQuestionKey(String questionId) {
    return _questionKeys.putIfAbsent(questionId, () => GlobalKey());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FormProvider>().loadForm(
        entryId: widget.entryId,
        readOnly: widget.readOnly,
      );
    });
  }

  void _initTabAndPageControllers(int totalSections) {
    if (totalSections <= 0) return;

    if (_tabController == null || _tabController!.length != totalSections) {
      _tabController?.dispose();
      _pageController?.dispose();

      _tabController = TabController(length: totalSections, vsync: this);
      _pageController = PageController();

      _tabController!.addListener(() {
        if (!mounted) return;
        setState(() {}); // Rebuild UI for tab selection state change
      });
    }
  }

  void _onTabTapped(int index) {
    if (_tabController?.index == index && _pageController?.page == index) return;

    _isPageAnimating = true;
    _tabController?.animateTo(index);

    if (_pageController != null && _pageController!.hasClients) {
      _pageController!
          .animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      )
          .then((_) {
        _isPageAnimating = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _pageController?.dispose();
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  String _extractSectionTitle(dynamic section) {
    try {
      if (section.title != null && section.title.toString().isNotEmpty) {
        return section.title;
      }
    } catch (_) {}
    try {
      if (section.sectionTitle != null && section.sectionTitle.toString().isNotEmpty) {
        return section.sectionTitle;
      }
    } catch (_) {}
    try {
      if (section.name != null && section.name.toString().isNotEmpty) {
        return section.name;
      }
    } catch (_) {}
    try {
      if (section.sectionName != null && section.sectionName.toString().isNotEmpty) {
        return section.sectionName;
      }
    } catch (_) {}
    return 'Section';
  }

  void _scrollToAndFocusQuestion(String questionId) {
    final provider = context.read<FormProvider>();
    if (provider.form == null) return;

    final sections = provider.form!.sections;
    int sectionIndex = -1;

    for (int i = 0; i < sections.length; i++) {
      if (sections[i].questions.any((q) => q.questionId == questionId)) {
        sectionIndex = i;
        break;
      }
    }

    if (sectionIndex != -1) {
      _onTabTapped(sectionIndex);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contextKey = _questionKeys[questionId]?.currentContext;
      if (contextKey != null) {
        Scrollable.ensureVisible(
          contextKey,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
      }

      final focusNode = _focusNodes[questionId];
      if (focusNode != null) {
        focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FormProvider>();
    final bool isReadOnly = provider.isReadOnly;
    final String title = isReadOnly
        ? 'Inspection Details'
        : (widget.entryId != null ? 'Edit Inspection' : 'Inspection Form');

    final sections = provider.form?.sections ?? [];

    if (sections.isNotEmpty) {
      _initTabAndPageControllers(sections.length);
    }

    return Scaffold(
      appBar: CommonAppBar(title: title),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.form == null || sections.isEmpty
          ? const Center(child: Text('Failed to load form'))
          : Column(
        children: [
          // CLEAN CUSTOM SEGMENT BUTTON TABS
          if (_tabController != null)
            Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: sections.asMap().entries.map((entry) {
                    final index = entry.key;
                    final sec = entry.value;
                    final isSelected = _tabController!.index == index;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () => _onTabTapped(index),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                                : null,
                          ),
                          child: Text(
                            _extractSectionTitle(sec),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          const Divider(height: 1, color: AppColors.border),

          // SECTION PAGE CONTENT
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: sections.length,
              onPageChanged: (index) {
                if (!_isPageAnimating && _tabController != null) {
                  _tabController!.animateTo(index);
                }
              },
              itemBuilder: (context, index) {
                final section = sections[index];

                return SingleChildScrollView(
                  padding: Responsive.pagePadding(context),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Responsive.contentMaxWidth(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var q in section.questions) ...[
                            KeyedSubtree(
                              key: _getQuestionKey(q.questionId),
                              child: Focus(
                                focusNode: _getFocusNode(q.questionId),
                                child: const SizedBox.shrink(),
                              ),
                            ),
                          ],
                          SectionCard(
                            section: section,
                            provider: provider,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // BOTTOM ACTION BAR
          _StepBottomBar(
            provider: provider,
            entryId: widget.entryId,
            totalSections: sections.length,
            tabController: _tabController,
            pageController: _pageController,
            onTabTapped: _onTabTapped,
            onInvalid: _scrollToAndFocusQuestion,
          ),
        ],
      ),
    );
  }
}

class _StepBottomBar extends StatefulWidget {
  final FormProvider provider;
  final String? entryId;
  final int totalSections;
  final TabController? tabController;
  final PageController? pageController;
  final Function(int index) onTabTapped;
  final Function(String invalidQuestionId) onInvalid;

  const _StepBottomBar({
    required this.provider,
    required this.totalSections,
    required this.tabController,
    required this.pageController,
    required this.onTabTapped,
    required this.onInvalid,
    this.entryId,
  });

  @override
  State<_StepBottomBar> createState() => _StepBottomBarState();
}

class _StepBottomBarState extends State<_StepBottomBar> {
  bool _isSaving = false;

  Future<void> _handleSaveDraft() async {
    if (_isSaving) return;

    final isValid = widget.provider.validateDraft();

    if (!isValid) {
      final invalidId = widget.provider.getFirstInvalidQuestionId();
      if (invalidId != null) {
        widget.onInvalid(invalidId);
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.provider.submitForm(
        entryId: widget.entryId,
        status: 'Draft',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft Saved Successfully'),
            backgroundColor: AppColors.textSecondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save draft: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final isValid = widget.provider.validateAll();

    if (!isValid) {
      final invalidId = widget.provider.getFirstInvalidQuestionId();
      if (invalidId != null) {
        widget.onInvalid(invalidId);
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.provider.submitForm(
        entryId: widget.entryId,
        status: 'Submitted',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspection Saved Successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabController == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: widget.tabController!,
      builder: (context, child) {
        final currentIndex = widget.tabController!.index;
        final isFirst = currentIndex == 0;
        final isLast = currentIndex == widget.totalSections - 1;
        final bool isReadOnly = widget.provider.isReadOnly;

        return Card(
          elevation: 4,
          margin: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // PREVIOUS BUTTON
                if (!isFirst)
                  OutlinedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => widget.onTabTapped(currentIndex - 1),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(100, 44),
                    ),
                  )
                else
                  const Spacer(),

                const Spacer(),

                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),

                // NEXT / SUBMIT BUTTONS
                if (!isLast)
                  ElevatedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => widget.onTabTapped(currentIndex + 1),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 44),
                    ),
                  )
                else if (!isReadOnly) ...[
                  OutlinedButton(
                    onPressed: _isSaving ? null : _handleSaveDraft,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(110, 44),
                    ),
                    child: const Text('Draft'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 44),
                    ),
                    child: Text(
                      widget.entryId != null ? 'Update' : 'Submit',
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}