import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClothingItem {
  final String id;
  final String name;
  final String category;
  final String color;
  final String? image;
  bool isFavorite;

  ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    this.image,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'color': color,
      'image': image,
      'isFavorite': isFavorite,
    };
  }

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      color: json['color'] as String,
      image: json['image'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}

void main() {
  runApp(const ReWearApp());
}

const Color cream = Color(0xFFF8F5EF);
const Color brown = Color(0xFF49382F);
const Color sage = Color(0xFFA6AD91);
const Color pink = Color(0xFFD9B9B0);

class ReWearApp extends StatelessWidget {
  const ReWearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ReWear',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(seedColor: sage),
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: brown,
          elevation: 0,
        ),
      ),
      home: const ClosetPage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Add item dialog (this was missing in the original code)
// ---------------------------------------------------------------------------
class AddItemDialog extends StatefulWidget {
  const AddItemDialog({super.key});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final nameController = TextEditingController();
  final colorController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  final List<String> categoryOptions = const [
    'Tops',
    'Bottoms',
    'Shoes',
    'Accessories',
    'Outerwear',
  ];

  String category = 'Tops';
  String? imageBase64;

  @override
  void dispose() {
    nameController.dispose();
    colorController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    try {
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 70,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => imageBase64 = base64Encode(bytes));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick an image.')),
      );
    }
  }

  void submit() {
    final name = nameController.text.trim();
    final color = colorController.text.trim();

    if (name.isEmpty || color.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name and a color.')),
      );
      return;
    }

    Navigator.pop(
      context,
      ClothingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        category: category,
        color: color,
        image: imageBase64,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cream,
      title: const Text(
        'Add Item',
        style: TextStyle(color: brown, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFECE9E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imageBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(imageBase64!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 34, color: sage),
                          SizedBox(height: 6),
                          Text('Tap to add a photo',
                              style: TextStyle(color: brown, fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Category',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: categoryOptions
                  .map((c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => category = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: colorController,
              decoration: InputDecoration(
                labelText: 'Color',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: brown)),
        ),
        ElevatedButton(
          onPressed: submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: brown,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Closet page
// ---------------------------------------------------------------------------
class ClosetPage extends StatefulWidget {
  const ClosetPage({super.key});

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  List<ClothingItem> items = [];
  String selectedCategory = 'All';
  String searchText = '';
  bool loading = true;

  final List<String> categories = [
    'All',
    'Favourites',
    'Tops',
    'Bottoms',
    'Shoes',
    'Accessories',
    'Outerwear',
  ];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final savedItems = prefs.getString('rewear_items');

    if (savedItems != null) {
      final List decoded = jsonDecode(savedItems) as List;
      items = decoded
          .map((item) =>
              ClothingItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final data = items.map((item) => item.toJson()).toList();
    await prefs.setString('rewear_items', jsonEncode(data));
  }

  Future<void> addItem(ClothingItem item) async {
    setState(() => items.add(item));
    await saveItems();
  }

  Future<void> deleteItem(String id) async {
    setState(() {
      items.removeWhere((item) => item.id == id);
    });
    await saveItems();
  }

  Future<void> toggleFavorite(ClothingItem item) async {
    setState(() {
      item.isFavorite = !item.isFavorite;
    });
    await saveItems();
  }

  List<ClothingItem> get filteredItems {
    return items.where((item) {
      final categoryMatch = selectedCategory == 'All' ||
          (selectedCategory == 'Favourites'
              ? item.isFavorite
              : item.category == selectedCategory);

      final searchMatch =
          item.name.toLowerCase().contains(searchText.toLowerCase());

      return categoryMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'REWEAR.',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: Text(
                'Wear more. Waste less.',
                style: TextStyle(
                  color: brown.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR STYLE,',
                      style: TextStyle(
                        color: sage,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'My Closet',
                      style: TextStyle(
                        color: brown,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${items.length} pieces in your wardrobe',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WardrobeInsightsPage(items: items),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('Wardrobe Insights'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pink,
                        foregroundColor: brown,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9E8DD),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'A wardrobe that works for you.',
                                  style: TextStyle(
                                    color: brown,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Organise your clothes and discover new outfits.',
                                  style: TextStyle(
                                    color: brown,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.checkroom,
                            size: 48,
                            color: brown,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your pieces',
                          style: TextStyle(
                            fontSize: 21,
                            color: brown,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OutfitBuilderPage(items: items),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Outfit Builder'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: sage,
                                foregroundColor: brown,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final item = await showDialog<ClothingItem>(
                                  context: context,
                                  builder: (context) => const AddItemDialog(),
                                );

                                if (item != null) {
                                  await addItem(item);
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Item'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brown,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (value) {
                        setState(() => searchText = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search your wardrobe...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((category) {
                          final selected = selectedCategory == category;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: selected,
                              selectedColor: sage,
                              onSelected: (_) {
                                setState(() {
                                  selectedCategory = category;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (visibleItems.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 45),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.checkroom_outlined,
                                size: 65,
                                color: sage,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Your closet is waiting!',
                                style: TextStyle(
                                  color: brown,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                selectedCategory == 'Favourites'
                                    ? 'You have no favourites yet.'
                                    : 'Add your first clothing piece.',
                                style: const TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth > 650 ? 3 : 2;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: visibleItems.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.72,
                            ),
                            itemBuilder: (context, index) {
                              final item = visibleItems[index];

                              return Card(
                                color: Colors.white,
                                elevation: 1,
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Container(
                                            color: const Color(0xFFECE9E2),
                                            child: item.image != null &&
                                                    item.image!.isNotEmpty
                                                ? Image.memory(
                                                    base64Decode(item.image!),
                                                    fit: BoxFit.cover,
                                                  )
                                                : const Icon(
                                                    Icons.checkroom,
                                                    size: 55,
                                                    color: sage,
                                                  ),
                                          ),

                                          // Favourite button
                                          Positioned(
                                            top: 5,
                                            left: 5,
                                            child: IconButton(
                                              onPressed: () =>
                                                  toggleFavorite(item),
                                              icon: Icon(
                                                item.isFavorite
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: item.isFavorite
                                                    ? Colors.red
                                                    : Colors.white,
                                              ),
                                              style: IconButton.styleFrom(
                                                backgroundColor:
                                                    Colors.black45,
                                              ),
                                            ),
                                          ),

                                          // Delete button
                                          Positioned(
                                            top: 5,
                                            right: 5,
                                            child: IconButton(
                                              onPressed: () =>
                                                  deleteItem(item.id),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.white,
                                              ),
                                              style: IconButton.styleFrom(
                                                backgroundColor:
                                                    Colors.black45,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: brown,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.category} • ${item.color}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 30),
                    const Center(
                      child: Text(
                        'REWEAR • BUILD A CONSCIOUS WARDROBE',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Outfit builder
// ---------------------------------------------------------------------------
class OutfitBuilderPage extends StatefulWidget {
  final List<ClothingItem> items;

  const OutfitBuilderPage({super.key, required this.items});

  @override
  State<OutfitBuilderPage> createState() => _OutfitBuilderPageState();
}

class _OutfitBuilderPageState extends State<OutfitBuilderPage> {
  ClothingItem? selectedTop;
  ClothingItem? selectedBottom;
  ClothingItem? selectedShoes;

  final outfitNameController = TextEditingController();
  List<Map<String, dynamic>> savedOutfits = [];

  @override
  void initState() {
    super.initState();
    loadOutfits();
  }

  @override
  void dispose() {
    outfitNameController.dispose();
    super.dispose();
  }

  Future<void> loadOutfits() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('rewear_outfits');

    if (data != null) {
      final List decoded = jsonDecode(data) as List;
      if (mounted) {
        setState(() {
          savedOutfits = decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }
    }
  }

  Future<void> saveOutfit() async {
    if (selectedTop == null ||
        selectedBottom == null ||
        selectedShoes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a top, bottom and shoes!'),
        ),
      );
      return;
    }

    final name = outfitNameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your outfit a name!')),
      );
      return;
    }

    final outfit = <String, dynamic>{
      'name': name,
      'top': selectedTop!.name,
      'bottom': selectedBottom!.name,
      'shoes': selectedShoes!.name,
    };

    setState(() {
      savedOutfits.add(outfit);
      outfitNameController.clear();
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'rewear_outfits',
      jsonEncode(savedOutfits),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Outfit saved successfully!')),
      );
    }
  }

  Widget clothingDropdown(
    String label,
    String category,
    ClothingItem? selected,
    ValueChanged<ClothingItem?> onChanged,
  ) {
    final available =
        widget.items.where((item) => item.category == category).toList();

    return DropdownButtonFormField<ClothingItem>(
      value: available.contains(selected) ? selected : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      hint: Text('Choose $category'),
      items: available.map((item) {
        return DropdownMenuItem<ClothingItem>(
          value: item,
          child: Text(item.name),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget previewPiece(ClothingItem? item, String label) {
    final image = item?.image;

    return Expanded(
      child: Column(
        children: [
          Container(
            height: 125,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFECE9E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: image != null && image.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(image),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.checkroom,
                    size: 38,
                    color: sage,
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            item?.name ?? label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: brown,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'OUTFIT BUILDER',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create your look.',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: brown,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Mix and match pieces from your wardrobe.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 25),
            const Text(
              'YOUR OUTFIT PREVIEW',
              style: TextStyle(
                color: brown,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                previewPiece(selectedTop, 'Top'),
                const SizedBox(width: 10),
                previewPiece(selectedBottom, 'Bottom'),
                const SizedBox(width: 10),
                previewPiece(selectedShoes, 'Shoes'),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Choose your pieces',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: brown,
              ),
            ),
            const SizedBox(height: 15),
            clothingDropdown(
              'Select a top',
              'Tops',
              selectedTop,
              (value) => setState(() => selectedTop = value),
            ),
            const SizedBox(height: 14),
            clothingDropdown(
              'Select a bottom',
              'Bottoms',
              selectedBottom,
              (value) => setState(() => selectedBottom = value),
            ),
            const SizedBox(height: 14),
            clothingDropdown(
              'Select shoes',
              'Shoes',
              selectedShoes,
              (value) => setState(() => selectedShoes = value),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: outfitNameController,
              decoration: InputDecoration(
                labelText: 'Name your outfit',
                hintText: 'e.g. Casual Sunday',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saveOutfit,
                icon: const Icon(Icons.favorite),
                label: const Text('Save Outfit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'SAVED OUTFITS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: brown,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeeklyPlannerPage(outfits: savedOutfits),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('Open Weekly Planner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: sage,
                foregroundColor: brown,
                padding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 12),
            if (savedOutfits.isEmpty)
              const Text(
                'Your saved outfits will appear here.',
                style: TextStyle(color: Colors.black54),
              )
            else
              ...savedOutfits.map((outfit) {
                return Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE9E8DD),
                      child: Icon(
                        Icons.checkroom,
                        color: brown,
                      ),
                    ),
                    title: Text(
                      outfit['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: brown,
                      ),
                    ),
                    subtitle: Text(
                      '${outfit['top']} • ${outfit['bottom']} • ${outfit['shoes']}',
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly planner
// ---------------------------------------------------------------------------
class WeeklyPlannerPage extends StatefulWidget {
  final List<Map<String, dynamic>> outfits;

  const WeeklyPlannerPage({super.key, required this.outfits});

  @override
  State<WeeklyPlannerPage> createState() => _WeeklyPlannerPageState();
}

class _WeeklyPlannerPageState extends State<WeeklyPlannerPage> {
  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  Map<String, String> weeklyPlan = {};

  @override
  void initState() {
    super.initState();
    loadPlan();
  }

  Future<void> loadPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('rewear_weekly_plan');

    if (saved != null) {
      final decoded = jsonDecode(saved) as Map;
      if (mounted) {
        setState(() {
          weeklyPlan = decoded.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          );
        });
      }
    }
  }

  Future<void> assignOutfit(String day, String? outfitIndex) async {
    if (outfitIndex == null) return;

    setState(() {
      weeklyPlan[day] = outfitIndex;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'rewear_weekly_plan',
      jsonEncode(weeklyPlan),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WEEKLY PLANNER',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan your week.',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: brown,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose what you want to wear each day.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            if (widget.outfits.isEmpty)
              const Text(
                'You have no saved outfits yet. Create an outfit first!',
                style: TextStyle(color: brown),
              )
            else
              ...days.map((day) {
                final selected = weeklyPlan[day];
                final selectedIndex =
                    selected == null ? null : int.tryParse(selected);

                final Map<String, dynamic>? selectedOutfit =
                    (selectedIndex != null &&
                            selectedIndex >= 0 &&
                            selectedIndex < widget.outfits.length)
                        ? widget.outfits[selectedIndex]
                        : null;

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: brown,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedOutfit != null ? selected : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'Choose an outfit',
                            filled: true,
                            fillColor: cream,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: List.generate(
                            widget.outfits.length,
                            (index) {
                              return DropdownMenuItem<String>(
                                value: index.toString(),
                                child: Text(
                                  widget.outfits[index]['name'] as String,
                                ),
                              );
                            },
                          ),
                          onChanged: (value) => assignOutfit(day, value),
                        ),
                        if (selectedOutfit != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Top: ${selectedOutfit['top']}',
                            style: const TextStyle(color: brown),
                          ),
                          Text(
                            'Bottom: ${selectedOutfit['bottom']}',
                            style: const TextStyle(color: brown),
                          ),
                          Text(
                            'Shoes: ${selectedOutfit['shoes']}',
                            style: const TextStyle(color: brown),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'PLAN IT. STYLE IT. REWEAR IT.',
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wardrobe insights
// ---------------------------------------------------------------------------
class WardrobeInsightsPage extends StatelessWidget {
  final List<ClothingItem> items;

  const WardrobeInsightsPage({
    super.key,
    required this.items,
  });

  Future<int> getOutfitCount() async {
    final prefs = await SharedPreferences.getInstance();
    final outfits = prefs.getString('rewear_outfits');

    if (outfits == null) return 0;

    return (jsonDecode(outfits) as List).length;
  }

  @override
  Widget build(BuildContext context) {
    const categories = [
      'Tops',
      'Bottoms',
      'Shoes',
      'Accessories',
      'Outerwear',
    ];

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Wardrobe Insights'),
        backgroundColor: cream,
        foregroundColor: brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const Text(
              'Your wardrobe at a glance',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: brown,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _insightCard(
                    'Total Pieces',
                    '${items.length}',
                    Icons.checkroom,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<int>(
                    future: getOutfitCount(),
                    builder: (context, snapshot) {
                      return _insightCard(
                        'Saved Outfits',
                        '${snapshot.data ?? 0}',
                        Icons.style,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Category Breakdown',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: brown,
              ),
            ),
            const SizedBox(height: 16),
            ...categories.map((category) {
              final count =
                  items.where((item) => item.category == category).length;

              final percentage = items.isEmpty ? 0.0 : count / items.length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$category ($count)',
                      style: const TextStyle(
                        color: brown,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: pink.withOpacity(0.3),
                      color: sage,
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: sage.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.eco, color: brown, size: 30),
                  SizedBox(height: 10),
                  Text(
                    'Wear more. Waste less.',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: brown,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Make the most of the clothes you already own. '
                    'Create new combinations and shop more consciously.',
                    style: TextStyle(color: brown),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pink.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: brown, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: brown,
            ),
          ),
          Text(title, style: const TextStyle(color: brown)),
        ],
      ),
    );
  }
}