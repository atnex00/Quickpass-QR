import { Navigate, useLocation } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import { Outlet } from "react-router"

export default function SecurityShell() {
  const { isAuthenticated, isLoading } = useAuthStore()
  const location = useLocation()

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
        <div className="h-10 w-10 animate-spin rounded-full border-4 border-emerald-400 border-t-transparent" />
      </div>
    )
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  return (
    <div key={location.pathname + location.search} className="page-enter">
      <Outlet />
    </div>
  )
}
