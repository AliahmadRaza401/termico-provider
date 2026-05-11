import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/screens/instructions_pdf_screen.dart';
import 'package:handyman_provider_flutter/screens/splash_screen.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:nb_utils/nb_utils.dart';

import '../utils/constant.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 4;

  void _completeOnboarding() async {
    await setValue(IS_ONBOARDING_COMPLETED, true);
    if (!mounted) return;
    SplashScreen().launch(context, isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
  }

  void _openInstructionsPdf() {
    final code = appStore.selectedLanguageCode;
    final assetPath = providerInstructionsPdfAsset(code);
    InstructionsPdfScreen(assetPath: assetPath).launch(context).then((_) {
      _completeOnboarding();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header: back (or skip on first pages), title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, size: 20),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    )
                  else
                    SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      _currentPage == 0
                          ? languages.onboardingTitle1
                          : _currentPage == 1
                              ? languages.onboardingTitle2
                              : _currentPage == 2
                                  ? languages.onboardingTitle3
                                  : languages.providerInstructionsTitle,
                      style: boldTextStyle(size: 18),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_currentPage < _totalPages - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(languages.skip, style: primaryTextStyle(size: 14, color: primaryColor)),
                    )
                  else
                    SizedBox(width: 64),
                ],
              ),
            ),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _OnboardingPage(
                    title: languages.onboardingTitle1,
                    text: languages.onboardingText1,
                    icon: "assets/images/step 1.png",
                  ),
                  _OnboardingPage(
                    title: languages.onboardingTitle2,
                    text: languages.onboardingText2,
                    icon: "assets/images/step 2.png",
                  ),
                  _OnboardingPage(
                    title: languages.onboardingTitle3,
                    text: languages.onboardingText3,
                    icon: "assets/images/step 3.png",
                  ),
                  _ProviderInstructionsPage(
                    onReadInstructions: _openInstructionsPdf,
                    onSkip: _completeOnboarding,
                  ),
                ],
              ),
            ),
            // Bottom: dots + next/buttons
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (i) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? primaryColor : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  24.height,
                  if (_currentPage < _totalPages - 1)
                    AppButton(
                      width: context.width(),
                      text: languages.next,
                      color: primaryColor,
                      textColor: Colors.white,
                      onTap: () {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: languages.skip,
                            color: context.cardColor,
                            textColor: primaryColor,
                            shapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: primaryColor),
                            ),
                            onTap: _completeOnboarding,
                          ),
                        ),
                        16.width,
                        Expanded(
                          flex: 2,
                          child: AppButton(
                            text: languages.readInstructions,
                            color: primaryColor,
                            textColor: Colors.white,
                            onTap: _openInstructionsPdf,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String text;
  final String icon;

  const _OnboardingPage({
    Key? key,
    required this.title,
    required this.text,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          32.height,
             Image.asset(
                      icon,
                      height: context.height() * 0.35,
                      fit: BoxFit.contain,
                    ),
          // Container(
          //   width: 160,
          //   height: 160,
          //   decoration: BoxDecoration(
          //     color: primaryColor.withOpacity(0.12),
          //     shape: BoxShape.circle,
          //   ),
          //   child: Icon(icon, size: 80, color: primaryColor),
          // ),
          40.height,
          Text(
            title,
            style: boldTextStyle(size: 20),
            textAlign: TextAlign.center,
          ),
          16.height,
          Text(
            text,
            style: secondaryTextStyle(size: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProviderInstructionsPage extends StatelessWidget {
  final VoidCallback onReadInstructions;
  final VoidCallback onSkip;

  const _ProviderInstructionsPage({
    Key? key,
    required this.onReadInstructions,
    required this.onSkip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          24.height,
          // Illustration: phone + job list style
             Image.asset(
                      "assets/images/step 2.png",
                      height: context.height() * 0.35,
                      fit: BoxFit.contain,
                    ),
          32.height,
          Text(
            languages.providerInstructionsText,
            style: secondaryTextStyle(size: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
