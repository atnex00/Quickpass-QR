import { BrowserRouter, Routes, Route, Navigate } from "react-router"
import { useEffect, Suspense, lazy, useRef } from "react"
import { useAuthStore } from "@/stores/authStore"
import AppLayout from "@/components/layout/AppLayout"
import RequireRole from "@/components/layout/RequireRole"
import SecurityShell from "@/components/layout/SecurityShell"
import LoadingScreen from "@/components/shared/LoadingScreen"
import { ErrorBoundary } from "@/components/ErrorBoundary"

const LoginPage = lazy(() => import("@/pages/auth/LoginPage"))
const GuidesPage = lazy(() => import("@/pages/guides/GuidesPage"))
const EmployeeDashboard = lazy(() => import("@/pages/employee/DashboardPage"))
const RequestLeavePage = lazy(() => import("@/pages/employee/RequestLeavePage"))
const LeaveHistoryPage = lazy(() => import("@/pages/employee/LeaveHistoryPage"))
const QrDisplayPage = lazy(() => import("@/pages/employee/QrDisplayPage"))
const MyProfilePage = lazy(() => import("@/pages/employee/MyProfilePage"))
const SupervisorDashboard = lazy(() => import("@/pages/supervisor/SupervisorDashboard"))
const PendingRequestsPage = lazy(() => import("@/pages/supervisor/PendingRequestsPage"))
const UserManagerPage = lazy(() => import("@/pages/admin/UserManagerPage"))
const DepartmentsPage = lazy(() => import("@/pages/admin/DepartmentsPage"))
const ReportsPage = lazy(() => import("@/pages/admin/ReportsPage"))
const AuditLogPage = lazy(() => import("@/pages/admin/AuditLogPage"))
const AdminPanelPage = lazy(() => import("@/pages/admin/AdminPanelPage"))
const ScannerPage = lazy(() => import("@/pages/security/ScannerPage"))
const ScanResultPage = lazy(() => import("@/pages/security/ScanResultPage"))
const ScanHistoryPage = lazy(() => import("@/pages/security/ScanHistoryPage"))
const LoadPreviewPage = lazy(() => import("@/pages/LoadPreviewPage"))

function AppRoutes() {
  const { loadUser } = useAuthStore()
  const isMounted = useRef(false)

  useEffect(() => {
    if (!isMounted.current) {
      loadUser()
      isMounted.current = true
    }
  }, [loadUser])

  return (
    <Suspense fallback={<LoadingScreen />}>
      <Routes>
        <Route path="/login" element={<LoginPage />} />

        <Route element={<AppLayout />}>
          <Route path="/guides" element={<GuidesPage />} />

          <Route path="/employee" element={<EmployeeDashboard />} />
          <Route path="/employee/request" element={<RequestLeavePage />} />
          <Route path="/employee/history" element={<LeaveHistoryPage />} />
          <Route path="/employee/qr/:id" element={<QrDisplayPage />} />
          <Route path="/employee/profile" element={<MyProfilePage />} />

          <Route path="/supervisor" element={
            <RequireRole roles={["is_supervisor", "is_admin"]}><SupervisorDashboard /></RequireRole>
          } />
          <Route path="/supervisor/pending" element={
            <RequireRole roles={["is_supervisor", "is_admin"]}><PendingRequestsPage /></RequireRole>
          } />

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
          <Route path="/admin/panel" element={
            <RequireRole roles={["is_admin"]}><AdminPanelPage /></RequireRole>
          } />

        </Route>

        <Route element={<SecurityShell />}>
          <Route path="/security/scan" element={<ScannerPage />} />
          <Route path="/security/result" element={<ScanResultPage />} />
          <Route path="/security/history" element={<ScanHistoryPage />} />
        </Route>

        {import.meta.env.DEV && <Route path="/load-preview" element={<LoadPreviewPage />} />}
        <Route path="*" element={<Navigate to="/employee" replace />} />
      </Routes>
    </Suspense>
  )
}

export default function App() {
  return (
    <ErrorBoundary>
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
    </ErrorBoundary>
  )
}
