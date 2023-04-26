import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ogree_app/common/appbar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ogree_app/common/popup_dialog.dart';
import 'package:ogree_app/models/tenant.dart';
import 'package:ogree_app/pages/projects_page.dart';
import 'package:ogree_app/widgets/tenants/api_stats_view.dart';
import 'package:ogree_app/widgets/tenants/locked_view.dart';
import 'package:ogree_app/widgets/tenants/popups/domain_popup.dart';
import 'package:ogree_app/widgets/tenants/docker_view.dart';
import 'package:ogree_app/widgets/select_objects/app_controller.dart';
import 'package:ogree_app/widgets/select_objects/settings_view/settings_view.dart';
import 'package:ogree_app/widgets/select_objects/tree_view/custom_tree_view.dart';
import 'package:ogree_app/widgets/tenants/user_view.dart';

class TenantPage extends StatefulWidget {
  final String userEmail;
  final Tenant tenant;
  const TenantPage({super.key, required this.userEmail, required this.tenant});

  @override
  State<TenantPage> createState() => _TenantPageState();
}

class _TenantPageState extends State<TenantPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late final AppController appController = AppController();
  bool _isLocked = true;
  bool _reloadDomains = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final localeMsg = AppLocalizations.of(context)!;
    return Scaffold(
        backgroundColor: Color.fromARGB(255, 238, 238, 241),
        appBar: myAppBar(context, widget.userEmail, isTenantMode: true),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.0, bottom: 14, left: 5),
                child: Row(
                  children: [
                    IconButton(
                        onPressed: () =>
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => ProjectsPage(
                                  userEmail: widget.userEmail,
                                  isTenantMode: true),
                            )),
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.blue.shade900,
                        )),
                    SizedBox(width: 5),
                    Text(
                      "Tenant ${widget.tenant.name}",
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TabBar(
                      controller: _tabController,
                      dividerColor: Colors.white,
                      labelPadding: const EdgeInsets.only(left: 20, right: 20),
                      labelColor: Colors.blue.shade900,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: TextStyle(
                          fontSize: 14,
                          fontFamily: GoogleFonts.inter().fontFamily),
                      unselectedLabelStyle: TextStyle(
                          fontSize: 14,
                          fontFamily: GoogleFonts.inter().fontFamily),
                      isScrollable: true,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: const [
                        Tab(
                          text: "Déploiement",
                          icon: Icon(Icons.dns),
                        ),
                        Tab(
                          text: "API Stats",
                          icon: Icon(Icons.info),
                        ),
                        Tab(
                          text: "Domains",
                          icon: Icon(Icons.business),
                        ),
                        Tab(
                          text: "Users",
                          icon: Icon(Icons.person),
                        ),
                      ],
                    ),
                    Divider(),
                    Container(
                      padding: const EdgeInsets.only(left: 20),
                      height: MediaQuery.of(context).size.height - 250,
                      width: double.maxFinite,
                      child: TabBarView(
                        physics: NeverScrollableScrollPhysics(),
                        controller: _tabController,
                        children: [
                          DockerView(tenantName: widget.tenant.name),
                          _isLocked
                              ? LockedView(
                                  tenant: widget.tenant,
                                  parentCallback: unlockView)
                              : ApiStatsView(tenant: widget.tenant),
                          _isLocked
                              ? LockedView(
                                  tenant: widget.tenant,
                                  parentCallback: unlockView)
                              : domainView(),
                          _isLocked
                              ? LockedView(
                                  tenant: widget.tenant,
                                  parentCallback: unlockView)
                              : UserView(tenant: widget.tenant),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  unlockView() {
    setState(() {
      _isLocked = false;
    });
  }

  domainView() {
    return Stack(children: [
      AppControllerScope(
        controller: appController,
        child: FutureBuilder<void>(
          future:
              appController.init({}, onlyDomain: true, reload: _reloadDomains),
          builder: (_, __) {
            if (_reloadDomains) {
              _reloadDomains = false;
            }
            if (appController.isInitialized) {
              return Stack(children: const [
                CustomTreeView(isTenantMode: true),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                        width: 320,
                        height: 116,
                        child: Card(
                            // color: Color.fromARGB(255, 250, 253, 255),
                            child: SettingsView(isTenantMode: true))),
                  ),
                ),
              ]);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20, right: 20),
          child: ElevatedButton.icon(
            onPressed: () =>
                showCustomPopup(context, DomainPopup(parentCallback: () {
              setState(() {
                _reloadDomains = true;
              });
            })),
            icon: Icon(Icons.add),
            label: Text("Créer domain"),
          ),
        ),
      ),
    ]);
  }
}
