import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:math';

// ─────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const EasyLoanApp());
}

// ─────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────
const kBlue       = Color(0xFF1565C0);
const kBlueDark   = Color(0xFF0D47A1);
const kBlueLight  = Color(0xFFE3F2FD);
const kGreen      = Color(0xFF2E7D32);
const kGreenLight = Color(0xFFE8F5E9);
const kRed        = Color(0xFFC62828);
const kRedLight   = Color(0xFFFFEBEE);
const kOrange     = Color(0xFFE65100);
const kGrey       = Color(0xFF757575);
const kGreyLight  = Color(0xFFF5F5F5);
const kTextDark   = Color(0xFF1A1A1A);
const kTextMid    = Color(0xFF555555);
const kFont       = 'sans-serif';

// Loan amounts & rules
const List<int> kAmounts = [100,200,300,400,500,600,700,800,900,1000,1500,2000];
const int kTenure   = 15;   // days
const int kFee      = 100;  // fixed fee for regular loans

// Penalty tiers
int penaltyFor(int amount) {
  if (amount <= 100)  return 50;
  if (amount <= 500)  return 100;
  if (amount <= 1000) return 200;
  if (amount <= 1500) return 250;
  return 300;
}

// Unlock tiers
bool isUnlocked(int amount, int onTimeCount) {
  if (amount <= 200)  return true;
  if (amount <= 1000) return onTimeCount >= 3;
  return onTimeCount >= 6;
}

String unlockLabel(int amount) {
  if (amount <= 200)  return '';
  if (amount <= 1000) return 'After 3 on-time repayments';
  return 'After 6 on-time repayments';
}

// ─────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────
class Loan {
  final String id;
  final int    amount;
  final int    returnAmount;
  final DateTime dueDate;
  final DateTime createdAt;
  String status;   // active | overdue | completed
  int    paid;
  bool   penaltyApplied;

  Loan({
    required this.id,
    required this.amount,
    required this.returnAmount,
    required this.dueDate,
    required this.createdAt,
    this.status = 'active',
    this.paid   = 0,
    this.penaltyApplied = false,
  });

  int get penalty  => penaltyApplied ? penaltyFor(amount) : 0;
  int get totalDue => returnAmount + penalty - paid;
  bool get isPaid  => totalDue <= 0;

  String get statusLabel {
    if (isPaid) return 'Completed';
    if (status == 'overdue') return 'Overdue';
    return 'Active';
  }

  Color get statusColor {
    if (isPaid)             return kGreen;
    if (status == 'overdue') return kRed;
    return kBlue;
  }

  // Simple encode/decode for SharedPreferences
  String encode() =>
      '$id|$amount|$returnAmount|${dueDate.millisecondsSinceEpoch}'
      '|${createdAt.millisecondsSinceEpoch}|$status|$paid|$penaltyApplied';

  static Loan decode(String s) {
    final p = s.split('|');
    return Loan(
      id:           p[0],
      amount:       int.parse(p[1]),
      returnAmount: int.parse(p[2]),
      dueDate:      DateTime.fromMillisecondsSinceEpoch(int.parse(p[3])),
      createdAt:    DateTime.fromMillisecondsSinceEpoch(int.parse(p[4])),
      status:       p[5],
      paid:         int.parse(p[6]),
      penaltyApplied: p[7] == 'true',
    );
  }
}

// ─────────────────────────────────────────────
//  SIMPLE STATE (InheritedNotifier pattern)
// ─────────────────────────────────────────────
class AppState extends ChangeNotifier {
  String  name        = '';
  String  phone       = '';
  bool    kycDone     = false;
  List<Loan> loans    = [];
  int     onTimeCount = 0;

  // Derived
  Loan?   get activeLoan => loans.where((l) => !l.isPaid).isEmpty
      ? null
      : loans.firstWhere((l) => !l.isPaid);

  bool get hasActiveLoan => activeLoan != null;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    name        = p.getString('name')       ?? '';
    phone       = p.getString('phone')      ?? '';
    kycDone     = p.getBool('kycDone')      ?? false;
    onTimeCount = p.getInt('onTimeCount')   ?? 0;
    final raw   = p.getStringList('loans')  ?? [];
    loans       = raw.map(Loan.decode).toList();
    _checkOverdue();
    notifyListeners();
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('name',   name);
    await p.setString('phone',  phone);
    await p.setBool('kycDone',  kycDone);
    await p.setInt('onTimeCount', onTimeCount);
    await p.setStringList('loans', loans.map((l) => l.encode()).toList());
  }

  void _checkOverdue() {
    final now = DateTime.now();
    for (final l in loans) {
      if (!l.isPaid && l.status == 'active' && now.isAfter(l.dueDate)) {
        l.status = 'overdue';
        if (!l.penaltyApplied) l.penaltyApplied = true;
      }
    }
  }

  Future<Loan> applyLoan(int amount) async {
    final loan = Loan(
      id:           'LOAN${Random().nextInt(99999).toString().padLeft(5,'0')}',
      amount:       amount,
      returnAmount: amount + kFee,
      dueDate:      DateTime.now().add(const Duration(days: kTenure)),
      createdAt:    DateTime.now(),
    );
    loans.insert(0, loan);
    await save();
    notifyListeners();
    return loan;
  }

  Future<void> makePayment(String loanId, int amount) async {
    final loan = loans.firstWhere((l) => l.id == loanId);
    loan.paid += amount;
    if (loan.isPaid) {
      loan.status = 'completed';
      final wasOnTime = DateTime.now().isBefore(loan.dueDate.add(const Duration(days:1)));
      if (wasOnTime) {
        onTimeCount++;
      }
    }
    await save();
    notifyListeners();
  }

  Future<void> completeKYC({required String n, required String ph}) async {
    name    = n;
    phone   = ph;
    kycDone = true;
    await save();
    notifyListeners();
  }

  Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    name = ''; phone = ''; kycDone = false;
    loans = []; onTimeCount = 0;
    notifyListeners();
  }
}

