import '../../../core/db/db_base_fields.dart';
import '../../../core/models/base_model.dart';
import '../../../core/services/database_service.dart';
import '../models/contact_model.dart';

/// Data service for managing Contact Directory entries.
class ContactService {
  ContactService._();
  static final ContactService instance = ContactService._();

  final _db = DatabaseService.instance;

  // ── Default Sample Contacts (for initial display) ──────────────────
  static final List<ContactModel> _sampleContacts = [
    ContactModel(
      id: 'c1',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      ownerName: 'Rahul Sharma',
      mobileNumber: '9876543210',
      businessShopName: 'Sharma General Store',
      placeCity: 'Mumbai',
      isActiveStatus: true,
      enableNotification: true,
      notificationMethod: NotificationMethod.whatsApp,
    ),
    ContactModel(
      id: 'c2',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      ownerName: 'Priya Patel',
      mobileNumber: '9123456789',
      businessShopName: 'Patel Electronics',
      placeCity: 'Ahmedabad',
      isActiveStatus: true,
      enableNotification: true,
      notificationMethod: NotificationMethod.sms,
    ),
    ContactModel(
      id: 'c3',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      ownerName: 'Amit Verma',
      mobileNumber: '9988776655',
      businessShopName: 'Verma Traders',
      placeCity: 'Delhi',
      isActiveStatus: false,
      enableNotification: false,
      notificationMethod: NotificationMethod.whatsApp,
    ),
  ];

  // ── Fetch All Contacts ─────────────────────────────────────────────
  Future<List<ContactModel>> fetchContacts() async {
    final result = await _db.query(
      'SELECT * FROM contacts WHERE (is_deleted = 0 OR is_deleted IS NULL) ORDER BY created_at DESC',
    );

    if (result.success && result.isNotEmpty) {
      final dbContacts = result.rows.map((row) => ContactModel.fromMap(row)).toList();
      final defaultsToKeep = _sampleContacts.where((s) => !dbContacts.any((c) => c.id == s.id || c.mobileNumber == s.mobileNumber));
      return [...dbContacts, ...defaultsToKeep];
    }

    return _sampleContacts;
  }

  // ── Save / Update Contact ─────────────────────────────────────────
  Future<bool> saveContact(ContactModel contact) async {
    final existing = await _db.query(
      'SELECT id FROM contacts WHERE id = ? LIMIT 1',
      [contact.id],
    );

    if (existing.success && existing.isNotEmpty) {
      // Update
      final updateFields = {
        ...DbBaseFields.updatedRecord(
          updatedBy: 'system',
          currentVersion: contact.version,
        ),
        'owner_name': contact.ownerName,
        'mobile_number': contact.mobileNumber,
        'business_shop_name': contact.businessShopName,
        'place_city': contact.placeCity,
        'is_active': contact.isActiveStatus ? 1 : 0,
        'enable_notification': contact.enableNotification ? 1 : 0,
        'notification_method': contact.notificationMethod,
      };

      final set = DbBaseFields.buildSetClause(updateFields);
      final res = await _db.query(
        'UPDATE contacts SET ${set.clause} WHERE id = ?',
        [...set.params, contact.id],
      );
      return res.success;
    } else {
      // Insert
      final fields = {
        ...DbBaseFields.newRecord(),
        'id': contact.id.isNotEmpty ? contact.id : BaseModel.newId(),
        'owner_name': contact.ownerName,
        'mobile_number': contact.mobileNumber,
        'business_shop_name': contact.businessShopName,
        'place_city': contact.placeCity,
        'is_active': contact.isActiveStatus ? 1 : 0,
        'enable_notification': contact.enableNotification ? 1 : 0,
        'notification_method': contact.notificationMethod,
      };

      final res = await _db.insertRecord('contacts', fields);
      return res.success;
    }
  }

  // ── Soft Delete Contact ────────────────────────────────────────────
  Future<bool> deleteContact(String id) async {
    final res = await _db.softDelete(
      'contacts',
      id,
      deletedBy: 'system',
      currentVersion: 1,
    );
    return res.success;
  }
}
