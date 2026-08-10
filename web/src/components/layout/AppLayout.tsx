import { useState, useEffect } from "react"
import { Outlet, Navigate, useLocation, useNavigate } from "react-router"
import { LogOut } from "lucide-react"
import { useAuthStore } from "@/stores/authStore"
import { useMediaQuery } from "@/hooks/useMediaQuery"
import Sidebar from "./Sidebar"
import ThemeToggle from "./ThemeToggle"
import { Toaster } from "sonner"

function StatusBar() {
  const { user, logout } = useAuthStore()
  const navigate = useNavigate()
  const [time, setTime] = useState(new Date())
  const isMobile = useMediaQuery("(max-width: 767px)")

  useEffect(() => {
    const id = setInterval(() => setTime(new Date()), 1000)
    return () => clearInterval(id)
  }, [])

  const fmt = (n: number) => n.toString().padStart(2, "0")
  const h = time.getHours(), m = time.getMinutes(), s = time.getSeconds()
  const role = user?.is_admin ? "Admin" : user?.is_supervisor ? "Supervisor" : user?.is_security ? "Security" : "Employee"

  const handleLogout = async () => {
    await logout()
    navigate("/login")
  }

  return (
    <div className="status-bar">
      <div className="flex items-center gap-3">
        <span className="status-bar-time">{fmt(h)}:{fmt(m)}:{fmt(s)}</span>
      </div>
      <div className="flex items-center gap-2">
        <ThemeToggle />
        <span className="status-bar-user">{user?.full_name}</span>
        <span className="text-[9px] font-semibold uppercase tracking-[0.08em] text-muted-foreground/40">{role}</span>
        {isMobile && (
          <button
            onClick={handleLogout}
            title="Logout"
            aria-label="Logout"
            className="flex h-7 w-7 items-center justify-center rounded text-muted-foreground transition-colors hover:bg-accent hover:text-destructive"
          >
            <LogOut className="h-3.5 w-3.5" />
          </button>
        )}
      </div>
    </div>
  )
}

export default function AppLayout() {
  const { isAuthenticated, isLoading } = useAuthStore()
  const location = useLocation()

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-4">
          <div className="h-10 w-10 animate-spin rounded-full border-4 border-primary border-t-transparent" />
          <p className="text-sm text-muted-foreground">Loading...</p>
        </div>
      </div>
    )
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  return (
    <div className="app-aurora flex h-screen overflow-hidden">
      <div className="glow-blob h-72 w-72 bg-primary/20 -left-20 top-1/3" />
      <Sidebar />
      <div className="flex flex-1 flex-col overflow-hidden">
        <StatusBar />
        <main className="relative flex-1 overflow-y-auto p-4 pb-16 md:pb-4">
          <div key={location.pathname + location.search} className="page-enter">
            <Outlet />
          </div>
        </main>
      </div>
      <Toaster position="top-right" richColors />
    </div>
  )
}
