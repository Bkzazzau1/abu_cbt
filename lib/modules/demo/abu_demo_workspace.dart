import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';

import '../portal/controller/center_exam_portal_controller.dart';
import 'abu_demo_theme.dart';
import 'demo_store.dart';
import '../auth/demo_auth.dart';

class AbuDemoWorkspace extends StatefulWidget {
  const AbuDemoWorkspace({super.key});
  @override
  State<AbuDemoWorkspace> createState() => _AbuDemoWorkspaceState();
}

class _AbuDemoWorkspaceState extends State<AbuDemoWorkspace> {
  final store = DemoStore.instance;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String page = 'Overview', query = '', filter = 'All', hall = 'Hall A';
  final search = TextEditingController();
  BuildContext? themedContext;
  final navigation = const {
    'Overview': Icons.space_dashboard_outlined,
    'Examinations': Icons.assignment_outlined,
    'Question bank': Icons.library_books_outlined,
    'Candidates': Icons.people_outline,
    'Hall monitoring': Icons.grid_view_outlined,
    'Attendance': Icons.fact_check_outlined,
    'Results': Icons.bar_chart_outlined,
    'Incidents': Icons.flag_outlined,
    'Settings': Icons.tune,
  };
  List<String> get pages => store.role == 'Student'
      ? ['My examinations', 'My results', 'Help & guidance']
      : store.role == 'Invigilator'
      ? [
          'Overview',
          'Hall monitoring',
          'Attendance',
          'Candidates',
          'Incidents',
          'Help & guidance',
        ]
      : [...navigation.keys, 'Help & guidance'];

