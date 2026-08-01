import '../../../core/models/base_model.dart';

/// Represents a custom Income or Expense category.
///
/// Extends [BaseModel] to inherit all 13 standardized audit & control fields.
class CategoryModel extends BaseModel {
  final String categoryName;

  /// 'income' or 'expense'
  final String categoryType;

  final String iconName;
  final String colorHex;

  const CategoryModel({
    // Base fields
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.createdBy,
    super.updatedBy,
    super.deletedAt,
    super.deletedBy,
    super.isDeleted,
    super.version,
    super.status,
    super.tenantId,
    super.remarks,
    super.metadata,
    // Category fields
    required this.categoryName,
    required this.categoryType,
    this.iconName = 'category',
    this.colorHex = '#6C3DE8',
  });

  // ── Deserialisation ───────────────────────────────────────────────

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    final base = BaseModel.baseFromMap(map);
    return CategoryModel(
      // Base fields
      id: base['id'] as String,
      createdAt: base['created_at'] as String,
      updatedAt: base['updated_at'] as String,
      createdBy: base['created_by'] as String?,
      updatedBy: base['updated_by'] as String?,
      deletedAt: base['deleted_at'] as String?,
      deletedBy: base['deleted_by'] as String?,
      isDeleted: base['is_deleted'] as bool,
      version: base['version'] as int,
      status: base['status'] as String,
      tenantId: base['tenant_id'] as String?,
      remarks: base['remarks'] as String?,
      metadata: base['metadata'] as String?,
      // Category fields
      categoryName: map['category_name']?.toString() ?? map['name']?.toString() ?? '',
      categoryType: map['category_type']?.toString() ?? 'expense',
      iconName: map['icon_name']?.toString() ?? 'category',
      colorHex: map['color_hex']?.toString() ?? '#6C3DE8',
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────

  @override
  Map<String, dynamic> toMap() => {
        ...baseToMap(),
        'category_name': categoryName,
        'category_type': categoryType,
        'icon_name': iconName,
        'color_hex': colorHex,
      };

  bool get isIncome => categoryType.toLowerCase() == 'income';
  bool get isExpense => categoryType.toLowerCase() == 'expense';
}
