import { Navigate, useLocation } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import { Outlet } from "react-router"

export default function SecurityShell() {
  const { user, isAuthenticated, isLoading } = useAuthStore()
  const location = useLocation()

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center bg-background">
        <div className="h-10 w-10 animate-spin rounded-full border-4 border-primary border-t-transparent" />
      </div>
    )
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  if (user && !user.is_security && !user.is_admin) {
    return <Navigate to="/employee" replace />
  }

  return (
    <div key={location.pathname + location.search} className="page-enter">
      <Outlet />
    </div>
  )
}
