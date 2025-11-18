import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Message Boards',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color.fromARGB(255, 52, 122, 179),
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const Splash(),
    );
  }
}


class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RootGate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white,
                child: Icon(Icons.forum, size: 40, color: Color.fromARGB(255, 42, 124, 207)),
              ),
              SizedBox(height: 16),
              Text(
                'Chatboards',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Homework 2',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class RootGate extends StatelessWidget {
  const RootGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.active) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final u = snap.data;
        return u == null ? const AuthScreen() : const BoardsHome();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final rFn = TextEditingController();
  final rLn = TextEditingController();
  final rRole = TextEditingController();
  final rEmail = TextEditingController();
  final rPass = TextEditingController();

  final lEmail = TextEditingController();
  final lPass = TextEditingController();

  @override
  void dispose() {
    rFn.dispose(); rLn.dispose(); rRole.dispose(); rEmail.dispose(); rPass.dispose();
    lEmail.dispose(); lPass.dispose();
    super.dispose();
  }

  Future<void> doRegister() async {
    final email = rEmail.text.trim();
    final pass = rPass.text;
    if (email.isEmpty || pass.length < 6) {
      msg('use a valid email and 6+ character password');
      return;
    }
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, password: pass,
      );
      final uid = cred.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'firstName': rFn.text.trim(),
        'lastName': rLn.text.trim(),
        'role': rRole.text.trim().isEmpty ? 'student' : rRole.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'uid': uid,
      });
      msg('registered $email');
    } on FirebaseAuthException catch (e) {
      msg(e.message ?? 'registration failed');
    }
  }

  Future<void> doLogin() async {
    final email = lEmail.text.trim();
    final pass = lPass.text;
    if (email.isEmpty || pass.isEmpty) {
      msg('fill email + password');
      return;
    }
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, password: pass,
      );
    } on FirebaseAuthException catch (e) {
      msg(e.message ?? 'login failed');
    }
  }

  void resetLogin() async {
    final email = lEmail.text.trim();
    if (email.isEmpty) { msg('type your email first'); return; }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    msg('reset email sent');
  }

  void msg(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: TextField(controller: rFn, decoration: const InputDecoration(labelText: 'first name'))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: rLn, decoration: const InputDecoration(labelText: 'last name'))),
                        ]),
                        const SizedBox(height: 8),
                        TextField(controller: rRole, decoration: const InputDecoration(labelText: 'role (e.g., student)')),
                        const SizedBox(height: 8),
                        TextField(controller: rEmail, decoration: const InputDecoration(labelText: 'email'), keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 8),
                        TextField(controller: rPass, decoration: const InputDecoration(labelText: 'password'), obscureText: true),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: doRegister, child: const Text('create account')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Sign in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(controller: lEmail, decoration: const InputDecoration(labelText: 'email'), keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 8),
                        TextField(controller: lPass, decoration: const InputDecoration(labelText: 'password'), obscureText: true),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: doLogin, child: const Text('sign in')),
                        TextButton(onPressed: resetLogin, child: const Text('forgot password?')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BoardsHome extends StatelessWidget {
  const BoardsHome({super.key});

  static final boards = <Board>[
    Board(
      id: 'general',
      title: 'General',
      icon: Icons.chat_bubble_outline_rounded,
    ),
    Board(
      id: 'school',
      title: 'School',
      icon: Icons.menu_book_rounded,
    ),
    Board(
      id: 'tech',
      title: 'Tech',
      icon: Icons.developer_board_rounded,
    ),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message Boards')),
      drawer: const AppDrawer(),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: boards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final b = boards[i];
          return Card(
            child: ListTile(
              leading: Icon(b.icon),
              title: Text(b.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(board: b),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class Board {
  final String id;
  final String title;
  final IconData icon;
  Board({required this.id, required this.title, required this.icon});
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(child: Center(child: Text('Menu', style: TextStyle(fontSize: 22)))),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Message Boards'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BoardsHome()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final fn = TextEditingController();
  final ln = TextEditingController();
  final role = TextEditingController();
  final dob = TextEditingController();

  @override
  void dispose() { fn.dispose(); ln.dispose(); role.dispose(); dob.dispose(); super.dispose(); }

  Future<void> load() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final d = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = d.data();
    if (data != null) {
      fn.text = (data['firstName'] ?? '').toString();
      ln.text = (data['lastName'] ?? '').toString();
      role.text = (data['role'] ?? '').toString();
      dob.text = (data['dob'] ?? '').toString();
    }
    setState(() {});
  }

  Future<void> save() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'firstName': fn.text.trim(),
      'lastName': ln.text.trim(),
      'role': role.text.trim(),
      'dob': dob.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'uid': uid,
    }, SetOptions(merge: true));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('profile saved')));
  }

  @override
  void initState() { super.initState(); load(); }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '(no email)';
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('email: $email'),
              const SizedBox(height: 12),
              TextField(controller: fn, decoration: const InputDecoration(labelText: 'first name')),
              const SizedBox(height: 8),
              TextField(controller: ln, decoration: const InputDecoration(labelText: 'last name')),
              const SizedBox(height: 8),
              TextField(controller: role, decoration: const InputDecoration(labelText: 'role')),
              const SizedBox(height: 8),
              TextField(controller: dob, decoration: const InputDecoration(labelText: 'dob (optional)')),
              const SizedBox(height: 12),
              FilledButton(onPressed: save, child: const Text('save')),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> doLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootGate()), (r) => false);
    }
  }

  Future<void> resetPassword(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('reset email sent')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '(no email)';
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('current login: $email'),
                const SizedBox(height: 12),
                FilledButton(onPressed: () => resetPassword(context), child: const Text('change password (email link)')),
                const SizedBox(height: 8),
                FilledButton.tonal(onPressed: () => doLogout(context), child: const Text('logout')),
                const SizedBox(height: 8),
                const Text('Note: changing email requires re-authorization!'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.board});
  final Board board;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final c = TextEditingController();

  Future<void> send() async {
    final txt = c.text.trim();
    if (txt.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser!;
    final udoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final name = () {
      final d = udoc.data();
      if (d == null) return user.email ?? 'user';
      final fn = (d['firstName'] ?? '').toString();
      final ln = (d['lastName'] ?? '').toString();
      final n = ('$fn $ln').trim();
      return n.isEmpty ? (user.email ?? 'user') : n;
    }();

    await FirebaseFirestore.instance
        .collection('boards')
        .doc(widget.board.id)
        .collection('messages')
        .add({
      'text': txt,
      'senderUid': user.uid,
      'senderName': name,
      'ts': FieldValue.serverTimestamp(),
    });
    c.clear();
  }

  @override
  Widget build(BuildContext context) {
    final msgs = FirebaseFirestore.instance
        .collection('boards')
        .doc(widget.board.id)
        .collection('messages')
        .orderBy('ts', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text(widget.board.title)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: msgs,
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('no messages yet'));
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final who = (d['senderName'] ?? 'user').toString();
                    final text = (d['text'] ?? '').toString();
                    final ts = (d['ts'] as Timestamp?)?.toDate();
                    final when = ts == null ? '' : '${ts.month}/${ts.day} ${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}';
                    return ListTile(
                      title: Text(text),
                      subtitle: Text('$who  •  $when'),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(child: TextField(controller: c, decoration: const InputDecoration(hintText: 'message...'))),
                const SizedBox(width: 8),
                IconButton(onPressed: send, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
