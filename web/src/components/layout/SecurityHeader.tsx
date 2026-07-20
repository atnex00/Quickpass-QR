import { Link } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import { Button } from "@/components/ui/button"
import { LayoutDashboard, History, LogOut, ArrowLeft, Scan } from "lucide-react"
import { useNavigate } from "react-router"
import ThemeToggle from "./ThemeToggle"

interface SecurityHeaderProps {
  showBack?: boolean
  title?: string
}

export default function SecurityHeader({ showBack, title }: SecurityHeaderProps) {
  const { user, logout } = useAuthStore()
  const navigate = useNavigate()

  return (
    <header className="flex h-14 items-center justify-between border-b border-border bg-card px-4">
      <div className="flex items-center gap-3">
        {showBack && (
          <button
            onClick={() => navigate("/security/scan")}
            className="flex h-8 w-8 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
          >
            <ArrowLeft className="h-4 w-4" />
          </button>
        )}
        <img src="/app-icon.png" alt="QuickPass" className="h-7 w-7 rounded-md" />
        <div className="flex items-center gap-2">
          <span className="text-sm font-semibold text-foreground">
            {title || "Security Scanner"}
          </span>
        </div>
      </div>
      <div className="flex items-center gap-1">
        <ThemeToggle />
        {user && (
          <span className="hidden text-sm text-muted-foreground sm:block">
            {user.full_name}
          </span>
        )}
        <Link to="/employee">
          <Button variant="ghost" size="icon"><LayoutDashboard className="h-4 w-4" /></Button>
        </Link>
        <Link to="/security/history">
          <Button variant="ghost" size="icon"><History className="h-4 w-4" /></Button>
        </Link>
        <Button variant="ghost" size="icon" onClick={logout}>
          <LogOut className="h-4 w-4" />
        </Button>
      </div>
    </header>
  )
}
