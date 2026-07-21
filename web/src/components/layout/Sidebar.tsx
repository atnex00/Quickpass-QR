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
      "flex flex-col border-r border-border glass transition-all duration-300 ease-[cubic-bezier(0.16,1,0.3,1)] shrink-0",
      collapsed ? "w-14" : "w-56"
    )}>
      {/* Logo + clock */}
      <div className={cn(
        "flex items-center border-b border-border/60 transition-all duration-300",
        collapsed ? "h-16 justify-center px-1" : "h-16 gap-2 px-3"
      )}>
        {!collapsed ? (
          <>
            <div className="brand-gradient flex h-9 w-9 shrink-0 items-center justify-center rounded-lg">
              <img src="/app-icon.png" alt="" className="h-5 w-5" />
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-sm font-bold font-display leading-tight text-foreground">QuickPass</p>
              <p className="text-[9px] font-semibold uppercase tracking-[0.1em] text-muted-foreground/60">Gate Access</p>
            </div>
            <span className="text-[10px] font-semibold tabular-nums text-muted-foreground/60">{fmt(h)}:{fmt(m)}</span>
          </>
        ) : (
          <div className="brand-gradient flex h-9 w-9 items-center justify-center rounded-lg">
            <img src="/app-icon.png" alt="QuickPass" className="h-5 w-5" />
          </div>
        )}
      </div>

      {/* Nav sections */}
      <nav className="flex-1 overflow-y-auto py-2">
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
                      "group relative flex items-center gap-3 mx-2 my-0.5 rounded-lg px-2.5 py-2 text-xs font-semibold transition-all duration-200",
                      isActive ? "sidebar-active text-primary" : "sidebar-inactive hover:bg-accent/60"
                    )
                  }
                >
                  <link.icon className="h-4 w-4 shrink-0 transition-transform duration-200 group-hover:scale-110" />
                  {!collapsed && <span className="truncate">{link.label}</span>}
                </NavLink>
              ))}
          </div>
        ))}
      </nav>

      {/* Bottom controls */}
      <div className="border-t border-border/60 p-2">
        <Link
          to="/employee/profile"
          className="flex w-full items-center gap-3 rounded-sm px-2.5 py-2 text-xs font-semibold text-muted-foreground transition-all duration-200 hover:text-foreground"
        >
          <User className="h-4 w-4 shrink-0" />
          {!collapsed && <span>Profile</span>}
        </Link>
        <button
          onClick={handleLogout}
          className="flex w-full items-center gap-3 rounded-sm px-2.5 py-2 text-xs font-semibold text-muted-foreground transition-all duration-200 hover:text-destructive"
        >
          <LogOut className="h-4 w-4 shrink-0" />
          {!collapsed && <span>Logout</span>}
        </button>
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="flex w-full items-center justify-center rounded-sm py-1.5 text-muted-foreground/40 hover:text-muted-foreground transition-colors"
        >
          {collapsed ? <ChevronRight className="h-3.5 w-3.5" /> : <ChevronLeft className="h-3.5 w-3.5" />}
        </button>
      </div>
    </aside>
  )
}
