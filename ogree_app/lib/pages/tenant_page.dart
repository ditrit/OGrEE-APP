import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ogree_app/common/api.dart';
import 'package:ogree_app/common/appbar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ogree_app/common/popup_dialog.dart';
import 'package:ogree_app/models/tenant.dart';
import 'package:ogree_app/pages/projects_page.dart';
import 'package:ogree_app/widgets/tenants/create_domain_popup.dart';
import 'package:ogree_app/widgets/tenants/create_user_popup.dart';
import 'package:ogree_app/widgets/tenants/docker_view.dart';
import 'package:ogree_app/widgets/tenants/container_logs_popup.dart';
import 'package:ogree_app/widgets/select_objects/app_controller.dart';
import 'package:ogree_app/widgets/select_objects/settings_view/settings_view.dart';
import 'package:ogree_app/widgets/select_objects/settings_view/tree_filter.dart';
import 'package:ogree_app/widgets/select_objects/tree_view/custom_tree_view.dart';

class TenantPage extends StatefulWidget {
  final String userEmail;
  final Tenant tenant;
  const TenantPage({super.key, required this.userEmail, required this.tenant});

  @override
  State<TenantPage> createState() => _TenantPageState();
}

class _TenantPageState extends State<TenantPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, String>>? _dockerInfo;
  Map<String, dynamic>? _tenantStats;
  late final AppController appController = AppController();

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
                        controller: _tabController,
                        children: [
                          DockerView(tenantName: widget.tenant.name),
                          apiView(localeMsg),
                          Stack(children: [
                            AppControllerScope(
                              controller: appController,
                              child: FutureBuilder<void>(
                                future: appController.init({}, isTest: true),
                                builder: (_, __) {
                                  if (appController.isInitialized) {
                                    return Stack(children: const [
                                      CustomTreeView(),
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 16),
                                          child: SizedBox(
                                              width: 320,
                                              height: 116,
                                              child: Card(
                                                  color: Color.fromARGB(
                                                      255, 250, 253, 255),
                                                  child: SettingsView(
                                                      isTenantMode: true))),
                                        ),
                                      ),
                                    ]);
                                  }
                                  return const Center(
                                      child: CircularProgressIndicator());
                                },
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 20, right: 20),
                                child: ElevatedButton.icon(
                                  onPressed: () => showCustomPopup(context,
                                      CreateDomainPopup(parentCallback: () {})),
                                  icon: Icon(Icons.add),
                                  label: Text("Créer domain"),
                                ),
                              ),
                            ),
                          ] //put a button inside and position it with bottom and right
                              ),
                          Theme(
                            data: ThemeData(
                              cardTheme: const CardTheme(
                                  elevation: 0,
                                  surfaceTintColor: Colors.white,
                                  color: Colors.white),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(right: 16, top: 0),
                              child: PaginatedDataTable(
                                checkboxHorizontalMargin: 0,
                                header: TextField(
                                    decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  label: Text("Rechercher"),
                                  prefixIcon: IconButton(
                                    onPressed: () => {},
                                    tooltip: "Search",
                                    icon: const Icon(
                                      Icons.search_rounded,
                                    ),
                                  ),
                                )),
                                actions: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: ElevatedButton.icon(
                                      onPressed: () => showCustomPopup(
                                          context,
                                          CreateUserPopup(
                                              parentCallback: () {})),
                                      icon:
                                          Icon(Icons.add, color: Colors.white),
                                      label: Text("Créer user"),
                                    ),
                                  ),
                                ],
                                rowsPerPage:
                                    users.length >= 6 ? 6 : users.length,
                                // sortColumnIndex: sortColumnIndex > 0 ? sortColumnIndex : null,
                                // sortAscending: sort,
                                columns: const [
                                  DataColumn(
                                      label: Text(
                                    "Name",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  )),
                                  DataColumn(
                                      label: Text(
                                    "Email",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  )),
                                  DataColumn(
                                      label: Text(
                                    "Domains",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ))
                                ],
                                source: _DataSource(context),
                              ),
                            ),
                          ),
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

  apiView(AppLocalizations localeMsg) {
    return FutureBuilder(
        future: getTenantStats(),
        builder: (context, _) {
          if (_tenantStats == null) {
            return const Center(child: CircularProgressIndicator());
          } else if (_tenantStats!.isNotEmpty) {
            List<Widget> stats = [];
            for (var key in _tenantStats!.keys) {
              stats.add(Padding(
                padding: const EdgeInsets.only(left: 2, right: 10),
                child: Row(
                  children: [
                    Text(
                      "$key : ",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_tenantStats![key].toString())
                  ],
                ),
              ));
            }
            return Expanded(
              child: SingleChildScrollView(child: Column(children: stats)),
            );
          } else {
            // Empty messages
            return Text(localeMsg.noProjects);
          }
        });
  }

  getTenantStats() async {
    _tenantStats =
        await fetchTenantStats("http://localhost:${widget.tenant.apiUrl}");
    Map<String, dynamic> versionStats =
        await fetchTenantApiVersion("http://localhost:${widget.tenant.apiUrl}");
    for (var key in versionStats.keys) {
      if (key.contains("Build")) {
        _tenantStats!["API$key"] = versionStats[key];
      } else {
        _tenantStats![key] = versionStats[key];
      }
    }
  }
}

