import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:my_tool_shed/models/tool.dart';

class DatabaseHelper {
  static const _databaseName = "ToolShed.db";
  static const _databaseVersion = 2;

  static const tableTools = 'tools';
  static const tableBorrowHistory = 'borrow_history';

  static const columnId = 'id';
  static const columnName = 'name';
  static const columnImagePath = 'imagePath';
  static const columnBrand = 'brand';
  static const columnIsBorrowed = 'isBorrowed';
  static const columnReturnDate = 'returnDate';
  static const columnBorrowedBy = 'borrowedBy';
  static const columnBorrowerPhone = 'borrowerPhone';
  static const columnBorrowerEmail = 'borrowerEmail';
  static const columnNotes = 'notes';
  static const columnQrCode = 'qrCode';
  static const columnCategory = 'category';
  static const columnOwnerId = 'ownerId';
  static const columnOwnerName = 'ownerName';

  // BorrowHistory specific columns
  static const columnHistoryToolId = 'tool_id'; // Foreign key to tools table
  static const columnBorrowerId = 'borrowerId';
  static const columnBorrowDate = 'borrowDate';
  static const columnDueDate = 'dueDate';
  // returnDate, borrowerName, borrowerPhone, borrowerEmail, notes are already in Tool or common

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTools (
        $columnId TEXT PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnImagePath TEXT,
        $columnBrand TEXT,
        $columnIsBorrowed INTEGER NOT NULL,
        $columnReturnDate TEXT,
        $columnBorrowedBy TEXT,
        $columnBorrowerPhone TEXT,
        $columnBorrowerEmail TEXT,
        $columnNotes TEXT,
        $columnQrCode TEXT,
        $columnCategory TEXT,
        $columnOwnerId TEXT NOT NULL,
        $columnOwnerName TEXT NOT NULL
      )
      ''');

    await db.execute('''
      CREATE TABLE $tableBorrowHistory (
        $columnId TEXT PRIMARY KEY, 
        $columnHistoryToolId TEXT NOT NULL,
        $columnBorrowerId TEXT NOT NULL,
        $columnName TEXT NOT NULL, 
        $columnBorrowerPhone TEXT,
        $columnBorrowerEmail TEXT,
        $columnBorrowDate TEXT NOT NULL,
        $columnDueDate TEXT NOT NULL,
        $columnReturnDate TEXT,
        $columnNotes TEXT,
        FOREIGN KEY ($columnHistoryToolId) REFERENCES $tableTools ($columnId) ON DELETE CASCADE
      )
      ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE $tableTools ADD COLUMN $columnBrand TEXT");
    }
    if (oldVersion < 3) {
      await db.execute(
          "ALTER TABLE $tableTools ADD COLUMN $columnOwnerId TEXT NOT NULL DEFAULT 'system'");
      await db.execute(
          "ALTER TABLE $tableTools ADD COLUMN $columnOwnerName TEXT NOT NULL DEFAULT 'System'");
    }
    // Add more migrations here if oldVersion < 4, etc.
  }

  // Helper methods for Tool
  Future<int> insertTool(Tool tool) async {
    Database db = await instance.database;
    return await db.insert(tableTools, tool.toJsonForDb());
  }

  Future<List<Tool>> getAllTools() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableTools);

    if (maps.isEmpty) {
      return [];
    }

    List<Tool> tools = [];
    for (var map in maps) {
      List<BorrowHistory> history =
          await getBorrowHistoryForTool(map[columnId] as String);
      tools.add(ToolDbExtension.fromJsonDb(map, history));
    }
    return tools;
  }

  Future<List<Tool>> getBorrowedTools() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTools,
      where: '$columnIsBorrowed = ?',
      whereArgs: [1],
    );

    if (maps.isEmpty) {
      return [];
    }

    List<Tool> tools = [];
    for (var map in maps) {
      List<BorrowHistory> history =
          await getBorrowHistoryForTool(map[columnId] as String);
      tools.add(ToolDbExtension.fromJsonDb(map, history));
    }
    return tools;
  }

  Future<List<Tool>> getAvailableTools() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTools,
      where: '$columnIsBorrowed = ?',
      whereArgs: [0],
    );

    if (maps.isEmpty) {
      return [];
    }

    List<Tool> tools = [];
    for (var map in maps) {
      List<BorrowHistory> history =
          await getBorrowHistoryForTool(map[columnId] as String);
      tools.add(ToolDbExtension.fromJsonDb(map, history));
    }
    return tools;
  }

  Future<Tool?> getToolById(String id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableTools,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      List<BorrowHistory> history =
          await getBorrowHistoryForTool(maps.first[columnId] as String);
      return ToolDbExtension.fromJsonDb(maps.first, history);
    }
    return null;
  }

  Future<int> updateTool(Tool tool) async {
    Database db = await instance.database;
    return await db.update(
      tableTools,
      tool.toJsonForDb(),
      where: '$columnId = ?',
      whereArgs: [tool.id],
    );
  }

  Future<int> deleteTool(String id) async {
    Database db = await instance.database;
    //Also deletes associated borrow history due to ON DELETE CASCADE
    return await db.delete(
      tableTools,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Helper methods for BorrowHistory
  Future<int> insertBorrowHistory(BorrowHistory history, String toolId) async {
    Database db = await instance.database;
    return await db.insert(tableBorrowHistory, history.toJsonForDb(toolId));
  }

  Future<List<BorrowHistory>> getBorrowHistoryForTool(String toolId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableBorrowHistory,
      where: '$columnHistoryToolId = ?',
      whereArgs: [toolId],
      orderBy: '$columnBorrowDate DESC',
    );
    return List.generate(maps.length, (i) {
      return BorrowHistoryDbExtension.fromJsonDb(maps[i]);
    });
  }

  Future<int> updateBorrowHistory(BorrowHistory history, String toolId) async {
    Database db = await instance.database;
    return await db.update(
      tableBorrowHistory,
      history.toJsonForDb(toolId),
      where: '$columnId = ?',
      whereArgs: [history.id],
    );
  }

  // This method might need to be more specific if a tool can have multiple identical history entries
  // For now, using the history entry's own ID (which we'll make sure is unique)
  Future<int> deleteBorrowHistoryEntry(String historyId) async {
    Database db = await instance.database;
    return await db.delete(
      tableBorrowHistory,
      where: '$columnId = ?',
      whereArgs: [historyId],
    );
  }

  Future<void> clearBorrowHistoryForTool(String toolId) async {
    Database db = await instance.database;
    await db.delete(
      tableBorrowHistory,
      where: '$columnHistoryToolId = ?',
      whereArgs: [toolId],
    );
  }
}

