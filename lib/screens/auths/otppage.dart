import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pinput/pinput.dart';
import 'package:taxischrono/modeles/applicationuser/client.dart';

import '../../modeles/applicationuser/appliactionuser.dart';
import '../../varibles/variables.dart';
import '../composants/delayed_animation.dart';
import '../homepage.dart';

class OtpPage extends StatefulWidget {
  final String verificationId;
  final String? phone;
  final ApplicationUser? utilisateur;
  final bool isauthentication;
  const OtpPage(
      {super.key,
      this.phone,
      this.utilisateur,
      required this.verificationId,
      required this.isauthentication});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  bool loader = false;
  String smsCode = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: dredColor, size: 27),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: loader
            ? const LoadingComponen()
            : SingleChildScrollView(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DelayedAnimation(
                        delay: 1500,
                        child: Text(
                          "Vérification du numéro de téléphone",
                          style: GoogleFonts.poppins(
                            color: dredColor,
                            letterSpacing: 3,
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      spacerHeight(30),
                      DelayedAnimation(
                        delay: 2000,
                        child: Text(
                          "Un code a été envoyé au numéro",
                          style: police.copyWith(
                              fontWeight: FontWeight.bold, height: 2),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      spacerHeight(5),
                      DelayedAnimation(
                        delay: 2000,
                        child: Text(
                          widget.utilisateur != null
                              ? "${widget.utilisateur!.userTelephone}"
                              : "${widget.phone}",
                          style: police.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      spacerHeight(50),
                      DelayedAnimation(
                        delay: 2500,
                        child: Pinput(
                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: focusedPinTheme(),
                          submittedPinTheme: submitpinTheme(),
                          onChanged: (val) {
                            setState(() {
                              smsCode = val;
                            });
                          },
                          length: 6,
                          onCompleted: (val) {
                            setState(() {
                              smsCode = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 120),
                      DelayedAnimation(
                          delay: 3000,
                          child: boutonText(
                              context: context,
                              action: () async {
                                if (smsCode.length == 6) {
                                  try {
                                    loader = true;
                                    setState(() {});
                                    if (widget.isauthentication) {
                                      await ApplicationUser.validateOPT(context,
                                          smsCode: smsCode,
                                          phone: widget.phone!,
                                          verificationId:
                                              widget.verificationId);
                                    } else {
                                      ApplicationUser chauffeur =
                                          widget.utilisateur!;
                                      await Client.validateOPT(
                                        chauffeur,
                                        context,
                                        smsCode: smsCode,
                                        verificationId: widget.verificationId,
                                      );
                                    }
                                    loader = false;
                                    setState(() {});
                                    // Navigator.of(context).pushAndRemoveUntil(
                                    //     PageTransition(
                                    //         child: const HomePage(),
                                    //         type:
                                    //             PageTransitionType.leftToRight),
                                    //     (route) => false);
                                  } catch (e) {
                                    debugPrint(e.toString());
                                    print("error update data $e");
                                    loader = false;
                                    setState(() {});
                                    toaster(
                                        message: 'Erreur de vérification',
                                        color: Colors.red);
                                  }
                                }
                              },
                              text: 'Valider'.toUpperCase())),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: police,
      decoration: BoxDecoration(
          border: Border.all(color: dredColor),
          borderRadius: BorderRadius.circular(40)));
  PinTheme focusedPinTheme() => defaultPinTheme.copyDecorationWith(
        border: Border.all(color: const Color.fromRGBO(114, 178, 238, 1)),
        borderRadius: BorderRadius.circular(12),
      );
  PinTheme submitpinTheme() => defaultPinTheme.copyDecorationWith(
        border: Border.all(color: const Color.fromARGB(49, 114, 178, 238)),
        borderRadius: BorderRadius.circular(12),
      );
}
