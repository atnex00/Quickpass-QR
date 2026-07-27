import { useState, useRef, useEffect } from "react"
import { NavLink } from "react-router"
import { MoreHorizontal, type LucideIcon } from "lucide-react"
import { cn } from "@/lib/utils"

interface NavItem {
  to: string
  icon: LucideIcon
  label: string
}

interface MobileBottomBarProps {
  items: NavItem[]
}

const MAX_VISIBLE = 5

export default function MobileBottomBar({ items }: MobileBottomBarProps) {
  const [menuOpen, setMenuOpen] = useState(false)
  const menuRef = useRef<HTMLDivElement>(null)
  const buttonRef = useRef<HTMLButtonElement>(null)

  const visible = items.slice(0, MAX_VISIBLE)
  const overflow = items.slice(MAX_VISIBLE)

  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (
        menuRef.current &&
        !menuRef.current.contains(e.target as Node) &&
        buttonRef.current &&
        !buttonRef.current.contains(e.target as Node)
      ) {
        setMenuOpen(false)
      }
    }
    if (menuOpen) {
      document.addEventListener("mousedown", handleClickOutside)
      return () => document.removeEventListener("mousedown", handleClickOutside)
    }
  }, [menuOpen])

  return (
    <nav className="mobile-bottom-bar">
      {visible.map((link) => (
        <NavLink
          key={link.to}
          to={link.to}
          end={link.to === "/employee" || link.to === "/supervisor"}
          onClick={() => setMenuOpen(false)}
          className={({ isActive }) =>
            cn(
              "mobile-bottom-link",
              isActive && "mobile-bottom-link-active"
            )
          }
        >
          <link.icon className="mobile-bottom-icon" />
          <span className="mobile-bottom-label">{link.label}</span>
        </NavLink>
      ))}

      {overflow.length > 0 && (
        <div className="relative">
          <button
            ref={buttonRef}
            onClick={() => setMenuOpen((prev) => !prev)}
            className={cn(
              "mobile-bottom-link",
              menuOpen && "text-primary"
            )}
          >
            <MoreHorizontal className="mobile-bottom-icon" />
            <span className="mobile-bottom-label">More</span>
          </button>

          {menuOpen && (
            <div
              ref={menuRef}
              className="absolute bottom-full right-0 mb-2 w-44 rounded-sm border border-border bg-card py-1 shadow-lg"
            >
              {overflow.map((link) => (
                <NavLink
                  key={link.to}
                  to={link.to}
                  end={link.to === "/employee" || link.to === "/supervisor"}
                  onClick={() => setMenuOpen(false)}
                  className={({ isActive }) =>
                    cn(
                      "flex items-center gap-3 px-3 py-2 text-xs font-semibold transition-colors",
                      isActive
                        ? "text-primary"
                        : "text-muted-foreground hover:bg-accent hover:text-accent-foreground"
                    )
                  }
                >
                  <link.icon className="h-4 w-4 shrink-0" />
                  <span className="truncate">{link.label}</span>
                </NavLink>
              ))}
            </div>
          )}
        </div>
      )}
    </nav>
  )
}
