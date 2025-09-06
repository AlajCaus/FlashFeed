/// Utility-Klasse für deutsche Postleitzahlen-Validierung
/// 
/// Task 5b.3: Erstellt für PLZ-Fallback-Kette
/// Integration: LocalStorageService, PLZInputDialog, LocationProvider
class PLZHelper {
  /// Deutsche PLZ-Validierung (5 Ziffern, gültiger Bereich) - Task D Fix
  /// 
  /// Deutsche PLZ-Bereiche: 01001-99999 (99999 ist gültig!)
  /// Ausgeschlossen: 00000 (ungültiger Testcode)
  /// 
  /// [plz] PLZ-String zum Validieren
  /// Returns: true wenn gültige deutsche PLZ
  static bool isValidPLZ(String plz) {
    // Null/Empty Check
    if (plz.isEmpty) return false;
    
    // Format Check: Genau 5 Ziffern
    if (!RegExp(r'^\d{5}$').hasMatch(plz)) return false;
    
    // Numerischer Bereich Check
    final plzNumber = int.tryParse(plz);
    if (plzNumber == null) return false;
    
    // Deutsche PLZ-Bereiche: 01001-99999
    // TASK D FIX: 99999 ist gültige deutsche PLZ, nicht ausschließen
    if (plzNumber < 1001 || plzNumber > 99999) return false;
    
    return true;
  }
  
  /// Debug-Informationen für PLZ-Validierung - Updated für Task D
  static Map<String, dynamic> validatePLZDetailed(String plz) {
    return {
      'plz': plz,
      'isEmpty': plz.isEmpty,
      'hasCorrectLength': plz.length == 5,
      'isNumeric': RegExp(r'^\d{5}$').hasMatch(plz),
      'numericalValue': int.tryParse(plz),
      'isInValidRange': () {
        final num = int.tryParse(plz);
        if (num == null) return false;
        return num >= 1001 && num <= 99999; // Updated: 99999 ist gültig
      }(),
      'isValid': isValidPLZ(plz),
    };
  }
}
