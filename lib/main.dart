// import 'package:chatapp/ChatAssistantScreen.dart';
// import 'package:chatapp/account_screen.dart';
// import 'package:chatapp/auth_screen.dart';
// import 'package:chatapp/auth_service.dart';
// import 'package:chatapp/firebase_options.dart';
// import 'package:chatapp/reports_screen_fixed.dart';
// import 'package:chatapp/transactions_screen.dart';
// import 'package:chatapp/tax_profile_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:curved_navigation_bar/curved_navigation_bar.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const ChatExpenseApp());
// }

// class ChatExpenseApp extends StatelessWidget {
//   const ChatExpenseApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         Provider<AuthService>(create: (_) => AuthService()),
//         StreamProvider<User?>.value(
//           value: FirebaseAuth.instance.authStateChanges(),
//           initialData: null,
//         ),
//       ],
//       child: MaterialApp(
//         title: 'ChatExpense',
//         theme: ThemeData(
//           primarySwatch: Colors.teal,
//           scaffoldBackgroundColor: Colors.grey[100],
//           appBarTheme: const AppBarTheme(
//             backgroundColor: Colors.teal,
//             foregroundColor: Colors.white,
//             elevation: 2,
//           ),
//           elevatedButtonTheme: ElevatedButtonThemeData(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.teal,
//               foregroundColor: Colors.white,
//             ),
//           ),
//         ),
//         home: const AuthWrapper(),
//         debugShowCheckedModeBanner: false,
//       ),
//     );
//   }
// }

// class AuthWrapper extends StatelessWidget {
//   const AuthWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final user = context.watch<User?>();
    
//     // Update last active when user is authenticated
//     if (user != null) {
//       context.read<AuthService>().updateLastActive();
//     }
    
//     return user != null ? const MainNavigation() : const AuthScreen();
//   }
// }

// class MainNavigation extends StatefulWidget {
//   const MainNavigation({super.key});

//   @override
//   State<MainNavigation> createState() => _MainNavigationState();
// }

// class _MainNavigationState extends State<MainNavigation> with SingleTickerProviderStateMixin {
//   int _selectedIndex = 0;
//   late AnimationController _drawerController;
//   bool _isDrawerOpen = false;

//   // Navigation items with Assistant in center (index 2)
//   final List<Widget> _screens = [
//     const TransactionsScreen(),    // 0
//     const ReportsScreen(),         // 1
//     const ChatAssistantScreen(),   // 2 - Center
//     const EnhancedAccountScreen(), // 3
//     const TaxProfileScreen(),      // 4
//   ];

//   final List<IconData> _navigationIcons = [
//     Icons.receipt_long,     // Transactions
//     Icons.bar_chart,        // Reports
//     Icons.smart_toy,        // AI Assistant (Center)
//     Icons.person,           // Account
//     Icons.description,      // Tax Profile
//   ];

//   final List<String> _navigationLabels = [
//     'Transactions',
//     'Reports',
//     'AI Assistant',
//     'Account',
//     'Tax Profile',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _drawerController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//   }

//   @override
//   void dispose() {
//     _drawerController.dispose();
//     super.dispose();
//   }

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//       // Close drawer if open when switching tabs
//       if (_isDrawerOpen) {
//         _toggleDrawer();
//       }
//     });
//   }

//   Color _getIconColor(int index) {
//     switch (index) {
//       case 0: return Colors.green;
//       case 1: return Colors.red;
//       case 2: return Colors.white; // AI Assistant - white on teal background
//       case 3: return Colors.orange;
//       case 4: return Colors.purple;
//       default: return Colors.teal;
//     }
//   }

//   void _toggleDrawer() {
//     setState(() {
//       _isDrawerOpen = !_isDrawerOpen;
//       _isDrawerOpen
//           ? _drawerController.forward()
//           : _drawerController.reverse();
//     });
//   }

