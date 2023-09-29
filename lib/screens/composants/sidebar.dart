import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:taxischrono/screens/auths/login_page.dart';

import 'package:taxischrono/screens/composants/mesrequettes.dart';
import 'package:taxischrono/screens/paquage.dart';
// import 'package:taxischrono/services/firebaseauthservice.dart';
import 'package:taxischrono/varibles/variables.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auths/profilepage.dart';
import 'codepromo.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  bool isConnected = authentication.currentUser != null;
  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
              right: Radius.circular(30), left: Radius.circular(8))),
      child: ListView(
        // Remove padding
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: dredColor),
            accountName: isConnected
                ? Text(
                    authentication.currentUser!.displayName!,
                    style: police.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Text("Veillez vous connecter",
                    style: police.copyWith(fontWeight: FontWeight.bold)),
            accountEmail:
                !isConnected ? null : Text(authentication.currentUser!.email!),

            currentAccountPicture: CircleAvatar(
              radius: 70,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl:
                      'https://png.pngtree.com/png-clipart/20190924/original/pngtree-business-people-avatar-icon-user-profile-free-vector-png-image_4815126.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 90,
                ),
              ),
            ),
            // decoration: const BoxDecoration(
            //   color: Colors.blue,
            //   image: DecorationImage(
            //       fit: BoxFit.fill,
            //       image: NetworkImage(
            //           'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png')),
            // ),
          ),
          isConnected
              ? ListTile(
                  leading: const Icon(Icons.person_pin),
                  title: Text('Mon compte', style: police),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      PageTransition(
                          child: authentication.currentUser != null
                              ? const ProfileScreen()
                              : const LoginPage(),
                          type: PageTransitionType.leftToRight),
                    );
                  },
                )
              : const SizedBox.shrink(),
          !isConnected
              ? ListTile(
                  leading: const Icon(Icons.person_pin),
                  title: Text('Connexion', style: police),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(PageTransition(
                      child: const LoginPage(),
                      type: PageTransitionType.fade,
                    ));
                  },
                )
              : const SizedBox.shrink(),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text('Mes Requetes', style: police),
            onTap: () {
              if (!isConnected) {
                Fluttertoast.showToast(
                    msg: "Vous n'êtes pas connecté\n Veillez vous authentifier",
                    toastLength: Toast.LENGTH_LONG,
                    backgroundColor: dredColor);
              }
              Navigator.of(context).pop();
              Navigator.of(context).push(PageTransition(
                  child: isConnected ? const MesRequettes() : const LoginPage(),
                  type: PageTransitionType.leftToRight));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.panorama_fish_eye_rounded),
            title: Text('Packages', style: police),
            onTap: () {
              Navigator.of(context).pop();
              if (isConnected) {
                Navigator.of(context).push(PageTransition(
                    child: const PackageUi(), type: PageTransitionType.fade));
              } else {
                getsnac(
                    title: "Connexion",
                    icons: Icon(Icons.info_outline, color: dredColor),
                    msg:
                        "Veillez vous connecter avant de souscrire à un package");
                connexion();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: Text('A propos de Taxis chrono', style: police),
            // ignore: avoid_returning_null_for_void
            onTap: () async =>
                await launchUrl(Uri.parse("https://www.taxi-chrono.net")),
          ),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: Text('Utiliser un code Promo', style: police),
              // ignore: avoid_returning_null_for_void
              onTap: () {
                if (authentication.currentUser == null) {
                  Fluttertoast.showToast(
                      msg:
                          "Vous n'êtes pas connecté\n Veillez vous authentifier",
                      toastLength: Toast.LENGTH_LONG,
                      backgroundColor: dredColor);
                }
                Navigator.of(context).pop();
                Navigator.of(context).push(PageTransition(
                    child: authentication.currentUser != null
                        ? const CodePromocomponent()
                        : const LoginPage(),
                    type: PageTransitionType.leftToRight));
              }),

          // isConnected
          ListTile(
              title: Text('Contacter nous', style: police),
              leading: const Icon(Icons.call),
              // ignore: avoid_returning_null_for_void
              onTap: () async {
                await FlutterPhoneDirectCaller.callNumber("+237658549711");
              }),
          //         : getsnac(
          //             title: "DÉCONNEXION", msg: "Aucun compte connecté"),
          //   )
          // : const SizedBox.shrink(),
        ],
      ),
    );
  }

  // fontion de navigation vers la page d'authentification
  connexion() => Navigator.of(context).push(PageTransition(
        child: const LoginPage(),
        type: PageTransitionType.fade,
      ));
}
