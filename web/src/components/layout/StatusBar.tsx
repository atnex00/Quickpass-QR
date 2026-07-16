import { useState, useEffect } from "react"
import { useAuthStore } from "@/stores/authStore"
import { useThemeStore } from "@/stores/themeStore"
import { Sun, Moon } from "lucide-react"

export default function StatusBar() {
  const { user } = useAuthStore()
  const { theme, setTheme } = useThemeStore()
  const [time, setTime] = useState(new Date())

  useEffect(() => {
    const id = setInterval(() => setTime(new Date()), 1000)
    return () => clearInterval(id)
  }, [])

  const fmt = (n: number) => n.toString().padStart(2, "0")
  const h = time.getHours(), m = time.getMinutes(), s = time.getSeconds()
  const role = user?.is_admin ? "Admin" : user?.is_supervisor ? "Supervisor" : user?.is_security ? "Security" : "Employee"

  const cycleTheme = () => {
    const next = theme === "light" ? "dark" : theme === "dark" ? "system" : "light"
    setTheme(next)
  }

  return (
    <header className="flex h-10 items-center justify-between border-b border-border bg-card px-4">
      <div className="flex items-center gap-3">
        <span className="text-sm font-semibold tabular-nums text-primary">
          {fmt(h)}:{fmt(m)}:{fmt(s)}
        </span>
        <span className="h-1.5 w-1.5 rounded-full bg-gold" />
      </div>
      <div className="flex items-center gap-2">
        <button
          onClick={cycleTheme}
          className="flex h-7 w-7 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
          title={`Theme: ${theme}`}
        >
          {theme === "dark" ? (
            <Moon className="h-3.5 w-3.5" />
          ) : theme === "light" ? (
            <Sun className="h-3.5 w-3.5" />
          ) : (
            <Sun className="h-3.5 w-3.5" />
          )}
        </button>
        <span className="text-sm text-muted-foreground">{user?.full_name}</span>
        <span className="rounded-full bg-accent px-2.5 py-0.5 text-xs font-medium text-accent-foreground">
          {role}
        </span>
      </div>
    </header>
  )
}