//   // ANIMATED DRAWER WIDGET
//   Widget _buildAnimatedDrawer() {
//     final user = FirebaseAuth.instance.currentUser;
//     final double maxWidth = MediaQuery.of(context).size.width * 0.75;
    
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       width: _isDrawerOpen ? maxWidth : 0,
//       curve: Curves.easeOut,
//       child: Drawer(
//         elevation: 10,
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             if (constraints.maxWidth < 10.0) {
//               return const SizedBox.shrink(); 
//             }
            
//             return Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [Colors.teal.shade700, Colors.teal.shade300],
//                 ),
//               ),
//               child: ListView(
//                 padding: EdgeInsets.zero,
//                 children: [
//                   Container(
//                     height: 160,
//                     decoration: BoxDecoration(
//                       color: Colors.teal.shade800,
//                       borderRadius: const BorderRadius.only(
//                         bottomRight: Radius.circular(20),
//                       ),
//                     ),
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         CircleAvatar(
//                           radius: 30,
//                           backgroundImage: user?.photoURL != null 
//                               ? NetworkImage(user!.photoURL!) 
//                               : null,
//                           child: user?.photoURL == null
//                               ? const Icon(Icons.person, size: 30, color: Colors.white)
//                               : null,
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           user?.displayName ?? 'Guest User',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 5),
//                         Text(
//                           user?.email ?? '',
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.8),
//                             fontSize: 14,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                     ),
//                   ),
//                   _buildDrawerItem(icon: Icons.share, title: "Share App", onTap: () {
//                     Share.share('Check out this awesome expense tracker app!');
//                     _toggleDrawer();
//                   }),
//                   _buildDrawerItem(icon: Icons.info, title: "About Us", onTap: () {
//                     _showAboutDialog();
//                     _toggleDrawer();
//                   }),
//                   _buildDrawerItem(icon: Icons.star, title: "Rate App", onTap: () {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Thank you for your interest! Rating feature coming soon.')),
//                     );
//                     _toggleDrawer();
//                   }),
//                   _buildDrawerItem(icon: Icons.help, title: "Help & Support", onTap: () {
//                     _showHelpDialog();
//                     _toggleDrawer();
//                   }),
//                   _buildDrawerItem(icon: Icons.settings, title: "Settings", onTap: () {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Settings feature coming soon!')),
//                     );
//                     _toggleDrawer();
//                   }),
//                   const Divider(color: Colors.white54, height: 20, indent: 16, endIndent: 16),
//                   _buildDrawerItem(icon: Icons.exit_to_app, title: "Sign Out", onTap: () {
//                     _signOut();
//                     _toggleDrawer();
//                   }),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   void _showAboutDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('About ChatExpense'),
//         content: const Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('ChatExpense - AI-Powered Financial Management'),
//             SizedBox(height: 10),
//             Text('Version: 1.0.0'),
//             SizedBox(height: 10),
//             Text('A comprehensive financial tracking app with AI assistance, tax calculations, and detailed reporting for Bangladesh.'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showHelpDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Help & Support'),
//         content: const Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('How to use ChatExpense:'),
//             SizedBox(height: 10),
//             Text('1. Add transactions manually or use voice/image'),
//             Text('2. View detailed reports and analytics'),
//             Text('3. Set up your tax profile for calculations'),
//             Text('4. Chat with AI assistant for financial advice'),
//             SizedBox(height: 10),
//             Text('For more help, contact support@chatexpense.com'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _signOut() async {
//     try {
//       await context.read<AuthService>().signOut();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Sign out failed: ${e.toString()}')),
//       );
//     }
//   }

//   Widget _buildDrawerItem({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//     Color iconColor = Colors.white70,
//     Color textColor = Colors.white,
//   }) {
//     return ListTile(
//       leading: Icon(
//         icon,
//         color: iconColor,
//       ),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: textColor,
//           fontSize: 16,
//         ),
//       ),
//       onTap: onTap,
//       splashColor: Colors.teal.shade700,
//     );
//   }
  
//   String _getAppBarTitle(int index) {
//     if (index >= 0 && index < _navigationLabels.length) {
//       return _navigationLabels[index];
//     }
//     return 'ChatExpense';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         if (_isDrawerOpen) {
//           _toggleDrawer();
//           return false;
//         }
//         return true;
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(_getAppBarTitle(_selectedIndex)),
//           leading: IconButton(
//             icon: AnimatedIcon(
//               icon: AnimatedIcons.menu_arrow,
//               progress: _drawerController,
//               color: Colors.white,
//             ),
//             onPressed: _toggleDrawer,
//           ),
//           actions: [
//             // Show user email in app bar
//             Padding(
//               padding: const EdgeInsets.only(right: 16.0),
//               child: Center(
//                 child: Text(
//                   FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? '',
//                   style: const TextStyle(fontSize: 12),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         body: Stack(
//           children: [
//             IndexedStack(
//               index: _selectedIndex,
//               children: _screens,
//             ),
//             _buildAnimatedDrawer(),
//           ],
//         ),
//         bottomNavigationBar: CurvedNavigationBar(
//           index: _selectedIndex,
//           height: 60,
//           items: _navigationIcons.asMap().entries.map((entry) {
//             int index = entry.key;
//             IconData icon = entry.value;
            
