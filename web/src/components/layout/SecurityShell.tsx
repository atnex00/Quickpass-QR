import { Navigate, useLocation } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import { Outlet } from "react-router"
import SecurityHeader from "./SecurityHeader"
import { Loader2 } from "lucide-react"

export default function SecurityShell() {
  const { user, isAuthenticated, isLoading } = useAuthStore()
  const location = useLocation()

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center bg-background">
        <Loader2 className="h-6 w-6 animate-spin text-primary" />
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
    <div className="flex h-screen flex-col overflow-hidden">
      <SecurityHeader />
      <main className="flex-1 overflow-y-auto bg-background">
        <div key={location.pathname + location.search} className="page-enter">
          <Outlet />
        </div>
      </main>
    </div>
  )
}
