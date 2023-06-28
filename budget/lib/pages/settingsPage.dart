import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/aboutPage.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/widgets/importCSV.dart';
import 'package:budget/pages/autoTransactionsPageEmail.dart';
import 'package:budget/pages/editAssociatedTitlesPage.dart';
import 'package:budget/pages/editBudgetPage.dart';
import 'package:budget/pages/editCategoriesPage.dart';
import 'package:budget/pages/editWalletsPage.dart';
import 'package:budget/pages/notificationsPage.dart';
import 'package:budget/pages/subscriptionsPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/widgets/accountAndBackup.dart';
import 'package:budget/widgets/moreIcons.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/radioItems.dart';
import 'package:budget/widgets/ratingPopup.dart';
import 'package:budget/widgets/selectColor.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/pages/walletDetailsPage.dart';
import 'package:budget/widgets/util/initializeBiometrics.dart';
import 'package:budget/widgets/util/initializeNotifications.dart';
import 'package:budget/widgets/util/upcomingTransactionsFunctions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:budget/main.dart';
import '../functions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/framework/popupFramework.dart';

//To get SHA1 Key run
// ./gradlew signingReport
//in budget\Android
//Generate new OAuth and put JSON in budget\android\app folder

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key, this.hasMorePages = true}) : super(key: key);
  final bool hasMorePages;

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  GlobalKey<PageFrameworkState> pageState = GlobalKey();

  late Color? selectedColor = HexColor(appStateSettings["accentColor"]);
  void refreshState() {
    print("refresh settings");
    setState(() {});
  }

  void scrollToTop() {
    pageState.currentState!.scrollToTop();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      key: pageState,
      title: "More Actions",
      backButton: false,
      appBarBackgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      appBarBackgroundColorStart: Theme.of(context).canvasColor,
      horizontalPadding: getHorizontalPaddingConstrained(context),
      listWidgets: [
        SettingsContainerOpenPage(
          openPage: AboutPage(),
          title: "About Cashew",
          icon: Icons.info_outline_rounded,
        ),
        kIsWeb
            ? SettingsContainer(
                title: "Cashew is Open Source",
                icon: Icons.code_rounded,
                onTap: () {
                  openUrl("https://github.com/jameskokoska/Cashew");
                },
              )
            : SizedBox.shrink(),
        kIsWeb
            ? SettingsContainer(
                title: "Share Feedback",
                icon: Icons.rate_review_rounded,
                onTap: () {
                  openBottomSheet(context, RatingPopup());
                },
              )
            : SizedBox.shrink(),
        widget.hasMorePages ? MorePages() : SizedBox.shrink(),
        SettingsHeader(title: "Theme"),
        SettingsContainer(
          onTap: () {
            openBottomSheet(
              context,
              PopupFramework(
                title: "Select Color",
                child: SelectColor(
                  includeThemeColor: false,
                  selectedColor: selectedColor,
                  setSelectedColor: (color) {
                    selectedColor = color;
                    updateSettings("accentColor", toHexString(color));
                    updateSettings("accentSystemColor", false);
                    generateColors();
                  },
                  useSystemColorPrompt: true,
                ),
              ),
            );
          },
          title: "Accent Color",
          description: "Select a color theme for the interface",
          icon: Icons.color_lens_rounded,
        ),
        SettingsContainerSwitch(
          title: "Material You",
          description: "Use a colorful expressive interface",
          onSwitched: (value) {
            updateSettings("materialYou", value, updateGlobalState: true);
          },
          initialValue: appStateSettings["materialYou"],
          icon: Icons.brush_rounded,
        ),
        SettingsContainerDropdown(
          title: "Theme Mode",
          icon: Icons.lightbulb_rounded,
          initial: appStateSettings["theme"].toString().capitalizeFirst,
          items: ["Light", "Dark", "System"],
          onChanged: (value) {
            if (value == "Light") {
              updateSettings("theme", "light");
            } else if (value == "Dark") {
              updateSettings("theme", "dark");
            } else if (value == "System") {
              updateSettings("theme", "system");
            }
          },
        ),
        EnterName(),
        SettingsHeader(title: "Preferences"),
        SettingsContainerSwitch(
          title: "Battery Saver",
          description:
              "Optimize the UI to increase performance and save battery",
          onSwitched: (value) {
            updateSettings("batterySaver", value,
                updateGlobalState: true, pagesNeedingRefresh: [0, 1, 2, 3]);
          },
          initialValue: appStateSettings["batterySaver"],
          icon: Icons.battery_charging_full_rounded,
        ),
        biometricsAvailable
            ? SettingsContainerSwitch(
                title: "Require Biometrics",
                description: "Lock the application with biometrics",
                onSwitched: (value) async {
                  bool result = await checkBiometrics(
                    checkAlways: true,
                    message: "Please verify your identity.",
                  );
                  if (result)
                    updateSettings("requireAuth", value,
                        updateGlobalState: false);
                  return result;
                },
                initialValue: appStateSettings["requireAuth"],
                icon: Icons.lock_rounded,
              )
            : SizedBox.shrink(),

        SettingsHeader(title: "Automation"),
        // SettingsContainerOpenPage(
        //   openPage: AutoTransactionsPage(),
        //   title: "Auto Transactions",
        //   icon: Icons.auto_fix_high_rounded,
        // ),
        ImportCSV(),

        appStateSettings["emailScanning"]
            ? SettingsContainerOpenPage(
                openPage: AutoTransactionsPageEmail(),
                title: "Auto Email Transactions",
                icon: Icons.mark_email_unread_rounded,
              )
            : SizedBox.shrink(),

        SettingsContainerSwitch(
          title: "Pay Subscriptions",
          description:
              "Automatically mark a subscription as paid after the due date.",
          onSwitched: (value) async {
            if (true) {
              await markSubscriptionsAsPaid();
              await setUpcomingNotifications(context);
            }
            updateSettings("automaticallyPaySubscriptions", value,
                updateGlobalState: false);
          },
          initialValue: appStateSettings["automaticallyPaySubscriptions"],
          icon: getTransactionTypeIcon(TransactionSpecialType.subscription),
        ),
      ],
    );
  }
}