//             return Container(
//               padding: const EdgeInsets.all(8),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     icon,
//                     size: index == 2 ? 28 : 24, // Larger icon for AI Assistant
//                     color: _getIconColor(index),
//                   ),
//                   if (index == 2) // Add a small badge for AI Assistant
//                     Container(
//                       margin: const EdgeInsets.only(top: 2),
//                       width: 6,
//                       height: 6,
//                       decoration: const BoxDecoration(
//                         color: Colors.lightGreenAccent,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                 ],
//               ),
//             );
//           }).toList(),
//           color: Colors.white,
//           buttonBackgroundColor: Colors.teal,
//           backgroundColor: Colors.transparent,
//           animationCurve: Curves.easeInOut,
//           animationDuration: const Duration(milliseconds: 300),
//           onTap: _onItemTapped,
//           letIndexChange: (index) => true,
//         ),
//       ),
//     );
//   }
// }


// import 'package:chatapp/ChatAssistantScreen.dart';
// import 'package:chatapp/account_screen.dart';
// import 'package:chatapp/auth_screen.dart';
// import 'package:chatapp/auth_service.dart';
// import 'package:chatapp/firebase_options.dart';
// import 'package:chatapp/reports_screen_fixed.dart';
// import 'package:chatapp/transactions_screen.dart';
// import 'package:chatapp/tax_profile_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:curved_navigation_bar/curved_navigation_bar.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const ChatExpenseApp());
// }

// class ChatExpenseApp extends StatelessWidget {
//   const ChatExpenseApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         Provider<AuthService>(create: (_) => AuthService()),
//         StreamProvider<User?>.value(
//           value: FirebaseAuth.instance.authStateChanges(),
//           initialData: null,
//         ),
//       ],
//       child: MaterialApp(
//         title: 'ChatExpense',
//         theme: ThemeData(
//           primarySwatch: Colors.teal,
//           scaffoldBackgroundColor: Colors.grey[100],
//           appBarTheme: const AppBarTheme(
//             backgroundColor: Colors.teal,
//             foregroundColor: Colors.white,
//             elevation: 2,
//           ),
//           elevatedButtonTheme: ElevatedButtonThemeData(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.teal,
//               foregroundColor: Colors.white,
//             ),
//           ),
//         ),
//         home: const AuthWrapper(),
//         debugShowCheckedModeBanner: false,
//       ),
//     );
//   }
// }

// class AuthWrapper extends StatelessWidget {
//   const AuthWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final user = context.watch<User?>();

//     if (user != null) {
//       context.read<AuthService>().updateLastActive();
//     }

//     return user != null ? const MainNavigation() : const AuthScreen();
//   }
// }

// class MainNavigation extends StatefulWidget {
//   const MainNavigation({super.key});

//   @override
//   State<MainNavigation> createState() => _MainNavigationState();
// }

// class _MainNavigationState extends State<MainNavigation> with SingleTickerProviderStateMixin {
//   int _selectedIndex = 0;

//   final List<Widget> _screens = [
//     const TransactionsScreen(),    // 0
//     const ReportsScreen(),         // 1
//     const ChatAssistantScreen(),   // 2
//     const EnhancedAccountScreen(), // 3
//     const TaxProfileScreen(),      // 4
//     Container(),                   // 5 (placeholder for logout)
//   ];

//   final List<IconData> _navigationIcons = [
//     Icons.receipt_long,
//     Icons.bar_chart,
//     Icons.smart_toy,
//     Icons.person,
//     Icons.description,
//     Icons.logout, // Logout icon
//   ];

//   final List<String> _navigationLabels = [
//     'Transactions',
//     'Reports',
//     'AI Assistant',
//     'Account',
//     'Tax Profile',
//     'Logout',
//   ];