// ─────────────────────────────────────────────
//  APP ROOT
// ─────────────────────────────────────────────
class EasyLoanApp extends StatefulWidget {
  const EasyLoanApp({super.key});
  @override
  State<EasyLoanApp> createState() => _EasyLoanAppState();
}

class _EasyLoanAppState extends State<EasyLoanApp> {
  final _state = AppState();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _state.load().then((_) => setState(() => _ready = true));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (ctx, _) => MaterialApp(
        title:                  'EasyLoan',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: kBlue),
          fontFamily:  kFont,
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor:    kBlue,
            foregroundColor:    Colors.white,
            elevation:          0,
            centerTitle:        false,
            titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.w700, fontFamily: kFont,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor:  kBlue,
              foregroundColor:  Colors.white,
              minimumSize:      const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled:    true,
            fillColor: kGreyLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kRed, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kRed, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14,
            ),
          ),
        ),
        home: !_ready
            ? const _SplashScreen()
            : _state.kycDone
                ? MainShell(state: _state)
                : KYCScreen(state: _state),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SPLASH
// ─────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: kBlue,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.currency_rupee, size: 72, color: Colors.white),
          SizedBox(height: 16),
          Text('EasyLoan', style: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w800,
            color: Colors.white, letterSpacing: -0.5,
          )),
          SizedBox(height: 8),
          Text('Fast Loans, Easy Life', style: TextStyle(
            color: Colors.white70, fontSize: 15,
          )),
          SizedBox(height: 48),
          CircularProgressIndicator(color: Colors.white60, strokeWidth: 2),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  KYC / REGISTRATION SCREEN
// ─────────────────────────────────────────────
class KYCScreen extends StatefulWidget {
  final AppState state;
  const KYCScreen({super.key, required this.state});
  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  int  _step    = 0; // 0=name+phone, 1=review

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    // Simulate a brief "verification"
    await Future.delayed(const Duration(milliseconds: 1200));
    await widget.state.completeKYC(
      n:  _nameCtrl.text.trim(),
      ph: _phoneCtrl.text.trim(),
    );
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => MainShell(state: widget.state)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Logo bar
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: kBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.currency_rupee,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                const Text('EasyLoan', style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: kBlue,
                )),
              ]),
              const SizedBox(height: 36),
              const Text('Create your account', style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w700, color: kTextDark,
                height: 1.2,
              )),
              const SizedBox(height: 8),
              const Text('Fill in details to get instant loans up to ₹2000',
                style: TextStyle(fontSize: 14, color: kTextMid)),
              const SizedBox(height: 32),
              // Features row
              Row(children: [
                _FeaturePill(Icons.bolt, 'Instant'),
                const SizedBox(width: 8),
                _FeaturePill(Icons.lock_outline, 'Secure'),
                const SizedBox(width: 8),
                _FeaturePill(Icons.thumb_up_outlined, 'Easy'),
              ]),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(children: [
                  _LabelField(
                    label: 'Full Name',
                    child: TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 3)
                          return 'Enter your full name (min 3 chars)';
                        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v.trim()))
                          return 'Name can only contain letters';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LabelField(
                    label: 'Mobile Number',
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        hintText: '10-digit mobile number',
                        prefixIcon: Icon(Icons.phone_android),
                        prefixText: '+91  ',
                        counterText: '',
                      ),
                      validator: (v) {
                        if (v == null || v.length != 10)
                          return 'Enter valid 10-digit number';
                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v))
                          return 'Must start with 6, 7, 8 or 9';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  _loading
                      ? const _LoadingBtn(label: 'Verifying...')
                      : ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Create Account & Continue'),
                        ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'By continuing you agree to our Terms & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: kGrey),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MAIN SHELL (Bottom Navigation)
// ─────────────────────────────────────────────
class MainShell extends StatefulWidget {
  final AppState state;
  const MainShell({super.key, required this.state});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(state: widget.state),
      LoansTab(state: widget.state),
      ProfileTab(state: widget.state),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'My Loans',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HOME TAB
// ─────────────────────────────────────────────
class HomeTab extends StatelessWidget {
  final AppState state;
  const HomeTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final active = state.activeLoan;
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Blue header
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: kBlue,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kBlue, kBlueDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.currency_rupee,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 6),
                      const Text('EasyLoan', style: TextStyle(
                        color: Colors.white,
                        fontSize: 18, fontWeight: FontWeight.w700,
                      )),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${state.onTimeCount} ✓',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Text('Hello, ${state.name.split(' ').first} 👋',
                      style: const TextStyle(
                        col