  @override
  void initState() {
    super.initState();
    if (store.role == 'Student') page = 'My examinations';
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void go(String next) {
    setState(() {
      page = next;
      query = '';
      filter = 'All';
      search.clear();
    });
    if (scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(themedContext!).pop();
    }
  }

  void notice(String message) =>
      ScaffoldMessenger.of(themedContext!).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  void change(String message, VoidCallback action) {
    store.update(message, action);
    notice(message);
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: abuDemoTheme(),
    child: Builder(
      builder: (context) {
        themedContext = context;
        return AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final wide = MediaQuery.sizeOf(context).width >= 1050;
            return Scaffold(
              key: scaffoldKey,
              drawer: wide ? null : Drawer(child: sidebar()),
              body: SafeArea(
                child: Row(
                  children: [
                    if (wide) SizedBox(width: 244, child: sidebar()),
                    Expanded(
                      child: Column(
                        children: [
                          header(wide),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.all(wide ? 32 : 18),
                              children: [
                                pageHeading(),
                                const SizedBox(height: 25),
                                ...content(),
                                const SizedBox(height: 28),
                                const Divider(),
                                const SizedBox(height: 12),
                                const Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  spacing: 20,
                                  runSpacing: 8,
                                  children: [
                                    Text(
                                      'Ahmadu Bello University, Zaria',
                                      style: TextStyle(
                                        color: abuMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Interactive demo · Changes last for this app session',
                                      style: TextStyle(
                                        color: abuMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );

  Widget sidebar() => Material(
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 20, 28),
          child: Row(
            children: [
              Image.asset(
                'assets/abulogo.png',
                width: 44,
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ahmadu Bello University, Zaria',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'EXAMINATION PORTAL',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          color: abuMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            store.role.toUpperCase(),
            style: const TextStyle(
              color: abuMuted,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: pages.map((name) {
              final selected = name == page;
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: ListTile(
                  dense: true,
                  selected: selected,
                  selectedTileColor: const Color(0xFFEAF3EC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  leading: Icon(
                    navigation[name] ??
                        (name == 'Help & guidance'
                            ? Icons.help_outline
                            : Icons.school_outlined),
                    size: 21,
                    color: selected ? abuGreen : abuMuted,
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? abuGreen : abuMuted,
                    ),
                  ),
                  onTap: () => go(name),
                  trailing: name == 'Incidents'
                      ? badge(
                          '${store.incidents.where((i) => !i.resolved).length}',
                          warning: true,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: abuCanvas,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.science_outlined, color: abuGreen),
                SizedBox(height: 10),
                Text(
                  'Your account workspace',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                SizedBox(height: 6),
                Text(
                  'Each account has its own workspace. Sign out to use a different demo account.',
                  style: TextStyle(color: abuMuted, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Text(
            '2026 / 2027  •  Demo session',
            style: TextStyle(fontSize: 11, color: abuMuted),
          ),
        ),
      ],
    ),
  );

  Widget header(bool wide) => Container(
    height: 80,
    padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: abuLine)),
    ),
    child: Row(
      children: [
        if (!wide)
          IconButton(
            tooltip: 'Open navigation',
            onPressed: () => scaffoldKey.currentState!.openDrawer(),
            icon: const Icon(Icons.menu),
          ),
        if (wide) ...[
          const Icon(Icons.account_balance_outlined, size: 19, color: abuMuted),
          const SizedBox(width: 10),
          const Text(
            'Academic affairs',
            style: TextStyle(color: abuMuted, fontSize: 13),
          ),
          const SizedBox(width: 10),
          const Text('/', style: TextStyle(color: abuMuted)),
          const SizedBox(width: 10),
          Text(page, style: const TextStyle(fontSize: 13)),
        ],
        const Spacer(),
        if (wide) ...[badge('DEMO'), const SizedBox(width: 20)],
        SizedBox(
          width: wide ? 160 : 110,
          child: Text(
            DemoAuth.instance.account?.name ?? '',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: DemoAuth.instance.signOut,
          icon: const Icon(Icons.logout, size: 20),
        ),
        const SizedBox(width: 12),
        if (store.role != 'Student')
          IconButton(
            tooltip: 'Recent activity',
            onPressed: () =>
                details('Recent activity', store.activity.join('\n\n')),
            icon: const Icon(Icons.notifications_none, size: 22),
          ),
      ],
    ),
  );

  Widget pageHeading() {
    final subtitles = {
      'Overview': 'A clear view of today’s examinations and centre activity.',
      'Examinations': 'Plan, schedule and manage the examination lifecycle.',
      'Question bank':
          'Build and review questions before they reach an examination.',
      'Candidates': 'Manage candidate records and examination eligibility.',
      'Hall monitoring':
          'A simulated view of workstations across your examination halls.',
      'Attendance':
          'Verify candidate identity and record arrival at the centre.',
      'Results': 'Review assessment outcomes and control result publication.',
      'Incidents': 'Record, track and resolve issues during examinations.',
      'Settings': 'Personalise the centre’s demo examination preferences.',
      'My examinations': 'Your examination schedule and practice sessions.',
      'My results': 'Your published examination results, in one place.',
      'Help & guidance':
          'Everything you need for a smooth examination experience.',
    };
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 16,
      spacing: 20,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              page == 'Overview' ? 'Examination overview' : page,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitles[page] ?? '',
              style: const TextStyle(color: abuMuted, fontSize: 13),
            ),
          ],
        ),
        if (store.role == 'Administrator' &&
            ['Overview', 'Examinations'].contains(page))
          FilledButton.icon(
            onPressed: examForm,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create examination'),
          ),
        if (page == 'Question bank')
          FilledButton.icon(
            onPressed: questionForm,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add question'),
          ),
        if (page == 'Candidates' && store.role == 'Administrator')
          FilledButton.icon(
            onPressed: candidateForm,
            icon: const Icon(Icons.person_add_alt, size: 18),
            label: const Text('Add candidate'),
          ),
        if (page == 'Incidents')
          FilledButton.icon(
            onPressed: incidentForm,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Report incident'),
          ),
      ],
    );
  }

  List<Widget> content() => switch (page) {
    'Overview' => overview(),
    'Examinations' => [examTable()],
    'Question bank' => questionBank(),
    'Candidates' || 'Attendance' => [candidateTable()],
    'Hall monitoring' => hallMonitoring(),
    'Results' || 'My results' => results(),
    'Incidents' => incidents(),
    'Settings' => settings(),
    'My examinations' => student(),
    _ => help(),
  };

  Widget panel({
    required Widget child,
    String? title,
    String? subtitle,
    Widget? action,
  }) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: abuLine),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 12, color: abuMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (action != null) action,
              ],
            ),
          ),
        child,
      ],
    ),
  );

  Widget badge(String text, {bool warning = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF2DF) : const Color(0xFFEAF3EC),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: warning ? const Color(0xFFA36D16) : abuGreen,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget stats(List<(String, String, String, IconData)> items) => LayoutBuilder(
    builder: (context, constraints) {
      final cols = constraints.maxWidth > 800
          ? 4
          : constraints.maxWidth > 480
          ? 2
          : 1;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: items
            .map(
              (item) => SizedBox(
                width: (constraints.maxWidth - (cols - 1) * 16) / cols,
                child: panel(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.$1,
                                style: const TextStyle(
                                  color: abuMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Icon(item.$4, color: abuGreen, size: 20),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          item.$3,
                          style: const TextStyle(fontSize: 11, color: abuMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );

  List<Widget> overview() => [
    Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: abuGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 20,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '2026 / 2027 ACADEMIC SESSION',
                style: TextStyle(
                  color: Color(0xFFBDD3BC),
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Prepared for every examination.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Manage the details. Give every candidate room to succeed.',
                style: TextStyle(color: Color(0xFFD3E2D7), fontSize: 13),
              ),
            ],
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF68917E)),
            ),
            onPressed: () => go('Hall monitoring'),
            icon: const Icon(Icons.arrow_outward, size: 18),
            label: const Text('Open control room'),
          ),
        ],
      ),
    ),
    const SizedBox(height: 22),
    stats([
      (
        'Examinations',
        '${store.exams.length}',
        '${store.exams.where((e) => e.status == 'In progress').length} session in progress',
        Icons.assignment_outlined,
      ),
      (
        'Registered candidates',
        '${store.candidates.length}',
        'Across ${store.candidates.map((c) => c.department).toSet().length} departments',
        Icons.people_outline,
      ),
      (
        'Checked in',
        '${store.candidates.where((c) => c.checkedIn).length}',
        'Candidate identity verified',
        Icons.how_to_reg_outlined,
      ),
      (
        'Open incidents',
        '${store.incidents.where((i) => !i.resolved).length}',
        'Awaiting invigilator action',
        Icons.flag_outlined,
      ),
    ]),
    const SizedBox(height: 24),
    examTable(compact: true),
    const SizedBox(height: 24),
    LayoutBuilder(
      builder: (context, c) {
        final halls = panel(
          title: 'Examination halls',
          subtitle: 'Demo workstation availability',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
            child: Column(
              children: ['Hall A', 'Hall B', 'Hall C']
                  .map(
                    (name) => Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: InkWell(
                        onTap: () {
                          hall = name;
                          go('Hall monitoring');
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.desktop_windows_outlined,
                              color: abuGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Text(name)),
                            badge(
                              name == 'Hall A' ? 'Session active' : 'Ready',
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.chevron_right, size: 18),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
        final activity = panel(
          title: 'Recent activity',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
            child: Column(
              children: store.activity
                  .take(4)
                  .map(
                    (event) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: abuGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              event,
                              style: const TextStyle(
                                fontSize: 12,
                                color: abuMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
        return c.maxWidth > 760
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: halls),
                  const SizedBox(width: 22),
                  Expanded(child: activity),
                ],
              )
            : Column(children: [halls, const SizedBox(height: 20), activity]);
      },
    ),
  ];

  Widget toolbar(String hint, List<String> filters) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
    child: Wrap(
      spacing: 14,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: search,
            onChanged: (v) => setState(() => query = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search, size: 19),
              isDense: true,
            ),
          ),
        ),
        ...filters.map(
          (f) => ChoiceChip(
            label: Text(f, style: const TextStyle(fontSize: 11)),
            selected: filter == f,
            onSelected: (_) => setState(() => filter = f),
            showCheckmark: false,
          ),
        ),
      ],
    ),
  );

  Widget table(List<String> headings, List<List<Widget>> rows) => rows.isEmpty
      ? const Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.search_off, color: abuMuted, size: 36),
              SizedBox(height: 12),
              Text('No matching records'),
              SizedBox(height: 6),
              Text(
                'Try another search or filter.',
                style: TextStyle(color: abuMuted),
              ),
            ],
          ),
        )
      : LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: const WidgetStatePropertyAll(abuCanvas),
                headingRowHeight: 44,
                dataRowMinHeight: 70,
                dataRowMaxHeight: 82,
                horizontalMargin: 22,
                columnSpacing: 28,
                dividerThickness: 0.5,
                columns: headings
                    .map(
                      (h) => DataColumn(
                        label: Text(
                          h.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: abuMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                rows: rows
                    .map(
                      (r) => DataRow(
                        cells: r.map((cell) => DataCell(cell)).toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );

  Widget cell(String title, [String? sub]) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      if (sub != null) ...[
        const SizedBox(height: 5),
        Text(sub, style: const TextStyle(fontSize: 11, color: abuMuted)),
      ],
    ],
  );

  Widget examTable({bool compact = false}) {
    final exams = store.exams
        .where(
          (e) =>
              compact ||
              ('${e.code} ${e.title}'.toLowerCase().contains(query) &&
                  (filter == 'All' || e.status == filter)),
        )
        .toList();
    return panel(
      title: compact ? 'Examination schedule' : 'All examinations',
      subtitle: 'Sample timetable · ${store.semester}',
      action: compact && store.role == 'Administrator'
          ? TextButton(
              onPressed: () => go('Examinations'),
              child: const Text('View all →'),
            )
          : null,
      child: Column(
        children: [
          if (!compact)
            toolbar('Search course or title', [
              'All',
              'Draft',
              'Scheduled',
              'In progress',
              'Completed',
            ]),
          table(
            [
              'Course / examination',
              'Hall',
              'Start time',
              'Candidates',
              'Status',
              '',
            ],
            exams
                .map(
                  (e) => [
                    cell(e.title, '${e.code} · ${e.duration} minutes'),
                    cell(e.hall),
                    cell(e.time),
                    cell('${e.candidates}'),
                    badge(e.status, warning: e.status == 'Draft'),
                    IconButton(
                      tooltip: 'Manage ${e.code}',
                      onPressed: () => examDetails(e),
                      icon: const Icon(
                        Icons.arrow_forward,
                        size: 19,
                        color: abuGreen,
                      ),
                    ),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> details(String title, String body) => showDialog<void>(
    context: themedContext!,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Text(body, style: const TextStyle(height: 1.7)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  Future<void> examDetails(DemoExam exam) => showDialog<void>(
    context: themedContext!,
    builder: (context) => AlertDialog(
      title: Text(exam.title),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            badge(exam.status),
            const SizedBox(height: 20),
            Text(
              '${exam.code}\n${exam.hall} · ${exam.time}\n${exam.duration} minutes · ${exam.candidates} candidates',
              style: const TextStyle(height: 1.9),
            ),
            const SizedBox(height: 16),
            const Text(
              'This action changes the simulated session status.',
              style: TextStyle(fontSize: 12, color: abuMuted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (exam.status != 'Completed')
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              final next = switch (exam.status) {
                'Draft' => 'Scheduled',
                'Scheduled' => 'In progress',
                _ => 'Completed',
              };
              change('${exam.code} marked $next', () => exam.status = next);
            },
            child: Text(switch (exam.status) {
              'Draft' => 'Publish schedule',
              'Scheduled' => 'Start session',
              _ => 'End session',
            }),
          ),
      ],
    ),
  );

  Future<List<String>?> form(
    String title,
    List<String> labels, {
    List<String>? initial,
    String button = 'Save',
    Set<int> numeric = const {},
  }) async {
    final controllers = List.generate(
      labels.length,
      (i) => TextEditingController(text: initial?[i] ?? ''),
    );
    final key = GlobalKey<FormState>();
    final result = await showDialog<List<String>>(
      context: themedContext!,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  labels.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: controllers[i],
                      keyboardType: numeric.contains(i)
                          ? TextInputType.number
                          : TextInputType.text,
                      maxLines:
                          labels[i].contains('Question') ||
                              labels[i].contains('Description')
                          ? 3
                          : 1,
                      decoration: InputDecoration(labelText: labels[i]),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'This field is required';
                        }
                        if (numeric.contains(i) &&
                            ((int.tryParse(v) ?? 0) <= 0)) {
                          return 'Enter a positive whole number';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(
                  context,
                  controllers.map((c) => c.text.trim()).toList(),
                );
              }
            },
            child: Text(button),
          ),
        ],
      ),
    );
    // Dialog fields remain mounted during their closing animation.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    for (final controller in controllers) {
      controller.dispose();
    }
    return result;
  }

  Future<void> examForm() async {
    final values = await form(
      'Create examination',
      [
        'Course code',
        'Examination title',
        'Hall',
        'Schedule label',
        'Duration (minutes)',
        'Candidate capacity',
      ],
      initial: ['', '', 'Hall A', 'Tomorrow · 09:00 AM', '60', '40'],
      numeric: {4, 5},
      button: 'Create draft',
    );
    if (values == null || !mounted) return;
    change(
      '${values[0]} draft created',
      () => store.exams.add(
        DemoExam(
          values[0].toUpperCase(),
          values[1],
          values[2],
          values[3],
          int.parse(values[5]),
          duration: int.parse(values[4]),
          status: 'Draft',
        ),
      ),
    );
    go('Examinations');
  }

  List<Widget> questionBank() => [
    panel(
      title: 'Question library',
      subtitle:
          '${store.questions.length} questions · ${store.questions.where((q) => q.approved).length} approved',
      child: Column(
        children: [
          toolbar('Search questions or course', ['All', 'Draft', 'Approved']),
          table(
            ['Question', 'Course', 'Type', 'Status', ''],
            store.questions
                .where(
                  (q) =>
                      '${q.prompt} ${q.course}'.toLowerCase().contains(query) &&
                      (filter == 'All' ||
                          (q.approved ? 'Approved' : 'Draft') == filter),
                )
                .map(
                  (q) => [
                    SizedBox(
                      width: 350,
                      child: Text(
                        q.prompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    cell(q.course),
                    cell('Single choice'),
                    badge(
                      q.approved ? 'Approved' : 'Draft',
                      warning: !q.approved,
                    ),
                    TextButton(
                      onPressed: () => questionDetails(q),
                      child: const Text('Review'),
                    ),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    ),
  ];

  Future<void> questionForm() async {
    final v = await form('Add a single-choice question', [
      'Course code',
      'Question text',
      'Option A',
      'Option B',
      'Option C',
      'Option D',
      'Correct option (A, B, C or D)',
    ]);
    if (v == null || !mounted) return;
    final answer = ['A', 'B', 'C', 'D'].indexOf(v[6].toUpperCase());
    if (answer < 0) {
      notice('Question not saved. Correct option must be A, B, C or D.');
      return;
    }
    change(
      'Question added to ${v[0]}',
      () => store.questions.add(
        DemoQuestion(v[0].toUpperCase(), v[1], v.sublist(2, 6), answer),
      ),
    );
  }

  Future<void> questionDetails(DemoQuestion q) => showDialog<void>(
    context: themedContext!,
    builder: (context) => AlertDialog(
      title: Text('${q.course} · Question review'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(q.prompt, style: const TextStyle(fontSize: 18, height: 1.5)),
              const SizedBox(height: 20),
              ...List.generate(
                q.options.length,
                (i) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    i == q.answer ? Icons.check_circle : Icons.circle_outlined,
                    color: i == q.answer ? abuGreen : abuMuted,
                  ),
                  title: Text(q.options[i]),
                  subtitle: i == q.answer ? const Text('Correct answer') : null,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            change(
              q.approved ? 'Question returned to draft' : 'Question approved',
              () => q.approved = !q.approved,
            );
          },
          child: Text(q.approved ? 'Return to draft' : 'Approve question'),
        ),
      ],
    ),
  );

  Widget candidateTable() => panel(
    title: page == 'Attendance' ? 'Candidate check-in' : 'Candidate directory',
    subtitle:
        '${store.candidates.where((c) => c.checkedIn).length} of ${store.candidates.length} checked in',
    action: TextButton.icon(
      onPressed: copyAttendance,
      icon: const Icon(Icons.copy_outlined, size: 16),
      label: const Text('Copy register'),
    ),
    child: Column(
      children: [
        toolbar('Search name or registration', [
          'All',
          'Checked in',
          'Expected',
        ]),
        table(
          ['Candidate', 'Department', 'Seat', 'Attendance', ''],
          store.candidates
              .where(
                (c) =>
                    '${c.name} ${c.number}'.toLowerCase().contains(query) &&
                    (filter == 'All' ||
                        (c.checkedIn ? 'Checked in' : 'Expected') == filter),
              )
              .map(
                (c) => [
                  cell(c.name, c.number),
                  cell(c.department),
                  cell(c.seat),
                  badge(
                    c.checkedIn ? 'Checked in' : 'Expected',
                    warning: !c.checkedIn,
                  ),
                  TextButton(
                    onPressed: () => candidateDetails(c),
                    child: Text(c.checkedIn ? 'View record' : 'Check in'),
                  ),
                ],
              )
              .toList(),
        ),
      ],
    ),
  );

  Future<void> candidateForm() async {
    final v = await form('Add candidate', [
      'Full name',
      'Registration number',
      'Department',
      'Seat',
    ]);
    if (v == null || !mounted) return;
    if (store.candidates.any(
      (c) =>
          c.number.toLowerCase() == v[1].toLowerCase() ||
          c.seat.toLowerCase() == v[3].toLowerCase(),
    )) {
      notice('Registration number or seat already exists.');
      return;
    }
    change(
      '${v[0]} added',
      () => store.candidates.add(
        DemoCandidate(v[0], v[1].toUpperCase(), v[2], v[3].toUpperCase()),
      ),
    );
  }

  Future<void> candidateDetails(DemoCandidate c) => showDialog<void>(
    context: themedContext!,
    builder: (context) => AlertDialog(
      title: Text(c.name),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${c.number}\n${c.department}\nAssigned seat: ${c.seat}',
              style: const TextStyle(height: 1.9),
            ),
            const SizedBox(height: 20),
            badge(
              c.checkedIn
                  ? 'Identity verified · Checked in'
                  : 'Awaiting identity verification',
              warning: !c.checkedIn,
            ),
            const SizedBox(height: 16),
            const Text(
              'Compare the candidate’s ID with this record before confirming arrival.',
              style: TextStyle(color: abuMuted, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            change(
              c.checkedIn
                  ? '${c.name} check-in reversed'
                  : '${c.name} checked in',
              () => c.checkedIn = !c.checkedIn,
            );
          },
          child: Text(c.checkedIn ? 'Undo check-in' : 'Verify & check in'),
        ),
      ],
    ),
  );

  Future<void> copyAttendance() async {
    await Clipboard.setData(
      ClipboardData(
        text: [
          'Name,Registration,Department,Seat,Attendance',
          ...store.candidates.map(
            (c) => [
              c.name,
              c.number,
              c.department,
              c.seat,
              c.checkedIn ? 'Checked in' : 'Expected',
            ].map((s) => '"${s.replaceAll('"', '""')}"').join(','),
          ),
        ].join('\n'),
      ),
    );
    if (mounted) notice('Attendance register copied as CSV.');
  }

  List<Widget> hallMonitoring() => [
    stats([
      ('Workstations', '24', 'Per demo hall', Icons.desktop_windows_outlined),
      (
        'In use',
        '${store.candidates.where((c) => c.checkedIn && c.seat.startsWith(hall.substring(5))).length}',
        'Checked-in candidates',
        Icons.person_outline,
      ),
      (
        'Available',
        '${24 - store.candidates.where((c) => c.checkedIn && c.seat.startsWith(hall.substring(5))).length - (hall == 'Hall A' && !store.incidents.first.resolved ? 1 : 0)}',
        'Ready for a candidate',
        Icons.check_circle_outline,
      ),
      (
        'Needs attention',
        hall == 'Hall A' && !store.incidents.first.resolved ? '1' : '0',
        'Simulated connection status',
        Icons.wifi_off_outlined,
      ),
    ]),
    const SizedBox(height: 22),
    panel(
      title: 'Hall floor plan',
      subtitle: 'Select a workstation to inspect its assignment',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              children: ['Hall A', 'Hall B', 'Hall C']
                  .map(
                    (h) => ChoiceChip(
                      label: Text(h),
                      selected: h == hall,
                      onSelected: (_) => setState(() => hall = h),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(12),
              color: abuCanvas,
              child: const Center(
                child: Text(
                  'FRONT OF HALL  ·  INVIGILATOR DESK',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: abuMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(24, (i) {
                  final seat =
                      '${hall.substring(5)}${(i + 1).toString().padLeft(2, '0')}';
                  final candidate = store.candidates
                      .where((c) => c.seat == seat)
                      .firstOrNull;
                  final issue =
                      seat == 'A12' && !store.incidents.first.resolved;
                  final used = candidate?.checkedIn ?? false;
                  final color = issue
                      ? const Color(0xFFAE7625)
                      : used
                      ? abuGreen
                      : abuMuted;
                  final cols = constraints.maxWidth > 620 ? 8 : 4;
                  return SizedBox(
                    width: (constraints.maxWidth - 12 * (cols - 1)) / cols,
                    child: Semantics(
                      label:
                          '$seat, ${issue
                              ? 'Disconnected'
                              : used
                              ? 'In use'
                              : 'Available'}',
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          if (candidate != null) {
                            candidateDetails(candidate);
                          } else {
                            details(
                              'Workstation $seat',
                              issue
                                  ? 'Connection interrupted.\nAn open incident has been logged for this workstation. Resolve it from the Incidents page to restore the simulated connection.'
                                  : 'Status: Available\nHall: $hall\nNo candidate is assigned to this workstation.',
                            );
                          }
                        },
                        child: Container(
                          height: 85,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.07),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                issue
                                    ? Icons.wifi_off
                                    : Icons.desktop_windows_outlined,
                                color: color,
                                size: 24,
                              ),
                              const SizedBox(height: 9),
                              Text(
                                seat,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                badge('In use'),
                badge('Needs attention', warning: true),
                const Text(
                  'Outlined seats are available',
                  style: TextStyle(color: abuMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ];

  List<Widget> results() => [
    if (page == 'Results') ...[
      panel(
        title: 'Result publication',
        subtitle: 'Sample assessment results · COS 301',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: Wrap(
            spacing: 20,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              badge(
                store.showResults
                    ? 'Published to student view'
                    : 'Awaiting publication',
                warning: !store.showResults,
              ),
              FilledButton(
                onPressed: () => change(
                  store.showResults
                      ? 'Results unpublished'
                      : 'Results published to student view',
                  () => store.showResults = !store.showResults,
                ),
                child: Text(
                  store.showResults
                      ? 'Unpublish results'
                      : 'Publish demo results',
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 22),
    ],
    if (page == 'My results' && !store.showResults)
      panel(
        child: const Padding(
          padding: EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.lock_clock_outlined, color: abuGreen, size: 44),
              SizedBox(height: 20),
              Text(
                'Your results are awaiting publication',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
              ),
              SizedBox(height: 12),
              Text(
                'Results will appear here after the examination office releases them.',
                textAlign: TextAlign.center,
                style: TextStyle(color: abuMuted),
              ),
            ],
          ),
        ),
      )
    else
      panel(
        title: page == 'My results'
            ? 'Published results'
            : 'Assessment register',
        subtitle:
            'Illustrative scores for UI demonstration; separate from the practice exam.',
        child: table(
          ['Candidate', 'Course', 'Score', 'Grade', 'Status'],
          (page == 'My results'
                  ? store.candidates
                        .take(4)
                        .where(
                          (c) =>
                              c.number == DemoAuth.instance.account?.username,
                        )
                  : store.candidates.take(4))
              .toList()
              .asMap()
              .entries
              .map(
                (entry) => [
                  cell(entry.value.name, entry.value.number),
                  cell('COS 301'),
                  cell(
                    '${[82, 74, 68, 91][store.candidates.indexOf(entry.value)]} / 100',
                  ),
                  cell(
                    ['A', 'A', 'B', 'A'][store.candidates.indexOf(entry.value)],
                  ),
                  badge(
                    store.showResults ? 'Published' : 'Reviewed',
                    warning: !store.showResults,
                  ),
                ],
              )
              .toList(),
        ),
      ),
  ];

  List<Widget> incidents() => [
    panel(
      title: 'Incident register',
      subtitle: 'A shared record for the examination team',
      child: Column(
        children: [
          toolbar('Search incidents', ['All', 'Open', 'Resolved']),
          table(
            ['Incident', 'Location', 'Priority', 'Status', ''],
            store.incidents
                .where(
                  (i) =>
                      '${i.title} ${i.location}'.toLowerCase().contains(
                        query,
                      ) &&
                      (filter == 'All' ||
                          (i.resolved ? 'Resolved' : 'Open') == filter),
                )
                .map(
                  (i) => [
                    SizedBox(
                      width: 310,
                      child: Text(
                        i.title,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    cell(i.location),
                    badge(i.severity, warning: i.severity == 'High'),
                    badge(
                      i.resolved ? 'Resolved' : 'Open',
                      warning: !i.resolved,
                    ),
                    TextButton(
                      onPressed: () => change(
                        i.resolved ? 'Incident reopened' : 'Incident resolved',
                        () => i.resolved = !i.resolved,
                      ),
                      child: Text(i.resolved ? 'Reopen' : 'Resolve'),
                    ),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    ),
  ];

  Future<void> incidentForm() async {
    final v = await form('Report an incident', [
      'Description',
      'Hall / seat',
      'Priority (Low, Medium or High)',
    ]);
    if (v == null || !mounted) return;
    final severity = [
      'Low',
      'Medium',
      'High',
    ].where((s) => s.toLowerCase() == v[2].toLowerCase()).firstOrNull;
    if (severity == null) {
      notice('Use Low, Medium or High for priority. Incident not saved.');
      return;
    }
    change(
      'Incident reported',
      () => store.incidents.add(DemoIncident(v[0], v[1], severity)),
    );
  }

  List<Widget> settings() => [
    panel(
      title: 'Examination preferences',
      subtitle: 'Demo preferences apply immediately within this workspace.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Academic session'),
              subtitle: const Text(
                '2026 / 2027 · Ahmadu Bello University, Zaria',
              ),
              trailing: badge('Demo'),
            ),
            const Divider(),
            DropdownButtonFormField<String>(
              initialValue: store.semester,
              decoration: const InputDecoration(labelText: 'Semester'),
              items: [
                'First semester',
                'Second semester',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) =>
                  change('Semester updated', () => store.semester = v!),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Randomise practice questions'),
              subtitle: const Text(
                'Shuffle the question order when opening a new practice exam.',
              ),
              value: store.shuffle,
              onChanged: (v) => change(
                'Question order preference updated',
                () => store.shuffle = v,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Publish demo results'),
              subtitle: const Text(
                'Make sample scores visible in the student account.',
              ),
              value: store.showResults,
              onChanged: (v) => change(
                'Result visibility updated',
                () => store.showResults = v,
              ),
            ),
          ],
        ),
      ),
    ),
  ];

  List<Widget> student() {
    final candidate = DemoAuth.instance.student!.candidate;
    final exams = DemoAuth.instance.student!.exams;
    return [
      panel(
        title: candidate.fullName,
        subtitle: candidate.registrationNumber,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: Text(
            '${candidate.department} ? ${candidate.level} ? ${candidate.programme}',
            style: const TextStyle(color: abuMuted),
          ),
        ),
      ),
      const SizedBox(height: 24),
      panel(
        title: 'Practice examination',
        subtitle: 'Prepare with your own course schedule.',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your practice centre',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
              ),
              const SizedBox(height: 12),
              const Text(
                'Read the instructions, confirm your identity and practise answering questions.',
                style: TextStyle(color: abuMuted),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: openPractice,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Open practice examination'),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      panel(
        title: 'My timetable',
        subtitle: 'Examinations assigned to your demo account',
        child: table(
          ['Examination', 'Time', 'Venue'],
          exams
              .map(
                (e) => [
                  cell(e.courseTitle, e.courseCode),
                  cell(e.startTime),
                  cell(e.venue),
                ],
              )
              .toList(),
        ),
      ),
    ];
  }

  Future<void> openPractice() async {
    if (DemoAuth.instance.student == null) return;
    final controller = Get.isRegistered<CenterExamPortalController>()
        ? Get.find<CenterExamPortalController>()
        : Get.put(CenterExamPortalController(), permanent: true);
    if (controller.candidate.value == null) {
      await controller.loadCandidateSession(
        DemoAuth.instance.student!,
        persist: false,
      );
    }
    Get.toNamed(Routes.centerPortal);
  }

  List<Widget> help() => [
    panel(
      title: 'A quick guide to the demo',
      child: Column(
        children: [
          for (final item in [
            (
              'Administrator walkthrough',
              'Create an examination draft, publish its schedule and start a session. Add questions and approve them in the question bank. Publish sample results to see them in the student account.',
            ),
            (
              'Invigilator walkthrough',
              'Open Attendance, search for a candidate and verify their identity. Checked-in candidates appear in the hall floor plan. Report an incident and resolve it from the incident register.',
            ),
            (
              'Student walkthrough',
              'Sign in with your student registration number. Open the practice examination, read the instructions and confirm your identity. Use the question navigator to review answers before submitting.',
            ),
            (
              'About the demo data',
              'All names, schedules, statistics and results are demonstration records. Workspace changes remain while the app is open and reset after restarting. The practice player is separate from the administration sample timetable.',
            ),
          ])
            ExpansionTile(
              title: Text(
                item.$1,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$2,
                  style: const TextStyle(height: 1.8, color: abuMuted),
                ),
              ],
            ),
        ],
      ),
    ),
  ];
}
