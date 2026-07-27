import { Navigate } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import type { ReactNode } from "react"

interface Props {
  roles: string[]
  children: ReactNode
}

export default function RequireRole({ roles, children }: Props) {
  const { user, isAuthenticated, isLoading } = useAuthStore()

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center">
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

  const hasRole = roles.some((role) => user?.[role as keyof typeof user])
  if (!hasRole) {
    return <Navigate to="/employee" replace />
  }

  return <>{children}</>
}
