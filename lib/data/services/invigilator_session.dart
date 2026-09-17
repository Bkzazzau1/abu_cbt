/// The currently logged-in invigilator's identity, set once at login and
/// read wherever an action needs to be attributed to a person (escalating a
/// flag, terminating an exam, filing a malpractice report). Deliberately a
/// simple static holder rather than threaded through `Get.arguments` or a
/// controller lookup, since those screens can be reached via several
/// different navigation paths and shouldn't each need to know how to find
/// the logged-in invigilator's name.
class InvigilatorSession {
  InvigilatorSession._();

  static String currentName = '';
}