//   void _onItemTapped(int index) {
//     if (index == 5) {
//       _signOut();
//       return;
//     }
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   Color _getIconColor(int index) {
//     switch (index) {
//       case 0:
//         return Colors.green;
//       case 1:
//         return Colors.red;
//       case 2:
//         return Colors.white;
//       case 3:
//         return Colors.orange;
//       case 4:
//         return Colors.purple;
//       case 5:
//         return Colors.black;
//       default:
//         return Colors.teal;
//     }
//   }

//   void _signOut() async {
//     try {
//       await context.read<AuthService>().signOut();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Sign out failed: ${e.toString()}')),
//       );
//     }
//   }

//   String _getAppBarTitle(int index) {
//     if (index >= 0 && index < _navigationLabels.length - 1) {
//       return _navigationLabels[index];
//     }
//     return 'ChatExpense';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async => true,
//       child: Scaffold(
//         // appBar: AppBar(
//         //   title: Text(_getAppBarTitle(_selectedIndex)),
//         //   // Drawer toggle removed
//         //   leading: null,
//         //   actions: [
//         //     Padding(
//         //       padding: const EdgeInsets.only(right: 16.0),
//         //       child: Center(
//         //         child: Text(
//         //           FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? '',
//         //           style: const TextStyle(fontSize: 12),
//         //           overflow: TextOverflow.ellipsis,
//         //         ),
//         //       ),
//         //     ),
//         //   ],
//         // ),
//         body: IndexedStack(
//           index: _selectedIndex,
//           children: _screens,
//         ),
//         bottomNavigationBar: CurvedNavigationBar(
//           index: _selectedIndex,
//           height: 60,
//           items: _navigationIcons.asMap().entries.map((entry) {
//             int index = entry.key;
//             IconData icon = entry.value;

//             return Container(
//               padding: const EdgeInsets.all(8),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     icon,
//                     size: index == 2 ? 28 : 24,
//                     color: _getIconColor(index),
//                   ),
//                   if (index == 2)
//                     Container(
//                       margin: const EdgeInsets.only(top: 2),
//                       width: 6,
//                       height: 6,
//                       decoration: const BoxDecoration(
//                         color: Colors.lightGreenAccent,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                 ],
//               ),
//             );
//           }).toList(),
//           color: Colors.white,
//           buttonBackgroundColor: Colors.teal,
//           backgroundColor: Colors.transparent,
//           animationCurve: Curves.easeInOut,
//           animationDuration: const Duration(milliseconds: 300),
//           onTap: _onItemTapped,
//           letIndexChange: (index) => true,
//         ),
//       ),
//     );
//   }
// }


import 'package:chatapp/ChatAssistantScreen.dart';
import 'package:chatapp/account_screen.dart';
import 'package:chatapp/auth_screen.dart';
import 'package:chatapp/auth_service.dart';
import 'package:chatapp/firebase_options.dart';
import 'package:chatapp/reports_screen_fixed.dart';
import 'package:chatapp/transactions_screen.dart';
import 'package:chatapp/tax_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ChatExpenseApp());
}

class ChatExpenseApp extends StatelessWidget {
  const ChatExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'ChatExpense',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: Colors.grey[100],
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    if (user != null) {
      context.read<AuthService>().updateLastActive();
    }

    return user != null ? const MainNavigation() : const AuthScreen();
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TransactionsScreen(),
    const ReportsScreen(),
    const ChatAssistantScreen(),
    const EnhancedAccountScreen(),
    const TaxProfileScreen(),
    const Center(child: Text('Logging out...')), // Logout placeholder
  ];

  final List<IconData> _navigationIcons = [
    Icons.receipt_long,
    Icons.bar_chart,
    Icons.smart_toy,
    Icons.person,
    Icons.description,
    Icons.logout, // "Others" or Logout
  ];

  void _onItemTapped(int index) {
    if (index == 5) {
      _signOut();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Color _getIconColor(int index) {
    switch (index) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.red;
      case 2:
        return Color.fromARGB(255, 17, 5, 190);
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.black;
      default:
        return Colors.teal;
    }
  }

  void _signOut() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // UX delay
      await context.read<AuthService>().signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: CurvedNavigationBar(
          index: _selectedIndex,
          height: 60,
          items: _navigationIcons.asMap().entries.map((entry) {
            int index = entry.key;
            IconData icon = entry.value;

            return Icon(
              icon,
              size: index == 2 ? 28 : 24,
              color: _getIconColor(index),
            );
          }).toList(),
          color: Colors.white,
          buttonBackgroundColor: Colors.teal,
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 300),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
