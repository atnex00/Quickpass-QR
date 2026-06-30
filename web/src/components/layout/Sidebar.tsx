import { NavLink, useNavigate } from "react-router"
import {
  LayoutDashboard, Clock, QrCode, Users, Building2, BarChart3,
  LogOut, ChevronLeft, ChevronRight, ShieldCheck, FileText, UserCheck,
  Scan, History, User,
} from "lucide-react"
import { cn } from "@/lib/utils"
import { useAuthStore } from "@/stores/authStore"
import { useState } from "react"

const employeeLinks = [
  { to: "/employee", icon: LayoutDashboard, label: "Dashboard" },
  { to: "/employee/request", icon: FileText, label: "Request Leave" },
  { to: "/employee/history", icon: Clock, label: "Leave History" },
  { to: "/employee/profile", icon: User, label: "My Profile" },
]

const supervisorLinks = [
  { to: "/supervisor", icon: UserCheck, label: "Supervisor Dashboard" },
  { to: "/supervisor/pending", icon: ShieldCheck, label: "Pending Requests" },
]

const adminLinks = [
  { to: "/admin/employees", icon: Users, label: "Employees" },
  { to: "/admin/departments", icon: Building2, label: "Departments" },
  { to: "/admin/reports", icon: BarChart3, label: "Reports" },
]

const scannerLinks = [
  { to: "/security/scan", icon: Scan, label: "Scan QR" },
  { to: "/security/history", icon: History, label: "Scan History" },
]

export default function Sidebar() {
  const { user, logout } = useAuthStore()
  const navigate = useNavigate()
  const [collapsed, setCollapsed] = useState(false)

  const handleLogout = async () => {
    await logout()
    navigate("/login")
  }

  const baseLinks = user?.is_admin
    ? [...employeeLinks, ...supervisorLinks, ...adminLinks, ...scannerLinks]
    : user?.is_supervisor
      ? [...employeeLinks, ...supervisorLinks, ...scannerLinks]
      : [...employeeLinks, ...scannerLinks]

  return (
    <aside className={cn(
      "flex flex-col border-r border-border bg-card transition-all duration-300 ease-[cubic-bezier(0.16,1,0.3,1)] shrink-0",
      collapsed ? "w-16" : "w-64"
    )}>
      {/* Logo */}
      <div className={cn(
        "flex h-16 items-center gap-3 border-b border-border px-4 transition-all duration-300",
        collapsed && "justify-center px-2"
      )}>
        {!collapsed ? (
          <>
            <div className="flex h-9 w-9 items-center justify-center rounded-lg sidebar-active shadow-sm">
              <QrCode className="h-5 w-5 text-white" />
            </div>
            <div className="min-w-0">
              <span className="text-lg font-black text-primary block leading-none">Quickpass</span>
              <p className="text-[10px] font-semibold uppercase tracking-[0.08em] text-muted-foreground leading-tight mt-0.5 truncate">
                {user?.is_admin ? "Admin Console" : user?.is_supervisor ? "Supervisor Portal" : "Employee Portal"}
              </p>
            </div>
          </>
        ) : (
          <div className="flex h-9 w-9 items-center justify-center rounded-lg sidebar-active shadow-sm">
            <QrCode className="h-5 w-5 text-white" />
          </div>
        )}
        <button
          onClick={() => setCollapsed(!collapsed)}
          className={cn("rounded-lg p-1.5 hover:bg-accent transition-all duration-300", collapsed && "ml-0")}
        >
          {collapsed ? <ChevronRight className="h-4 w-4" /> : <ChevronLeft className="h-4 w-4" />}
        </button>
      </div>

      {/* Nav */}
      <nav className="flex-1 space-y-0.5 overflow-y-auto p-3">
        {baseLinks.map((link) => (
          <NavLink
            key={link.to}
            to={link.to}
            className={({ isActive }) =>
              cn(
                "sidebar-item flex items-center gap-3 rounded-lg px-3 py-2.5 text-xs font-semibold transition-all duration-200",
                isActive
                  ? "sidebar-active text-white shadow-sm"
                  : "text-muted-foreground hover:bg-accent/60 hover:text-accent-foreground"
              )
            }
          >
            <link.icon className="h-5 w-5 shrink-0" />
            {!collapsed && <span className="truncate">{link.label}</span>}
          </NavLink>
        ))}
      </nav>

      {/* Logout */}
      <div className="border-t border-border p-3">
        <button
          onClick={handleLogout}
          className="sidebar-item flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-xs font-semibold text-muted-foreground transition-all duration-200 hover:bg-accent/60 hover:text-destructive"
        >
          <LogOut className="h-5 w-5 shrink-0" />
          {!collapsed && <span>Logout</span>}
        </button>
      </div>
    </aside>
  )
}
