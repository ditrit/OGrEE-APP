import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ogree_app/common/api_backend.dart';
import 'package:ogree_app/common/appbar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ogree_app/common/popup_dialog.dart';
import 'package:ogree_app/common/snackbar.dart';
import 'package:ogree_app/models/tenant.dart';
import 'package:ogree_app/models/user.dart';
import 'package:ogree_app/pages/projects_page.dart';
import 'package:ogree_app/widgets/tenants/create_domain_popup.dart';
import 'package:ogree_app/widgets/tenants/create_user_popup.dart';
import 'package:ogree_app/widgets/tenants/docker_view.dart';
import 'package:ogree_app/widgets/tenants/container_logs_popup.dart';
import 'package:ogree_app/widgets/select_objects/app_controller.dart';
import 'package:ogree_app/widgets/select_objects/settings_view/settings_view.dart';
import 'package:ogree_app/widgets/select_objects/settings_view/tree_filter.dart';
import 'package:ogree_app/widgets/select_objects/tree_view/custom_tree_view.dart';
import 'package:ogree_app/widgets/tenants/tenant_card.dart';

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
  List<User> _users = [];
  late final AppController appController = AppController();
  String _apiToken = "";
  String? _email;
  String? _password;
  static const inputStyle = OutlineInputBorder(
    borderSide: BorderSide(
      color: Colors.grey,
      width: 1,
    ),
  );
  bool _loadUsers = true;
  bool _reloadDomains = false;
  List<User> selectedUsers = [];

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
                          _apiToken == "" ? lockedView() : apiView(localeMsg),
                          _apiToken == "" ? lockedView() : domainView(),
                          _apiToken == "" ? lockedView() : usersView(),
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
    _tenantStats = await fetchTenantStats(
        "http://localhost:${widget.tenant.apiUrl}", _apiToken);
    Map<String, dynamic> versionStats = await fetchTenantApiVersion(
        "http://localhost:${widget.tenant.apiUrl}", _apiToken);
    for (var key in versionStats.keys) {
      if (key.contains("Build")) {
        _tenantStats!["API$key"] = versionStats[key];
      } else {
        _tenantStats![key] = versionStats[key];
      }
    }
  }

  domainView() {
    return Stack(children: [
      AppControllerScope(
        controller: appController,
        child: FutureBuilder<void>(
          future:
              appController.init({}, onlyDomain: true, reload: _reloadDomains),
          builder: (_, __) {
            print("### buildeeeer");
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
                showCustomPopup(context, CreateDomainPopup(parentCallback: () {
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

  getUsers() async {
    _users = await fetchApiUsers(
        "http://localhost:${widget.tenant.apiUrl}", _apiToken);
  }

  usersView() {
    return FutureBuilder(
        future: _loadUsers ? getUsers() : null,
        builder: (context, _) {
          if (_users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          _loadUsers = false;
          print("Rebuild users view");
          return Theme(
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
                    padding: const EdgeInsets.only(right: 4.0),
                    child: IconButton(
                        splashRadius: 23,
                        // iconSize: 14,
                        onPressed: () => selectedUsers.length > 0
                            ? showCustomPopup(
                                context,
                                CreateUserPopup(
                                  parentCallback: () {
                                    setState(() {
                                      _loadUsers = true;
                                    });
                                  },
                                  modifyUser: selectedUsers.first,
                                ),
                                isDismissible: true)
                            : null,
                        icon: Icon(
                          Icons.edit,
                          // color: Colors.red.shade900,
                        )),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                        splashRadius: 23,
                        // iconSize: 14,
                        onPressed: () => selectedUsers.length > 0
                            ? showCustomPopup(
                                context,
                                DeleteDialog(
                                  objName: selectedUsers.map((e) {
                                    print(e);
                                    return e.id!;
                                  }).toList(),
                                  objType: "users",
                                  parentCallback: () {
                                    setState(() {
                                      _loadUsers = true;
                                    });
                                  },
                                ),
                                isDismissible: true)
                            : null,
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red.shade900,
                        )),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ElevatedButton.icon(
                      onPressed: () => showCustomPopup(context,
                          CreateUserPopup(parentCallback: () {
                        setState(() {
                          _loadUsers = true;
                        });
                      })),
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text("Créer user"),
                    ),
                  ),
                ],
                rowsPerPage: _users.length >= 6 ? 6 : _users.length,
                columns: const [
                  DataColumn(
                      label: Text(
                    "Email",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  )),
                  DataColumn(
                      label: Text(
                    "Domains (roles)",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ))
                ],
                source: _DataSource(context, _users, onUserSelected),
              ),
            ),
          );
        });
  }

  onUserSelected(int index, bool value) {
    if (index < 0) {
      selectedUsers = [];
    } else if (value) {
      selectedUsers.add(_users[index]);
    } else {
      selectedUsers.remove(_users[index]);
    }
  }

  lockedView() {
    final localeMsg = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    return Form(
      key: formKey,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 350, maxHeight: 500),
        padding: const EdgeInsets.only(
          right: 100,
          left: 100,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64),
            const SizedBox(height: 20),
            Text("Log in to this tenant's API to get access:"),
            const SizedBox(height: 20),
            SizedBox(
              width: 350,
              child: TextFormField(
                onSaved: (newValue) => _email = newValue,
                validator: (text) {
                  if (text == null || text.isEmpty) {
                    return localeMsg.mandatoryField;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'E-mail',
                  hintText: 'abc@example.com',
                  labelStyle: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.black,
                  ),
                  border: inputStyle,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              constraints: const BoxConstraints(maxWidth: 350),
              child: TextFormField(
                obscureText: true,
                onSaved: (newValue) => _password = newValue,
                onEditingComplete: () => tryLogin(formKey),
                validator: (text) {
                  if (text == null || text.isEmpty) {
                    return localeMsg.mandatoryField;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  isDense: true,
                  labelText: localeMsg.password,
                  hintText: '********',
                  labelStyle: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.black,
                  ),
                  border: inputStyle,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              child: ElevatedButton(
                onPressed: () => tryLogin(formKey),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),
                ),
                child: Text(
                  localeMsg.login,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  tryLogin(formKey) {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      loginAPITenant(
              _email!, _password!, "http://localhost:${widget.tenant.apiUrl}")
          .then((value) => value != ""
              ? setState(() {
                  print(_apiToken);
                  _apiToken = value;
                })
              : showSnackBar(
                  context, AppLocalizations.of(context)!.invalidLogin,
                  isError: true))
          .onError((error, stackTrace) {
        print(error);
        showSnackBar(context, error.toString().trim(), isError: true);
      });
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
  List<User> users;
  final Function onRowSelected;
  _DataSource(this.context, this.users, this.onRowSelected) {
    _rows = getChildren();
    onRowSelected(-1, false);
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
        print("hello selection");
        if (row.selected != value) {
          _selectedCount += value! ? 1 : -1;
          assert(_selectedCount >= 0);
          row.selected = value;
          notifyListeners();
          onRowSelected(index, value);
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
    print("### Get children");
    for (var user in users) {
      List<DataCell> row = [];
      row.add(label(user.email, fontWeight: FontWeight.w500));
      String domainStr = "";
      for (var domain in user.roles.keys) {
        domainStr =
            "$domainStr ${domain == "*" ? "All domains" : domain} (${user.roles[domain]});";
      }
      row.add(label(domainStr));
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
          ),
        ),
      ),
    );
  }
}
