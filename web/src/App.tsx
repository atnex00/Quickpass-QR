import { BrowserRouter, Routes, Route, Navigate } from "react-router"
import { useEffect } from "react"
import { useAuthStore } from "@/stores/authStore"
import AppLayout from "@/components/layout/AppLayout"
import RequireRole from "@/components/layout/RequireRole"
import LoginPage from "@/pages/auth/LoginPage"
import EmployeeDashboard from "@/pages/employee/DashboardPage"
import RequestLeavePage from "@/pages/employee/RequestLeavePage"
import LeaveHistoryPage from "@/pages/employee/LeaveHistoryPage"
import QrDisplayPage from "@/pages/employee/QrDisplayPage"
import MyProfilePage from "@/pages/employee/MyProfilePage"
import SupervisorDashboard from "@/pages/supervisor/SupervisorDashboard"
import PendingRequestsPage from "@/pages/supervisor/PendingRequestsPage"
import UserManagerPage from "@/pages/admin/UserManagerPage"
import DepartmentsPage from "@/pages/admin/DepartmentsPage"
import ReportsPage from "@/pages/admin/ReportsPage"
import AuditLogPage from "@/pages/admin/AuditLogPage"
import ScannerPage from "@/pages/security/ScannerPage"
import ScanResultPage from "@/pages/security/ScanResultPage"
import ScanHistoryPage from "@/pages/security/ScanHistoryPage"
import SecurityShell from "@/components/layout/SecurityShell"
import GuidesPage from "@/pages/guides/GuidesPage"
import LoadPreviewPage from "@/pages/LoadPreviewPage"

function AppRoutes() {
  const { loadUser } = useAuthStore()

  useEffect(() => {
    loadUser()
  }, [])

  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />

      <Route element={<AppLayout />}>
        {/* Guides (all roles) */}
        <Route path="/guides" element={<GuidesPage />} />

        {/* Employee */}
        <Route path="/employee" element={<EmployeeDashboard />} />
        <Route path="/employee/request" element={<RequestLeavePage />} />
        <Route path="/employee/history" element={<LeaveHistoryPage />} />
        <Route path="/employee/qr/:id" element={<QrDisplayPage />} />
        <Route path="/employee/profile" element={<MyProfilePage />} />

        {/* Supervisor */}
        <Route path="/supervisor" element={
          <RequireRole roles={["is_supervisor", "is_admin"]}><SupervisorDashboard /></RequireRole>
        } />
        <Route path="/supervisor/pending" element={
          <RequireRole roles={["is_supervisor", "is_admin"]}><PendingRequestsPage /></RequireRole>
        } />

        {/* Admin */}
        <Route path="/admin/employees" element={
          <RequireRole roles={["is_admin"]}><UserManagerPage /></RequireRole>
        } />
        <Route path="/admin/departments" element={
          <RequireRole roles={["is_admin"]}><DepartmentsPage /></RequireRole>
        } />
        <Route path="/admin/reports" element={
          <RequireRole roles={["is_admin"]}><ReportsPage /></RequireRole>
        } />
        <Route path="/admin/audit" element={
          <RequireRole roles={["is_admin"]}><AuditLogPage /></RequireRole>
        } />

      </Route>

      {/* Security / Scanner (standalone, no sidebar) */}
      <Route element={<SecurityShell />}>
        <Route path="/security/scan" element={<ScannerPage />} />
        <Route path="/security/result" element={<ScanResultPage />} />
        <Route path="/security/history" element={<ScanHistoryPage />} />
      </Route>

      {import.meta.env.DEV && <Route path="/load-preview" element={<LoadPreviewPage />} />}
      <Route path="*" element={<Navigate to="/employee" replace />} />
    </Routes>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <AppRoutes />
    </BrowserRouter>
  )
}