// Extension methods on Tool and BorrowHistory to handle DB specific JSON
extension ToolDbExtension on Tool {
  Map<String, dynamic> toJsonForDb() => {
        DatabaseHelper.columnId: id,
        DatabaseHelper.columnName: name,
        DatabaseHelper.columnImagePath: imagePath,
        DatabaseHelper.columnBrand: brand,
        DatabaseHelper.columnIsBorrowed: isBorrowed ? 1 : 0,
        DatabaseHelper.columnReturnDate: returnDate?.toIso8601String(),
        DatabaseHelper.columnBorrowedBy: borrowedBy,
        DatabaseHelper.columnBorrowerPhone: borrowerPhone,
        DatabaseHelper.columnBorrowerEmail: borrowerEmail,
        DatabaseHelper.columnNotes: notes,
        DatabaseHelper.columnQrCode: qrCode,
        DatabaseHelper.columnCategory: category,
        DatabaseHelper.columnOwnerId: ownerId,
        DatabaseHelper.columnOwnerName: ownerName,
      };

  static Tool fromJsonDb(
          Map<String, dynamic> json, List<BorrowHistory> history) =>
      Tool(
        id: json[DatabaseHelper.columnId] as String,
        name: json[DatabaseHelper.columnName] as String,
        imagePath: json[DatabaseHelper.columnImagePath] as String?,
        brand: json[DatabaseHelper.columnBrand] as String?,
        ownerId: json[DatabaseHelper.columnOwnerId] as String,
        ownerName: json[DatabaseHelper.columnOwnerName] as String,
        isBorrowed: (json[DatabaseHelper.columnIsBorrowed] as int) == 1,
        returnDate: json[DatabaseHelper.columnReturnDate] == null
            ? null
            : DateTime.parse(json[DatabaseHelper.columnReturnDate] as String),
        borrowedBy: json[DatabaseHelper.columnBorrowedBy] as String?,
        borrowHistory: history,
        borrowerPhone: json[DatabaseHelper.columnBorrowerPhone] as String?,
        borrowerEmail: json[DatabaseHelper.columnBorrowerEmail] as String?,
        notes: json[DatabaseHelper.columnNotes] as String?,
        qrCode: json[DatabaseHelper.columnQrCode] as String?,
        category: json[DatabaseHelper.columnCategory] as String?,
      );
}

extension BorrowHistoryDbExtension on BorrowHistory {
  Map<String, dynamic> toJsonForDb(String toolId) => {
        DatabaseHelper.columnId: id,
        DatabaseHelper.columnHistoryToolId: toolId,
        DatabaseHelper.columnBorrowerId: borrowerId,
        DatabaseHelper.columnName: borrowerName,
        DatabaseHelper.columnBorrowerPhone: borrowerPhone,
        DatabaseHelper.columnBorrowerEmail: borrowerEmail,
        DatabaseHelper.columnBorrowDate: borrowDate.toIso8601String(),
        DatabaseHelper.columnDueDate: dueDate.toIso8601String(),
        DatabaseHelper.columnReturnDate: returnDate?.toIso8601String(),
        DatabaseHelper.columnNotes: notes,
      };

  static BorrowHistory fromJsonDb(Map<String, dynamic> json) => BorrowHistory(
        id: json[DatabaseHelper.columnId] as String,
        borrowerId: json[DatabaseHelper.columnBorrowerId] as String,
        borrowerName: json[DatabaseHelper.columnName] as String,
        borrowerPhone: json[DatabaseHelper.columnBorrowerPhone] as String?,
        borrowerEmail: json[DatabaseHelper.columnBorrowerEmail] as String?,
        borrowDate:
            DateTime.parse(json[DatabaseHelper.columnBorrowDate] as String),
        dueDate: DateTime.parse(json[DatabaseHelper.columnDueDate] as String),
        returnDate: json[DatabaseHelper.columnReturnDate] == null
            ? null
            : DateTime.parse(json[DatabaseHelper.columnReturnDate] as String),
        notes: json[DatabaseHelper.columnNotes] as String?,
      );
}