class _Row {
  _Row(
    this.cells,
  );

  final List<DataCell> cells;

  bool selected = false;
}

class _DataSource extends DataTableSource {
  _DataSource(this.context) {
    _rows = getChildren();
  }
  final BuildContext context;
  late List<_Row> _rows;

  int _selectedCount = 0;

  @override
  DataRow? getRow(int index) {
    assert(index >= 0);
    if (index >= _rows.length) return null;
    final row = _rows[index];
    return DataRow.byIndex(
      index: index,
      selected: row.selected,
      onSelectChanged: (value) {
        if (row.selected != value) {
          _selectedCount += value! ? 1 : -1;
          assert(_selectedCount >= 0);
          row.selected = value;
          notifyListeners();
        }
      },
      cells: row.cells,
    );
  }

  @override
  int get rowCount => _rows.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => _selectedCount;

  List<_Row> getChildren() {
    List<_Row> children = [];
    for (var user in users) {
      List<DataCell> row = [];
      row.add(label(user["name"], fontWeight: FontWeight.w500));
      row.add(label(user["email"]));
      row.add(label(user["roles"].keys.join(", ")));
      // for add column at the end
      children.add(_Row(row));
    }
    return children;
  }

  DataCell label(String label, {FontWeight fontWeight = FontWeight.w400}) {
    return DataCell(
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: fontWeight,
              color: label.contains('(') ? Colors.green : null),
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> users = [
  {
    "name": "Hervé Chibois",
    "email": "herve.chibois@exaion.com",
    "roles": {"EXAION": "manager", "EDF.DTEO.DSIT.ITO.ICS.EDC": "super"}
  },
  {
    "name": "Hervé Chibois",
    "email": "herve.chibois@exaion.com",
    "roles": {"EXAION": "manager", "EDF.DTEO.DSIT.ITO.ICS.EDC": "super"}
  },
  {
    "name": "Hervé Chibois",
    "email": "herve.chibois@exaion.com",
    "roles": {"EXAION": "manager", "EDF.DTEO.DSIT.ITO.ICS.EDC": "super"}
  },
  {
    "name": "Hervé Chibois",
    "email": "herve.chibois@exaion.com",
    "roles": {"EXAION": "manager", "EDF.DTEO.DSIT.ITO.ICS.EDC": "super"}
  },
  {
    "name": "Hervé Chibois",
    "email": "herve.chibois@exaion.com",
    "roles": {"EXAION": "manager", "EDF.DTEO.DSIT.ITO.ICS.EDC": "super"}
  },
  {
    "name": "Hervé Chibois",
    "email": "herve.chibois@exaion.com",
    "roles": {"EXAION": "manager", "EDF.DTEO.DSIT.ITO.ICS.EDC": "super"}
  },
  {
    "name": "Hervé Chibois",
    "email": "herve.chibois@exaion.com",
    "roles": {"EXAION": "manager", "EDF.DTEO.DSIT.ITO.ICS.EDC": "super"}
  },
  {
    "name": "Hervé Chibois",
    "email": "herve.chibois@exaion.com",
    "roles": {"EXAION": "manager", "EDF.DTEO.DSIT.ITO.ICS.EDC": "super"}
  },
  {
    "name": "Hervé Chibois",
    "email": "herve.chibois@exaion.com",
    "roles": {"EXAION": "manager", "EDF.DTEO.DSIT.ITO.ICS.EDC": "super"}
  }
];
