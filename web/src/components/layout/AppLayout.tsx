import { Outlet, Navigate, useLocation } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import Sidebar from "./Sidebar"
import { Toaster } from "sonner"

export default function AppLayout() {
  const { isAuthenticated, isLoading } = useAuthStore()
  const location = useLocation()

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <div className="h-10 w-10 animate-spin rounded-full border-4 border-primary border-t-transparent" />
          <p className="text-sm text-[#9c9c9d]">Loading...</p>
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
      <main className="flex-1 overflow-y-auto bg-background p-6">
        <div key={location.pathname + location.search} className="page-enter">
          <Outlet />
        </div>
      </main>
      <Toaster position="top-right" richColors />
    </div>
  )
}
