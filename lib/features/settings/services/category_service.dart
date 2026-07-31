import '../../../core/db/db_base_fields.dart';
import '../../../core/models/base_model.dart';
import '../../../core/services/database_service.dart';
import '../models/category_model.dart';

/// Data service for managing custom Income & Expense categories.
class CategoryService {
  CategoryService._();
  static final CategoryService instance = CategoryService._();

  final _db = DatabaseService.instance;

  // ── Default Categories ─────────────────────────────────────────────
  static final List<CategoryModel> _defaultCategories = [
    // Expense
    CategoryModel(
      id: 'cat_1',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      categoryName: 'Food & Dining',
      categoryType: 'expense',
      iconName: 'restaurant',
      colorHex: '#FF9800',
    ),
    CategoryModel(
      id: 'cat_2',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      categoryName: 'Bills & Utilities',
      categoryType: 'expense',
      iconName: 'receipt',
      colorHex: '#6C3DE8',
    ),
    CategoryModel(
      id: 'cat_3',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      categoryName: 'Shopping',
      categoryType: 'expense',
      iconName: 'shopping_bag',
      colorHex: '#00BCD4',
    ),
    CategoryModel(
      id: 'cat_4',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      categoryName: 'Travel & Fuel',
      categoryType: 'expense',
      iconName: 'directions_car',
      colorHex: '#E91E63',
    ),
    // Income
    CategoryModel(
      id: 'cat_5',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      categoryName: 'Salary',
      categoryType: 'income',
      iconName: 'account_balance',
      colorHex: '#4CAF50',
    ),
    CategoryModel(
      id: 'cat_6',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      categoryName: 'Freelance & Business',
      categoryType: 'income',
      iconName: 'work',
      colorHex: '#2196F3',
    ),
  ];

  // ── Fetch All Categories ──────────────────────────────────────────
  Future<List<CategoryModel>> fetchCategories() async {
    final result = await _db.query(
      'SELECT * FROM categories WHERE (is_deleted = 0 OR is_deleted IS NULL) ORDER BY created_at DESC',
    );

    if (result.success && result.isNotEmpty) {
      return result.rows.map((row) => CategoryModel.fromMap(row)).toList();
    }

    return _defaultCategories;
  }

  // ── Add New Category ──────────────────────────────────────────────
  Future<bool> addCategory(CategoryModel category) async {
    final fields = {
      ...DbBaseFields.newRecord(),
      'id': category.id.isNotEmpty ? category.id : BaseModel.newId(),
      'category_name': category.categoryName,
      'category_type': category.categoryType,
      'icon_name': category.iconName,
      'color_hex': category.colorHex,
    };

    final result = await _db.insertRecord('categories', fields);
    return result.success;
  }

  // ── Soft Delete Category ───────────────────────────────────────────
  Future<bool> deleteCategory(String id) async {
    final result = await _db.softDelete(
      'categories',
      id,
      deletedBy: 'system',
      currentVersion: 1,
    );
    return result.success;
  }
}
