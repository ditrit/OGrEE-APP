import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ogree_app/common/api_backend.dart';
import 'package:ogree_app/common/snackbar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ogree_app/models/user.dart';
import 'package:ogree_app/widgets/select_objects/settings_view/tree_filter.dart';

class CreateUserPopup extends StatefulWidget {
  Function() parentCallback;
  User? modifyUser;
  CreateUserPopup({super.key, required this.parentCallback, this.modifyUser});

  @override
  State<CreateUserPopup> createState() => _CreateUserPopupState();
}

class _CreateUserPopupState extends State<CreateUserPopup> {
  final _formKey = GlobalKey<FormState>();
  String? _userName;
  String? _userPassword;
  bool _isLoading = false;
  List<String>? domainList;
  List<String> selectedDomain = [];
  List<String> roleList = <String>['Manager', 'User', 'Viewer'];
  List<String> selectedRole = [];
  List<Widget> domainRoleRows = [];
  bool isEdit = false;
  @override
  void initState() {
    super.initState();
    isEdit = widget.modifyUser != null;
  }

  @override
  Widget build(BuildContext context) {
    final localeMsg = AppLocalizations.of(context)!;
    return FutureBuilder(
        future: domainList == null ? getDomains() : null,
        builder: (context, _) {
          if (domainList == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: Container(
              // height: 240,
              width: 500,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 20, 40, 15),
                child: Material(
                  color: Colors.white,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isEdit ? "Modifier user" : "Créer un nouveau user",
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Divider(height: 40),
                        getFormField(
                            save: (newValue) => _userName = newValue,
                            label: "Email",
                            icon: Icons.alternate_email,
                            initial: isEdit ? widget.modifyUser!.email : null),
                        getFormField(
                            save: (newValue) => _userPassword = newValue,
                            label: "Mot de passe",
                            icon: Icons.lock,
                            initial:
                                isEdit ? widget.modifyUser!.password : null,
                            obscure: true),
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0, bottom: 10),
                          child: Text("Permissions :"),
                        ),
                        Column(children: domainRoleRows),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: TextButton.icon(
                                onPressed: () => setState(() {
                                      domainRoleRows.add(addDomainRoleRow(
                                          domainRoleRows.length));
                                    }),
                                icon: Icon(Icons.add),
                                label: Text("Domain")),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue.shade900),
                              onPressed: () => Navigator.pop(context),
                              label: Text(localeMsg.cancel),
                              icon: const Icon(
                                Icons.cancel_outlined,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 15),
                            ElevatedButton.icon(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    _formKey.currentState!.save();
                                    try {
                                      Map<String, String> roles = getRolesMap();
                                      setState(() {
                                        _isLoading = true;
                                      });

                                      var response;
                                      if (isEdit) {
                                        response = await modifyUser(
                                            widget.modifyUser!.id!, roles);
                                      } else {
                                        response = await createUser(User(
                                            email: _userName!,
                                            password: _userPassword!,
                                            roles: roles));
                                      }

                                      if (response == "") {
                                        widget.parentCallback();
                                        showSnackBar(
                                            context,
                                            isEdit
                                                ? "User successfully modified"
                                                : "User created 🥳",
                                            isSuccess: true);
                                        Navigator.of(context).pop();
                                      } else {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                        showSnackBar(context, response,
                                            isError: true);
                                      }
                                    } catch (e) {
                                      showSnackBar(context, e.toString(),
                                          isError: true);
                                      return;
                                    }
                                  }
                                },
                                label: Text(
                                    isEdit ? "Modifier" : localeMsg.create),
                                icon: _isLoading
                                    ? Container(
                                        width: 24,
                                        height: 24,
                                        padding: const EdgeInsets.all(2.0),
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle, size: 16))
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
  }

  getDomains() async {
    var list = await fetchObjectsTree(onlyDomain: true);
    domainList =
        list[0].values.reduce((value, element) => List.from(value + element));
    if (!isEdit) {
      if (domainList!.isNotEmpty) {
        domainList!.add("*");
        domainRoleRows.add(addDomainRoleRow(0));
      }
    } else {
      domainList!.add("*");
      var roles = widget.modifyUser!.roles;
      for (var i = 0; i < roles.length; i++) {
        selectedDomain.add(roles.keys.elementAt(i));
        selectedRole.add(roles.values.elementAt(i).capitalize());
        domainRoleRows.add(addDomainRoleRow(i, useDefaultValue: false));
      }
    }
  }

  Map<String, String> getRolesMap() {
    Map<String, String> roles = {};
    for (var i = 0; i < selectedDomain.length; i++) {
      if (roles.containsKey(selectedDomain[i])) {
        throw Exception("Only one role can be assigned per domain");
      }
      roles[selectedDomain[i]] = selectedRole[i].toLowerCase();
    }
    return roles;
  }

  getFormField(
      {required Function(String?) save,
      required String label,
      required IconData icon,
      String? prefix,
      String? suffix,
      List<TextInputFormatter>? formatters,
      String? initial,
      bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 10),
      child: TextFormField(
        obscureText: obscure,
        initialValue: initial,
        readOnly: isEdit,
        onSaved: (newValue) => save(newValue),
        validator: (text) {
          if (text == null || text.isEmpty) {
            return AppLocalizations.of(context)!.mandatoryField;
          }
          return null;
        },
        inputFormatters: formatters,
        decoration: InputDecoration(
          icon: Icon(icon, color: isEdit ? Colors.grey : Colors.blue.shade900),
          labelText: label,
          prefixText: prefix,
          suffixText: suffix,
        ),
      ),
    );
  }

  rebuildDomainRole() {
    domainRoleRows = [];
    for (var i = 0; i < selectedDomain.length; i++) {
      domainRoleRows.add(addDomainRoleRow(i, useDefaultValue: false));
    }
  }

  removeDomainRoleRow(int rowIdx) {
    selectedDomain.removeAt(rowIdx);
    selectedRole.removeAt(rowIdx);
    rebuildDomainRole();
  }

  addDomainRoleRow(int rowIdx, {bool useDefaultValue = true}) {
    if (useDefaultValue) {
      selectedDomain.add(domainList!.first);
      selectedRole.add(roleList.first);
    }
    return StatefulBuilder(builder: (context, _setState) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // SizedBox(width: 20),
          Flexible(
            flex: 3,
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedDomain[rowIdx],
              items: domainList!.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? value) {
                _setState(() {
                  selectedDomain[rowIdx] = value!;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(
              Icons.arrow_forward,
              color: Colors.blue.shade900,
            ),
          ),
          Flexible(
            flex: 2,
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedRole[rowIdx],
              items: roleList.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? value) {
                _setState(() {
                  selectedRole[rowIdx] = value!;
                });
              },
            ),
          ),
          rowIdx > 0
              ? IconButton(
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(),
                  iconSize: 14,
                  onPressed: () => setState(() => removeDomainRoleRow(rowIdx)),
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red.shade400,
                  ))
              : SizedBox(width: 22),
        ],
      );
    });
  }
}
