import 'package:flutter/material.dart';
import 'package:point_shoot_resolve/pages/home_page_admin.dart';
import 'package:point_shoot_resolve/routes/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:point_shoot_resolve/utils/constants/micrsoft_aad_constants.dart';

import '../model/user.dart';

class AuthProvider extends ChangeNotifier {
  final GlobalKey<NavigatorState> navigatorKey;

  AuthProvider({required this.navigatorKey});

  // Add a FormState variable and a method to set it
  FormState? _formState;

  void setFormState(FormState? formState) {
    _formState = formState;
  }

  UserDetails? _user;

  void setUser(UserDetails? user) {
    _user = user;
    notifyListeners();
  }

  UserDetails? getUser() {
    return _user;
  }

  Future<void> signInWithEmailAndPassword(
      String email, String password, BuildContext context) async {
    try {
      if (_formState != null && _formState!.validate()) {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        // Updating Display Name - Do it once for each type of admin
        // await FirebaseAuth.instance.currentUser!.updateDisplayName("Plumbing Department");
        String _desig =
            FirebaseAuth.instance.currentUser!.email!.substring(0, 5);
        String _designation = "";
        if (_desig == 'admin') {
          _designation = "Admin";
        } else if (_desig == "elect") {
          _designation = "Electrical Department";
        } else if (_desig == "plumb") {
          _designation = "Plumbing Department";
        } else if (_desig == "carpe") {
          _designation = "Hardware Department";
        } else if (_desig == "adoff") {
          // /adOff@amrita.com //adminOffice1234
          _designation = "Admin Office";
        }
        final user = UserDetails(
          name: FirebaseAuth.instance.currentUser!.displayName,
          rollNo: null,
          emailID: FirebaseAuth.instance.currentUser!.email,
          designation: _designation,
        );

        setUser(user);
        Navigator.of(navigatorKey.currentContext!).push(MaterialPageRoute(
        builder: (context) => HomePageAdmin(dept:_designation)));
      }
    } catch (error) {
      // Handle the error here
      // print("Error signing in: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Incorrect Credentials. Try again',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          duration: Duration(seconds: 3), // Adjust the duration as needed
        ),
      );
    }
  }

  Future<void> signOutFirebase() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamed(navigatorKey.currentContext!, MyRoutes.welcomeRoute);
  }

  Future<void> signOutMicrosoft() async {
    final AadOAuth microsoftOauth =
        OAuthConfig.createMicrosoftOAuth(navigatorKey);
    await microsoftOauth.logout();
    Navigator.pushNamed(navigatorKey.currentContext!, MyRoutes.welcomeRoute);
  }

  Future<void> signInWithMicrosoft() async {
    final AadOAuth microsoftOauth =
        OAuthConfig.createMicrosoftOAuth(navigatorKey);

    final result = await microsoftOauth.login();
    result.fold(
      (l) => showError(l.toString()),
      (r) {
        final idTokenPayload = Jwt.parseJwt(r.idToken!);
        var _nameRollNo = idTokenPayload["name"];
        List<String> _parts = _nameRollNo.split(' - [');
        String _name = _parts[0]
            .trim(); // Extract the name and remove leading/trailing spaces
        String _rollNo = _parts[1].replaceAll(
            ']', ''); // Extract the roll number and remove the closing bracket

        final user = UserDetails(
          name: _name,
          rollNo: _rollNo,
          emailID: idTokenPayload["preferred_username"],
          //(water)_dept, (elect)rical_dept, (admin)_amrita, (carpe)nter_dept
          designation: "Student",
        );

        setUser(user);
        Navigator.pushNamed(
            navigatorKey.currentContext!, MyRoutes.loggedInStudent);
        // showMessage('Logged in successfully, your access token: ${idTokenPayload['name']}');
      },
    );
  }

  void showError(dynamic ex) {
    showMessage(ex.toString());
  }

  void showMessage(String text) {
    var alert = AlertDialog(content: Text(text), actions: <Widget>[
      TextButton(
          child: const Text('Ok'),
          onPressed: () {
            Navigator.pop(navigatorKey.currentContext!);
          })
    ]);
    showDialog(
        context: navigatorKey.currentContext!,
        builder: (BuildContext context) => alert);
  }
}
