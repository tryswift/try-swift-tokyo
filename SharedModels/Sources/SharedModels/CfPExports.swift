// Re-export all CfP types from the SharedModels module
// This file ensures all types in the CfP subfolder are accessible

@_exported import struct Foundation.Date
@_exported import struct Foundation.UUID

// CfP types are automatically included as they are in the same module
// This file exists to ensure the CfP folder is properly compiled as part of SharedModels
