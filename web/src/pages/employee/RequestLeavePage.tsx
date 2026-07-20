import { useState } from "react"
import { useNavigate } from "react-router"
import { useLeaveStore } from "@/stores/leaveStore"
import { useAuthStore } from "@/stores/authStore"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import PageHeader from "@/components/layout/PageHeader"
import { toast } from "sonner"
import { Loader2, Lock, CalendarDays, User } from "lucide-react"

export default function RequestLeavePage() {
  const { user } = useAuthStore()
  const { submitLeave, isLoading } = useLeaveStore()
  const navigate = useNavigate()

  const today = new Date().toISOString().split("T")[0]
  const now = new Date()
  const defaultStart = `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`
  const defaultEnd = `${String(now.getHours() + 2).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`
  const [startTime, setStartTime] = useState(defaultStart)
  const [endTime, setEndTime] = useState(defaultEnd)
  const [reason, setReason] = useState("")

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (startTime >= endTime) {
      toast.error("End time must be after start time")
      return
    }

    if (reason.trim().length < 5) {
      toast.error("Reason must be at least 5 characters")
      return
    }

    const success = await submitLeave({
      leave_date: today,
      start_time: `${startTime}:00`,
      end_time: `${endTime}:00`,
      reason,
    })

    if (success) {
      toast.success("Leave request submitted successfully")
      navigate("/employee")
    } else {
      const msg = useLeaveStore.getState().error || "Failed to submit leave request"
      toast.error(msg)
    }
  }

  const calcDuration = () => {
    const [sh, sm] = startTime.split(":").map(Number)
    const [eh, em] = endTime.split(":").map(Number)
    const diff = eh * 60 + em - (sh * 60 + sm)
    if (diff <= 0) return "Invalid"
    const h = Math.floor(diff / 60)
    const m = diff % 60
    return h > 0 ? `${h}h ${m}m` : `${m}m`
  }

  return (
    <div className="page-enter mx-auto max-w-2xl space-y-4">
      <PageHeader
        title="Request Leave"
        subtitle="Submit a new temporary leave request"
        icon={<CalendarDays className="h-5 w-5" />}
      />

      <Card>
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            <User className="h-4 w-4 text-primary" /> Employee Information
          </CardTitle>
        </CardHeader>
        <CardContent className="grid gap-3 text-sm">
          <div className="flex justify-between border-b border-border/50 pb-2">
            <span className="text-muted-foreground">Employee ID</span>
            <span className="font-medium">{user?.employee_id}</span>
          </div>
          <div className="flex justify-between border-b border-border/50 pb-2">
            <span className="text-muted-foreground">Full Name</span>
            <span className="font-medium">{user?.full_name}</span>
          </div>
          <div className="flex justify-between border-b border-border/50 pb-2">
            <span className="text-muted-foreground">Position</span>
            <span className="font-medium">{user?.position}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-muted-foreground">Department</span>
            <span className="font-medium">{user?.department_name}</span>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Leave Details</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="flex items-center gap-3 rounded-lg border bg-muted/50 p-3">
              <CalendarDays className="h-5 w-5 text-muted-foreground" />
              <div className="flex-1">
                <p className="text-xs text-muted-foreground">Date</p>
                <p className="font-medium">{today}</p>
              </div>
              <Lock className="h-4 w-4 text-muted-foreground" />
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="startTime">Start Time (OUT)</Label>
                <Input
                  id="startTime"
                  type="time"
                  value={startTime}
                  onChange={(e) => setStartTime(e.target.value)}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="endTime">End Time (IN)</Label>
                <Input
                  id="endTime"
                  type="time"
                  value={endTime}
                  onChange={(e) => setEndTime(e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="rounded-lg border border-primary/20 bg-primary/5 p-3 text-sm">
              <span className="font-medium text-primary">Duration: </span>
              <span className="font-bold text-primary">{calcDuration()}</span>
            </div>

            <div className="space-y-2">
              <Label htmlFor="reason">Reason for Leave</Label>
              <Textarea
                id="reason"
                placeholder="Enter your reason for leave... (min. 5 characters)"
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                required
                rows={3}
              />
              {reason.length > 0 && reason.length < 5 && (
                <p className="text-xs text-destructive">Reason must be at least 5 characters</p>
              )}
            </div>

            <Button type="submit" className="w-full" size="lg" disabled={isLoading}>
              {isLoading ? <Loader2 className="h-5 w-5 animate-spin" /> : "Submit Request"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
