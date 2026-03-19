import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const RecipeBookApp());
}

class Recipe {
  final String id;
  final String title;
  final List<String> ingredients;
  final String instructions;
  final String imageUrl;
  final String category;
  final String time;
  final String difficulty;

  Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.instructions,
    required this.imageUrl,
    required this.category,
    required this.time,
    required this.difficulty,
  });
}

class RecipeBookApp extends StatelessWidget {
  const RecipeBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Book',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5722),
          primary: const Color(0xFFFF5722),
          secondary: const Color(0xFFFFAB40),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const RecipeListScreen(),
    );
  }
}

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> with TickerProviderStateMixin {
  final List<Recipe> _recipes = [
    Recipe(
      id: '1',
      title: 'Spaghetti Carbonara',
      category: 'Italian',
      time: '25 min',
      difficulty: 'Medium',
      ingredients: ['Spaghetti', 'Eggs', 'Pecorino Romano', 'Guanciale', 'Black Pepper'],
      instructions: '1. Boil water and cook pasta.\n2. Fry guanciale until crispy.\n3. Mix eggs and cheese.\n4. Combine all with pasta and pepper.',
      imageUrl: 'https://images.unsplash.com/photo-1612874742237-6526221588e3?q=80&w=500&auto=format&fit=crop',
    ),
    Recipe(
      id: '2',
      title: 'Chicken Caesar Salad',
      category: 'Salad',
      time: '15 min',
      difficulty: 'Easy',
      ingredients: ['Romaine Lettuce', 'Chicken Breast', 'Croutons', 'Caesar Dressing', 'Parmesan'],
      instructions: '1. Grill chicken.\n2. Chop lettuce.\n3. Toss lettuce with dressing and croutons.\n4. Top with chicken and cheese.',
      imageUrl: 'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?q=80&w=500&auto=format&fit=crop',
    ),
    Recipe(
      id: '3',
      title: 'Berry Smoothie',
      category: 'Breakfast',
      time: '5 min',
      difficulty: 'Easy',
      ingredients: ['Mixed Berries', 'Banana', 'Greek Yogurt', 'Honey', 'Milk'],
      instructions: '1. Place all ingredients in a blender.\n2. Blend until smooth.\n3. Pour into a glass and serve.',
      imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?q=80&w=500&auto=format&fit=crop',
    ),
    Recipe(
      id: '4',
      title: 'Beef Tacos',
      category: 'Mexican',
      time: '30 min',
      difficulty: 'Medium',
      ingredients: ['Ground Beef', 'Taco Shells', 'Lettuce', 'Tomato', 'Cheddar Cheese', 'Sour Cream'],
      instructions: '1. Brown the beef with taco seasoning.\n2. Chop vegetables.\n3. Fill shells with beef and toppings.',
      imageUrl: 'https://images.unsplash.com/photo-1552332386-f8dd00dc2f85?q=80&w=500&auto=format&fit=crop',
    ),
  ];

  List<Recipe> _filteredRecipes = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Italian', 'Salad', 'Breakfast', 'Mexican'];

  @override
  void initState() {
    super.initState();
    _filteredRecipes = _recipes;
    _searchController.addListener(_filterRecipes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRecipes() {
    setState(() {
      _filteredRecipes = _recipes.where((recipe) {
        final matchesSearch = recipe.title.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesCategory = _selectedCategory == 'All' || recipe.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: const Text(
              'Discover Recipes',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            centerTitle: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none, color: Colors.orange),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search ingredients, recipes...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.search, color: Colors.deepOrange),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.deepOrange, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              _selectedCategory = category;
                              _filterRecipes();
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.deepOrange,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          showCheckmark: false,
                          side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[200]!),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          _filteredRecipes.isEmpty
              ? const SliverFillRemaining(
                  child: Center(child: EmptyStateAnimation()),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return AnimatedRecipeCard(recipe: _filteredRecipes[index], index: index);
                      },
                      childCount: _filteredRecipes.length,
                    ),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Recipe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class EmptyStateAnimation extends StatefulWidget {
  const EmptyStateAnimation({super.key});

  @override
  State<EmptyStateAnimation> createState() => _EmptyStateAnimationState();
}

class _EmptyStateAnimationState extends State<EmptyStateAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Frying Pan
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: math.sin(_controller.value * math.pi * 2) * 0.1,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[700]!, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // The Egg Animation
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                double yOffset = -math.sin(_controller.value * math.pi) * 80;
                double rotation = _controller.value * math.pi * 2;
                
                return Transform.translate(
                  offset: Offset(0, yOffset),
                  child: Transform.rotate(
                    angle: rotation,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Center(
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: 110,
              child: Container(
                width: 60,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        const Text(
          'Nothing cooking here...',
          style: TextStyle(color: Colors.grey, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Try searching for another recipe!',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
      ],
    );
  }
}

class AnimatedRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final int index;

  const AnimatedRecipeCard({super.key, required this.recipe, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 500),
                pageBuilder: (context, animation, secondaryAnimation) => RecipeDetailScreen(recipe: recipe),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Hero(
                    tag: 'recipe-image-${recipe.id}',
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                        image: DecorationImage(
                          image: NetworkImage(recipe.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: Colors.deepOrange),
                          const SizedBox(width: 4),
                          Text(recipe.time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          recipe.category,
                          style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          recipe.difficulty,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recipe.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Hero(
                tag: 'recipe-image-${recipe.id}',
                child: Image.network(
                  recipe.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          recipe.category,
                          style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          recipe.difficulty,
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    recipe.title,
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _detailStat(Icons.schedule, recipe.time, 'Cooking Time'),
                      _detailStat(Icons.restaurant_menu, '${recipe.ingredients.length} items', 'Ingredients'),
                      _detailStat(Icons.local_fire_department_outlined, '450 kcal', 'Calories'),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Ingredients',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...recipe.ingredients.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: Colors.deepOrange),
                            const SizedBox(width: 16),
                            Text(item, style: const TextStyle(fontSize: 18, color: Colors.black87)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 40),
                  const Text(
                    'Instructions',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    recipe.instructions,
                    style: TextStyle(fontSize: 18, height: 1.8, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('Start Cooking', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _detailStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepOrange, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }
}
