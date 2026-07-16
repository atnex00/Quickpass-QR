import { Outlet, Navigate, useLocation } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import Sidebar from "./Sidebar"
import StatusBar from "./StatusBar"
import { Toaster } from "sonner"
import { Loader2 } from "lucide-react"

export default function AppLayout() {
  const { isAuthenticated, isLoading } = useAuthStore()
  const location = useLocation()

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="h-6 w-6 animate-spin text-primary" />
          <p className="text-sm text-muted-foreground">Loading...</p>
        </div>
      </div>
    )
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  return (
    <div className="flex h-screen overflow-hidden">
      <Sidebar />
      <div className="flex flex-1 flex-col overflow-hidden">
        <StatusBar />
        <main className="flex-1 overflow-y-auto bg-background p-4 pb-16 md:pb-4">
          <div key={location.pathname + location.search} className="page-enter">
            <Outlet />
          </div>
        </main>
      </div>
      <Toaster position="top-right" richColors />
    </div>
  )
}
