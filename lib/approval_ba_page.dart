// import 'package:flutter/material.dart';
// import 'package:management_event/badismantle/list_ba_dismantle.dart';

// class ApprovalBAPage extends StatelessWidget {
//   const ApprovalBAPage({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [Colors.green[700]!, Colors.green[900]!],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: const Icon(
//                         Icons.assignment_turned_in_rounded,
//                         size: 60,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     const Text(
//                       'Approval Berita Acara',
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Pilih jenis BA yang ingin di-approve',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.white.withOpacity(0.9),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: Container(
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(30),
//                       topRight: Radius.circular(30),
//                     ),
//                   ),
//                   child: ListView(
//                     padding: const EdgeInsets.all(20),
//                     children: [
//                       _buildBACard(
//                         context,
//                         icon: Icons.build_circle_outlined,
//                         title: 'BA Dismantle',
//                         subtitle: 'Approve pembongkaran sarana prasarana',
//                         color: Colors.blue,
//                         pendingCount: 2,
//                         isEnabled: true,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const BADismantleListPage(role: 'approver'),
//                             ),
//                           );
//                         },
//                       ),
//                       _buildBACard(
//                         context,
//                         icon: Icons.calendar_today_rounded,
//                         title: 'BA Harian',
//                         subtitle: 'Segera hadir',
//                         color: Colors.green,
//                         pendingCount: 0,
//                         isEnabled: false,
//                         onTap: () {},
//                       ),
//                       _buildBACard(
//                         context,
//                         icon: Icons.swap_horiz_rounded,
//                         title: 'BA Perubahan Volume',
//                         subtitle: 'Segera hadir',
//                         color: Colors.orange,
//                         pendingCount: 0,
//                         isEnabled: false,
//                         onTap: () {},
//                       ),
//                       _buildBACard(
//                         context,
//                         icon: Icons.add_box_outlined,
//                         title: 'BA Penambahan Volume di Luar Kontrak',
//                         subtitle: 'Segera hadir',
//                         color: Colors.purple,
//                         pendingCount: 0,
//                         isEnabled: false,
//                         onTap: () {},
//                       ),
//                       _buildBACard(
//                         context,
//                         icon: Icons.verified_outlined,
//                         title: 'BA Uji Fungsi',
//                         subtitle: 'Segera hadir',
//                         color: Colors.teal,
//                         pendingCount: 0,
//                         isEnabled: false,
//                         onTap: () {},
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBACard(
//     BuildContext context, {
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required Color color,
//     required int pendingCount,
//     required bool isEnabled,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: isEnabled ? onTap : null,
//           borderRadius: BorderRadius.circular(16),
//           child: Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: isEnabled ? Colors.white : Colors.grey[100],
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: (isEnabled ? color : Colors.grey).withOpacity(0.2),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//               border: Border.all(
//                 color: (isEnabled ? color : Colors.grey).withOpacity(0.3),
//                 width: 1,
//               ),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: (isEnabled ? color : Colors.grey).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(
//                     icon,
//                     color: isEnabled ? color : Colors.grey[400],
//                     size: 28,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         title,
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 15,
//                           color: isEnabled ? Colors.black : Colors.grey[500],
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         subtitle,
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: isEnabled ? Colors.grey[600] : Colors.grey[400],
//                         ),
//                       ),
//                       if (pendingCount > 0 && isEnabled) ...[
//                         const SizedBox(height: 6),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                           decoration: BoxDecoration(
//                             color: Colors.red.shade50,
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(
//                             '$pendingCount pending',
//                             style: TextStyle(
//                               fontSize: 11,
//                               color: Colors.red.shade600,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//                 Icon(
//                   Icons.arrow_forward_ios,
//                   size: 16,
//                   color: isEnabled ? color : Colors.grey[300],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }