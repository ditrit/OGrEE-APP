import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ogree_app/pages/login_page.dart';
import 'package:ogree_app/pages/projects_page.dart';
import 'package:ogree_app/widgets/language_toggle.dart';

AppBar myAppBar(context, userEmail, {isTenantMode = false}) {
  logout() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
  return AppBar(
    backgroundColor: Colors.grey.shade900,
    leadingWidth: 150,
    leading: Center(
        child: TextButton(
      child: Text(
        'OGrEE',
        style: TextStyle(
            fontSize: 21, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              ProjectsPage(userEmail: userEmail, isTenantMode: isTenantMode),
        ),
      ),
    )),
    actions: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: LanguageToggle(),
      ),
      const SizedBox(width: 20),
      PopupMenuButton<String>(
          onSelected: (_) => logout(),
          itemBuilder: (_) => <PopupMenuEntry<String>>[
                PopupMenuItem(
                  value: "logout",
                  child: Text("Logout"),
                ),
              ],
          child: Row(
            children: [
              const Icon(
                Icons.account_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                userEmail,
                style: TextStyle(color: Colors.white),
              ),
            ],
          )),
      const SizedBox(width: 40)
    ],
  );
}
