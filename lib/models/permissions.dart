enum Permission {
  // Medical Operations
  viewPatientRecords,
  createPatientRecords,
  editPatientRecords,
  deletePatientRecords,
  orderTests,
  performTests,
  viewTestResults,
  editTestResults,
  approveTestResults,
  prescribeMedication,

  // Laboratory Management
  viewInventory,
  manageInventory,
  qualityControl,
  equipmentMaintenance,
  sampleManagement,

  // Administrative
  viewEmployees,
  createEmployee,
  editEmployee,
  deleteEmployee,
  viewAttendance,
  manageAttendance,
  viewPayroll,
  managePayroll,

  // Attendance & Leave Management
  clockInOut,
  viewOwnAttendance,
  viewAllAttendance,
  editAttendance,
  generateAttendanceReports,
  applyLeave,
  approveLeave,
  rejectLeave,
  viewOwnLeave,
  viewAllLeave,
  cancelLeave,

  // System Management
  manageRoles,
  manageSettings,
  viewReports,
  exportData,
  accessAuditLogs,
}
