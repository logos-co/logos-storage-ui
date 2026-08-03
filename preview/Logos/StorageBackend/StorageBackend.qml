import QtQuick

// Stub of the StorageStatus enum the real replica exposes (src/StorageBackend.rep).
QtObject {
    enum StorageStatus {
        Stopped,
        Starting,
        Running,
        Stopping,
        Destroyed
    }
}