class MorePages extends StatelessWidget {
  const MorePages({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              kIsWeb
                  ? SizedBox.shrink()
                  : Expanded(
                      child: SettingsContainer(
                        onTap: () {
                          openUrl("https://github.com/jameskokoska/Cashew");
                        },
                        title: "Open Source",
                        icon: Icons.code_rounded,
                        isOutlined: true,
                      ),
                    ),
              kIsWeb
                  ? SizedBox.shrink()
                  : Expanded(
                      child: SettingsContainer(
                        onTap: () {
                          openBottomSheet(context, RatingPopup());
                        },
                        title: "Feedback",
                        icon: Icons.rate_review_rounded,
                        isOutlined: true,
                      ),
                    ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: SubscriptionsPage(),
                  title: "Subscriptions",
                  icon: Icons.event_repeat_rounded,
                  isOutlined: true,
                ),
              ),
              kIsWeb
                  ? SizedBox.shrink()
                  : Expanded(
                      child: SettingsContainerOpenPage(
                        openPage: NotificationsPage(),
                        title: "Notifications",
                        icon: Icons.notifications_rounded,
                        isOutlined: true,
                      ),
                    ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: EditWalletsPage(title: "Edit Wallets"),
                  title: "Wallets",
                  icon: Icons.account_balance_wallet_rounded,
                  isOutlined: true,
                ),
              ),
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: EditBudgetPage(title: "Edit Budgets"),
                  title: "Budgets",
                  icon: MoreIcons.chart_pie,
                  iconSize: 20,
                  isOutlined: true,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: EditCategoriesPage(title: "Edit Categories"),
                  title: "Categories",
                  icon: Icons.category_rounded,
                  isOutlined: true,
                ),
              ),
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: EditAssociatedTitlesPage(title: "Edit Titles"),
                  title: "Titles",
                  icon: Icons.text_fields_rounded,
                  isOutlined: true,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: WalletDetailsPage(wallet: null),
                  title: "All Spending",
                  icon: Icons.line_weight_rounded,
                  isOutlined: true,
                ),
              ),
              Expanded(child: GoogleAccountLoginButton()),
            ],
          ),
        ),
      ],
    );
  }
}

class EnterName extends StatelessWidget {
  const EnterName({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      title: "Username",
      icon: Icons.edit,
      onTap: () {
        enterNameBottomSheet(context);
      },
    );
  }
}

Future enterNameBottomSheet(context) async {
  return await openBottomSheet(
    context,
    PopupFramework(
      title: "Enter Name",
      child: Column(
        children: [
          SelectText(
            icon: Icons.title_rounded,
            setSelectedText: (_) {},
            nextWithInput: (text) {
              updateSettings("username", text.trim(), pagesNeedingRefresh: [0]);
            },
            selectedText: appStateSettings["username"],
            placeholder: "Nickname",
            autoFocus: false,
            requestLateAutoFocus: true,
          ),
        ],
      ),
    ),
  );
}
