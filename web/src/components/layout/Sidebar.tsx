import { useState, useEffect } from "react"
import { NavLink, useNavigate, Link } from "react-router"
import {
  LayoutDashboard, Clock, Users, Building2, BarChart3,
  LogOut, ChevronLeft, ChevronRight, ShieldCheck, FileText, UserCheck,
  Scan, User, BookOpen,
} from "lucide-react"
import { cn } from "@/lib/utils"
import { useAuthStore } from "@/stores/authStore"
import { useMediaQuery } from "@/hooks/useMediaQuery"
import MobileBottomBar from "./MobileBottomBar"

const sections = [
  {
    label: "Operations",
    links: [
      { to: "/employee", icon: LayoutDashboard, label: "Dashboard" },
      { to: "/security/scan", icon: Scan, label: "Gate Scanner" },
    ],
  },
  {
    label: "Requests",
    links: [
      { to: "/employee/request", icon: FileText, label: "Request Leave" },
      { to: "/employee/history", icon: Clock, label: "Leave History" },
    ],
  },
  {
    label: "Management",
    links: [
      { to: "/supervisor", icon: UserCheck, label: "Supervisor" },
      { to: "/supervisor/pending", icon: ShieldCheck, label: "Pending" },
    ],
  },
  {
    label: "Admin",
    links: [
      { to: "/admin/employees", icon: Users, label: "Employees" },
      { to: "/admin/departments", icon: Building2, label: "Departments" },
      { to: "/admin/reports", icon: BarChart3, label: "Reports" },
    ],
  },
  {
    label: "Help",
    links: [
      { to: "/guides", icon: BookOpen, label: "User Guide" },
    ],
  },
]

export default function Sidebar() {
  const { user, logout } = useAuthStore()
  const navigate = useNavigate()
  const [collapsed, setCollapsed] = useState(false)
  const [time, setTime] = useState(new Date())

  useEffect(() => {
    const id = setInterval(() => setTime(new Date()), 1000)
    return () => clearInterval(id)
  }, [])

  const handleLogout = async () => {
    await logout()
    navigate("/login")
  }

  const fmt = (n: number) => n.toString().padStart(2, "0")
  const h = time.getHours(), m = time.getMinutes()

  const isAdmin = !!user?.is_admin
  const isSupervisor = !!user?.is_supervisor
  const isSecurity = !!user?.is_security

  const visibleSections = sections.filter((s) => {
    if (s.label === "Admin" && !isAdmin) return false
    if (s.label === "Management" && !isSupervisor && !isAdmin) return false
    if (s.label === "Operations" && isSecurity) return s.links.filter(l => l.to === "/security/scan").length > 0
    return true
  })

  const mobileNavItems = visibleSections
    .flatMap((s) => s.links)
    .filter((link) => {
      if (link.to.startsWith("/security") && !isSecurity && !isAdmin) return false
      if (link.to.startsWith("/supervisor") && !isSupervisor && !isAdmin) return false
      if (link.to.startsWith("/admin") && !isAdmin) return false
      return true
    })

  const isMobile = useMediaQuery("(max-width: 767px)")

  if (isMobile) {
    return <MobileBottomBar items={mobileNavItems} />
  }

  return (
    <aside className={cn(
      "flex flex-col border-r border-border bg-card transition-all duration-300 ease-[cubic-bezier(0.16,1,0.3,1)] shrink-0",
      collapsed ? "w-14" : "w-56"
    )}>
      {/* Logo + clock */}
      <div className={cn(
        "flex items-center border-b border-border transition-all duration-300",
        collapsed ? "h-14 justify-center px-1" : "h-14 gap-2 px-3"
      )}>
        {!collapsed ? (
          <>
            <img src="/logo.png" alt="ZANECO QuickPass" className="h-8 w-auto shrink-0" />
            <span className="ml-auto text-sm tabular-nums text-muted-foreground">{fmt(h)}:{fmt(m)}</span>
          </>
        ) : (
          <img src="/app-icon.png" alt="ZANECO QuickPass" className="h-7 w-7 rounded-md" />
        )}
      </div>

      {/* Nav sections */}
      <nav className="flex-1 overflow-y-auto py-1">
        {visibleSections.map((section) => (
          <div key={section.label}>
            {!collapsed && <p className="sidebar-section-label">{section.label}</p>}
            {section.links
              .filter((link) => {
                if (link.to.startsWith("/security") && !isSecurity && !isAdmin) return false
                if (link.to.startsWith("/supervisor") && !isSupervisor && !isAdmin) return false
                if (link.to.startsWith("/admin") && !isAdmin) return false
                return true
              })
              .map((link) => (
                <NavLink
                  key={link.to}
                  to={link.to}
                  end={link.to === "/employee" || link.to === "/supervisor"}
                  className={({ isActive }) =>
                    cn(
                      "flex items-center gap-3 mx-2 my-0.5 rounded-md px-2.5 py-2 text-sm font-medium transition-colors",
                      isActive ? "sidebar-active" : "sidebar-inactive"
                    )
                  }
                >
                  <link.icon className="h-4 w-4 shrink-0" />
                  {!collapsed && <span className="truncate">{link.label}</span>}
                </NavLink>
              ))}
          </div>
        ))}
      </nav>

      {/* Bottom controls */}
      <div className="border-t border-border p-2">
        <Link
          to="/employee/profile"
          className="flex w-full items-center gap-3 rounded-md px-2.5 py-2 text-sm font-medium text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
        >
          <User className="h-4 w-4 shrink-0" />
          {!collapsed && <span>Profile</span>}
        </Link>
        <button
          onClick={handleLogout}
          className="flex w-full items-center gap-3 rounded-md px-2.5 py-2 text-sm font-medium text-muted-foreground transition-colors hover:bg-accent hover:text-destructive"
        >
          <LogOut className="h-4 w-4 shrink-0" />
          {!collapsed && <span>Logout</span>}
        </button>
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="flex w-full items-center justify-center rounded-md py-1.5 text-muted-foreground transition-colors hover:text-foreground"
        >
          {collapsed ? <ChevronRight className="h-4 w-4" /> : <ChevronLeft className="h-4 w-4" />}
        </button>
      </div>
    </aside>
  )
}
