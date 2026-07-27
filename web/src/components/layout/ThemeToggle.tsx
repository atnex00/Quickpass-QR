import { useThemeStore } from "@/stores/themeStore"
import { Sun, Moon, Monitor } from "lucide-react"

const OPTIONS = [
  { value: "light", icon: Sun, label: "Light" },
  { value: "system", icon: Monitor, label: "System" },
  { value: "dark", icon: Moon, label: "Dark" },
] as const

export default function ThemeToggle() {
  const { theme, setTheme, resolved } = useThemeStore()

  const cycle = () => {
    const next = theme === "light" ? "system" : theme === "dark" ? "light" : "dark"
    setTheme(next)
  }

  const Icon = theme === "dark" ? Moon : theme === "light" ? Sun : Monitor

  return (
    <div className="flex items-center rounded-md border border-border bg-background p-0.5">
      {OPTIONS.map((opt) => {
        const OptIcon = opt.icon
        const active = theme === opt.value
        return (
          <button
            key={opt.value}
            type="button"
            onClick={() => setTheme(opt.value)}
            title={`${opt.label}${theme === "system" && opt.value === "system" ? ` (${resolved()})` : ""}`}
            aria-label={`${opt.label} theme`}
            aria-pressed={active}
            className={`flex h-7 w-7 items-center justify-center rounded transition-colors ${
              active
                ? "bg-primary text-primary-foreground"
                : "text-muted-foreground hover:bg-accent hover:text-accent-foreground"
            }`}
          >
            <OptIcon className="h-3.5 w-3.5" />
          </button>
        )
      })}
      <button
        type="button"
        onClick={cycle}
        title="Cycle theme"
        aria-label="Cycle theme"
        className="flex h-7 items-center gap-1 rounded px-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
      >
        <Icon className="h-3.5 w-3.5" />
      </button>
    </div>
  )
}
