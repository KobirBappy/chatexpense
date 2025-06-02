// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:iconsax/iconsax.dart';
// import 'package:intl/intl.dart';

// class CategoriesScreen extends StatefulWidget {
//   const CategoriesScreen({super.key});

//   @override
//   State<CategoriesScreen> createState() => _CategoriesScreenState();
// }

// class _CategoriesScreenState extends State<CategoriesScreen> {
//   final _nameController = TextEditingController();
//   final _descController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   String _searchQuery = '';
//   bool _isLoading = false;
//   String? _editingCategoryId;
//   final FocusNode _nameFocusNode = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     _nameFocusNode.addListener(() {
//       if (!_nameFocusNode.hasFocus) {
//         _formKey.currentState?.validate();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _nameFocusNode.dispose();
//     super.dispose();
//   }

//   Future<void> _addCategory() async {
//     if (!_formKey.currentState!.validate()) return;
    
//     setState(() => _isLoading = true);
    
//     try {
//       final category = {
//         'name': _nameController.text.trim(),
//         'description': _descController.text.trim(),
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       };
      
//       if (_editingCategoryId != null) {
//         // Update existing category
//         await FirebaseFirestore.instance
//             .collection('categories')
//             .doc(_editingCategoryId)
//             .update(category);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Category updated successfully')),
//         );
//       } else {
//         // Add new category
//         await FirebaseFirestore.instance.collection('categories').add(category);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Category added successfully')),
//         );
//       }
      
//       _resetForm();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _deleteCategory(String id, String name) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: Text('Are you sure you want to delete "$name"? This action cannot be undone.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       setState(() => _isLoading = true);
//       try {
//         await FirebaseFirestore.instance.collection('categories').doc(id).delete();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('"$name" deleted')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Delete failed: ${e.toString()}')),
//         );
//       } finally {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   void _editCategory(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     setState(() {
//       _editingCategoryId = doc.id;
//       _nameController.text = data['name'];
//       _descController.text = data['description'] ?? '';
//     });
//     _nameFocusNode.requestFocus();
//   }

//   void _resetForm() {
//     _formKey.currentState?.reset();
//     _nameController.clear();
//     _descController.clear();
//     setState(() => _editingCategoryId = null);
//   }

//   Widget _buildCategoryCard(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     final name = data['name'];
//     final description = data['description'] ?? 'No description';
//     final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       elevation: 2,
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         leading: Container(
//           width: 44,
//           height: 44,
//           decoration: BoxDecoration(
//             color: Colors.blue.shade50,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Icon(Icons.category, color: Colors.blue.shade700),
//         ),
//         title: Text(
//           name,
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
//             const SizedBox(height: 4),
//             Text(
//               'Created: ${DateFormat.yMMMd().format(createdAt)}',
//               style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//             ),
//           ],
//         ),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             IconButton(
//               icon: const Icon(Icons.edit, size: 20),
//               onPressed: () => _editCategory(doc),
//               tooltip: 'Edit',
//             ),
//             IconButton(
//               icon: const Icon(Icons.delete, size: 20, color: Colors.red),
//               onPressed: () => _deleteCategory(doc.id, name),
//               tooltip: 'Delete',
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Manage Categories"),
//         actions: [
//           if (_editingCategoryId != null)
//             IconButton(
//               icon: const Icon(Icons.close),
//               onPressed: _resetForm,
//               tooltip: 'Cancel Edit',
//             )
//         ],
//       ),
//       body: Column(
//         children: [
//           // Search Bar
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: TextField(
//               decoration: InputDecoration(
//                 hintText: 'Search categories...',
//                 prefixIcon: const Icon(Iconsax.search_normal),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide.none,
//                 ),
//                 filled: true,
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 16),
//               ),
//               onChanged: (value) => setState(() => _searchQuery = value),
//             ),
//           ),
          
//           // Add/Edit Category Form
//           Card(
//             margin: const EdgeInsets.symmetric(horizontal: 16),
//             elevation: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     Text(
//                       _editingCategoryId != null 
//                           ? 'Edit Category' 
//                           : 'Add New Category',
//                       style: Theme.of(context).textTheme.titleLarge,
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _nameController,
//                       focusNode: _nameFocusNode,
//                       decoration: const InputDecoration(
//                         labelText: 'Category Name',
//                         prefixIcon: Icon(Iconsax.category),
//                         border: OutlineInputBorder(),
//                       ),
//                       inputFormatters: [
//                         LengthLimitingTextInputFormatter(30),
//                       ],
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter a category name';
//                         }
//                         if (value.length < 3) {
//                           return 'Name must be at least 3 characters';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _descController,
//                       decoration: const InputDecoration(
//                         labelText: 'Description (Optional)',
//                         prefixIcon: Icon(Iconsax.note),
//                         border: OutlineInputBorder(),
//                       ),
//                       maxLines: 2,
//                       maxLength: 100,
//                     ),
//                     const SizedBox(height: 16),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton.icon(
//                         onPressed: _isLoading ? null : _addCategory,
//                         icon: _isLoading
//                             ? const SizedBox(
//                                 width: 24,
//                                 height: 24,
//                                 child: CircularProgressIndicator(),
//                               )
//                             : Icon(_editingCategoryId != null 
//                                 ? Icons.save 
//                                 : Icons.add),
//                         label: Text(_editingCategoryId != null 
//                             ? 'Update Category' 
//                             : 'Add Category'),
//                       ),
//                     ),
//                     if (_editingCategoryId != null)
//                       TextButton(
//                         onPressed: _resetForm,
//                         child: const Text('Cancel'),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           const Divider(),
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Row(
//               children: [
//                 Icon(Iconsax.category, size: 20),
//                 SizedBox(width: 8),
//                 Text(
//                   'Your Categories',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//           ),
          
//           // List of Categories
//           Expanded(
//             child: StreamBuilder(
//               stream: FirebaseFirestore.instance
//                   .collection('categories')
//                   .orderBy('name')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
                
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
                
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return const Center(
//                     child: Text(
//                       'No categories found\nAdd your first category!',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: 18, color: Colors.grey)),
//                   );
//                 }
                
//                 final docs = snapshot.data!.docs;
                
//                 // Filter based on search query
//                 final filteredDocs = _searchQuery.isEmpty
//                     ? docs
//                     : docs.where((doc) {
//                         final data = doc.data() as Map<String, dynamic>;
//                         final name = data['name'].toString().toLowerCase();
//                         final description = data['description']?.toString().toLowerCase() ?? '';
//                         return name.contains(_searchQuery.toLowerCase()) || 
//                                description.contains(_searchQuery.toLowerCase());
//                       }).toList();
                
//                 if (filteredDocs.isEmpty) {
//                   return const Center(
//                     child: Text(
//                       'No matching categories found',
//                       style: TextStyle(fontSize: 18, color: Colors.grey)),
//                   );
//                 }
                
//                 return ListView.builder(
//                   itemCount: filteredDocs.length,
//                   itemBuilder: (ctx, i) => _buildCategoryCard(filteredDocs[i]),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }