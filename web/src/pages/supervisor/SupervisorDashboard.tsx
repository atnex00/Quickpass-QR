import { useEffect } from "react"
import { Link } from "react-router"
import { useAuthStore } from "@/stores/authStore"
import { useLeaveStore } from "@/stores/leaveStore"
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { UserCheck, ShieldCheck, CalendarDays, ArrowRight } from "lucide-react"
import { Loader2 } from "lucide-react"

export default function SupervisorDashboard() {
  const { user } = useAuthStore()
  const { pendingRequests, isLoading, loadPendingRequests } = useLeaveStore()

  useEffect(() => {
    loadPendingRequests()
  }, [])

  if (isLoading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <Loader2 className="h-6 w-6 animate-spin text-primary" />
      </div>
    )
  }

  return (
    <div className="page-enter space-y-4">
      <div>
        <h1 className="text-2xl font-bold">Supervisor Dashboard</h1>
        <p className="text-sm text-muted-foreground">{user?.department_name}</p>
      </div>

      <Card className="border-l-4 border-l-primary">
        <CardContent className="flex items-center gap-4">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/15">
            <ShieldCheck className="h-5 w-5 text-primary" />
          </div>
          <div className="flex-1">
            <p className="text-3xl font-bold text-foreground">{pendingRequests.length}</p>
            <p className="text-sm text-muted-foreground">Pending Requests</p>
          </div>
          <Link to="/supervisor/pending">
            <Button variant="outline" size="sm">
              Review <ArrowRight className="h-3.5 w-3.5" />
            </Button>
          </Link>
        </CardContent>
      </Card>

      {pendingRequests.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Recent Pending Requests</CardTitle>
          </CardHeader>
          <CardContent className="space-y-1">
            {pendingRequests.slice(0, 5).map((req) => (
              <div
                key={req.leave_id}
                className="flex items-center justify-between rounded-md px-3 py-2 transition-colors hover:bg-accent"
              >
                <div className="flex items-center gap-3">
                  <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary/15 text-sm font-semibold text-primary">
                    {req.employee_name.charAt(0)}
                  </div>
                  <div>
                    <p className="text-sm font-medium text-foreground">{req.employee_name}</p>
                    <p className="text-xs text-muted-foreground">
                      {req.start_time} - {req.end_time}
                    </p>
                  </div>
                </div>
                <Link to="/supervisor/pending">
                  <Button variant="ghost" size="sm">Review</Button>
                </Link>
              </div>
            ))}
          </CardContent>
        </Card>
      )}
    </div>
  )
}
