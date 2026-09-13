# Demo login accounts

Choose the matching role on the sign-in screen. Students enter their registration
number, click **Next**, then complete the fingerprint demonstration. Staff continue
to use their username and password. Each account has its own login;
sign out before signing into another account. The login screen also lists these
under **Demo account details** for the selected role.

| Role | Name | Username / registration | Password / verification |
| --- | --- | --- | --- |
| Administrator | ABU Administrator | admin.abu | AbuAdmin123! |
| Invigilator | Amina Yusuf | invigilator.a | invA123 |
| Invigilator | Musa Ibrahim | invigilator.b | invB123 |
| Invigilator | Chief Invigilator | chief.invigilator | chief123 |
| Student | Zainab Musa | ABU/CSC/001 | Fingerprint (demo) |
| Student | Ibrahim Bashir Yahaya | ABU/MTH/004 | Fingerprint (demo) |
| Student | Maryam Bello | ABU/GST/011 | Fingerprint (demo) |
| Student | Sadiq Lawal | ABU/CSC/008 | Fingerprint (demo) |
| Student | Fatima Musa | ABU/BIO/002 | Fingerprint (demo) |
| Student | Umar Aliyu | ABU/CHM/007 | Fingerprint (demo) |
| Student | Aisha Bello | ABU/PHY/003 | Fingerprint (demo) |

Students see their own identity and assigned practice courses. Published sample
results are filtered to the signed-in student; students without a seeded result
see an empty register. Staff share the demo examination operations records.

These are intentionally public, local demo credentials. Role checks and sessions
are implemented in the client for the UI demonstration, not as production authentication.

## Fingerprint demonstration

The second student login page shows scan progress, a successful match, a mismatch
with retry, and reader-unavailable guidance. No student session is created until
a match is completed and **Continue to exams** is selected. Student password
sign-in is disabled. Cancelling returns to registration without granting access.

No physical reader is connected and no biometric samples are captured or stored.
`FingerprintReader` is the integration boundary; an actual reader requires its
vendor SDK and verification against the enrolled student identity.
