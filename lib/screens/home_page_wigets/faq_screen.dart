import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mighty_fitness/features/faq/viewmodels/faq_view_model.dart';
import 'package:mighty_fitness/extensions/loader_widget.dart';

class FaqScreen extends StatefulWidget {
const FaqScreen({super.key});
  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final FaqViewModel vm = Get.put(FaqViewModel());
  final ScrollController _scrollController = ScrollController();
  int expandedIndex = -1;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          vm.hasMore &&
          !vm.isLoadingMore.value) {
        vm.fetchFaqs(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: CupertinoNavigationBarBackButton(
          color: cs.primary,
          onPressed: () => Get.back(),
        ),
        title: Text(
          "FAQs",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: cs.onSurface,
          ),
        ),
      ),

      body: Obx(() {

        /// LOADING
        if (vm.isLoading.value) {
          return Center(
            child: Loader(),
          );
        }

        /// ERROR
        if (vm.isError.value) {
          return _errorState(cs);
        }

        /// EMPTY
        if (vm.faqList.isEmpty) {
          return _emptyState(cs);
        }

        return RefreshIndicator(
          onRefresh: vm.refreshFaqs,
          color: cs.primary,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            children: [
              /// TOP LOTTIE HEADER
              const SizedBox(height: 10),
              // Lottie.asset(
              //   "assets/FAQ web page (1).json",
              //   height: 180,
              //   repeat: true,
              // ),
              const SizedBox(height: 10),
              ...List.generate(vm.faqList.length, (index) {
                final faq = vm.faqList[index];

                return _PremiumFaqCard(
                  index: index,
                  isExpanded: expandedIndex == index,
                  question: faq.title ?? "",
                  answer: faq.description ?? "",
                  onTap: () {
                    setState(() {
                      expandedIndex =
                          expandedIndex == index ? -1 : index;
                    });
                  },
                );
              }),

              if (vm.isLoadingMore.value)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lottie.asset("assets/FAQ web page.json", height: 200),
          const SizedBox(height: 16),
          Text(
            "No FAQs Available",
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 50, color: cs.error),
          const SizedBox(height: 12),
          Text(
            vm.errorMessage.value,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.error),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: vm.refreshFaqs,
            child: const Text("Retry"),
          )
        ],
      ),
    );
  }
}

class _PremiumFaqCard extends StatelessWidget {
  final int index;
  final bool isExpanded;
  final String question;
  final String answer;
  final VoidCallback onTap;

  const _PremiumFaqCard({
    required this.index,
    required this.isExpanded,
    required this.question,
    required this.answer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            cs.surface,
            cs.surface.withOpacity(0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// HEADER
          InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: isExpanded ? 0.5 : 0,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: cs.primary,
                  ),
                )
              ],
            ),
          ),

          /// BODY
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Html(
                data: answer,
                style: {
                  "body": Style(
                    fontSize: FontSize(14),
                    lineHeight: LineHeight(1.6),
                    color:
                        cs.onSurface.withOpacity(0.7),
                    margin: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                  ),

                  
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

