import { useEffect, useState } from "react"
import { useLeaveStore } from "@/stores/leaveStore"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import StatusBadge from "@/components/shared/StatusBadge"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Textarea } from "@/components/ui/textarea"
import { toast } from "sonner"
import { formatDate, formatTime } from "@/lib/utils"
import { useAuthStore } from "@/stores/authStore"
import api from "@/lib/api"
import { CheckCircle, XCircle, Loader2, Inbox, User, Undo2, Trash2 } from "lucide-react"

export default function PendingRequestsPage() {
  const {
    pendingRequests, isLoading, loadPendingRequests,
    approvedLeaves, loadApprovedLeaves,
    approveLeave, rejectLeave, revokeApproval,
  } = useLeaveStore()
  const [rejectId, setRejectId] = useState<string | null>(null)
  const [rejectReason, setRejectReason] = useState("")
  const [actionLoading, setActionLoading] = useState<string | null>(null)

  useEffect(() => {
    loadPendingRequests()
    loadApprovedLeaves()
  }, [])

  const handleApprove = async (leaveId: string) => {
    setActionLoading(leaveId)
    const ok = await approveLeave(leaveId)
    if (ok) toast.success("Leave approved")
    else toast.error("Could not approve — try again")
    setActionLoading(null)
    loadApprovedLeaves()
  }

  const handleReject = async () => {
    if (!rejectId || !rejectReason.trim()) return
    setActionLoading(rejectId)
    const ok = await rejectLeave(rejectId, rejectReason.trim())
    if (ok) toast.success("Leave rejected")
    else toast.error("Could not reject — try again")
    setActionLoading(null)
    setRejectId(null)
    setRejectReason("")
  }

  const handleRevoke = async (leaveId: string) => {
    setActionLoading(leaveId)
    const ok = await revokeApproval(leaveId)
    if (ok) {
      toast.success("Approval revoked — request moved back to pending")
      loadPendingRequests()
    } else {
      toast.error("Could not revoke")
    }
    setActionLoading(null)
  }

  const handleDelete = async (leaveId: string) => {
    setActionLoading(leaveId)
    try {
      await api.delete(`/leave/${leaveId}`)
      toast.success("Leave record deleted")
      loadApprovedLeaves()
    } catch (err: any) {
      toast.error(err.response?.data?.message || "Could not delete")
    }
    setActionLoading(null)
  }

  const { user } = useAuthStore()

  return (
    <div className="page-enter space-y-8">
      <div>
        <h1 className="text-2xl font-bold">Pending Requests</h1>
        <p className="text-muted-foreground">
          {pendingRequests.length} request{pendingRequests.length !== 1 ? "s" : ""} awaiting review
        </p>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-12">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
      ) : pendingRequests.length === 0 ? (
        <div className="empty-state">
          <div className="empty-icon">
            <Inbox className="h-6 w-6 text-muted-foreground" />
          </div>
          <div>
            <h3>All caught up!</h3>
            <p>No pending requests awaiting your review</p>
          </div>
        </div>
      ) : (
        <div className="space-y-4">
          {pendingRequests.map((req) => (
            <Card key={req.leave_id} className="card-hover p-4">
              <div className="flex items-start gap-4">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary text-lg font-bold text-white">
                  {req.employee_name.charAt(0)}
                </div>
                <div className="flex-1">
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="font-semibold">{req.employee_name}</h3>
                      {req.employee_position && (
                        <p className="text-sm text-muted-foreground">{req.employee_position}</p>
                      )}
                    </div>
                    <StatusBadge status={req.status} />
                  </div>

                  <div className="mt-3 grid grid-cols-2 gap-2 text-sm">
                    <div>
                      <span className="text-muted-foreground">Date: </span>
                      <span className="font-medium">{formatDate(req.leave_date)}</span>
                    </div>
                    <div>
                      <span className="text-muted-foreground">Time: </span>
                      <span className="font-medium">{formatTime(req.start_time)} - {formatTime(req.end_time)}</span>
                    </div>
                  </div>

                  <p className="mt-2 text-sm text-muted-foreground">{req.reason}</p>

                  <div className="mt-4 flex gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      className="gap-1.5 border-destructive text-destructive hover:bg-destructive/10"
                      disabled={actionLoading === req.leave_id}
                      onClick={() => setRejectId(req.leave_id)}
                    >
                      <XCircle className="h-4 w-4" /> Reject
                    </Button>
                    <Button
                      size="sm"
                      className="gap-1.5 bg-primary hover:brightness-110"
                      disabled={actionLoading === req.leave_id}
                      onClick={() => handleApprove(req.leave_id)}
                    >
                      {actionLoading === req.leave_id ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <CheckCircle className="h-4 w-4" />
                      )}
                      Approve
                    </Button>
                    {user?.is_admin && (
                      <Button
                        variant="outline"
                        size="sm"
                        className="gap-1.5 border-destructive/40 text-destructive hover:bg-destructive/5"
                        disabled={actionLoading === req.leave_id}
                        onClick={() => handleDelete(req.leave_id)}
                        title="Delete (admin only)"
                      >
                        {actionLoading === req.leave_id ? (
                          <Loader2 className="h-4 w-4 animate-spin" />
                        ) : (
                          <Trash2 className="h-4 w-4" />
                        )}
                      </Button>
                    )}
                  </div>
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* Approved / Revoke Section */}
      <div>
        <h2 className="text-xl font-bold">Approved Leaves</h2>
        <p className="text-muted-foreground">Revoke approvals to move requests back to pending</p>
      </div>

      {approvedLeaves.length === 0 ? (
        <p className="text-sm text-muted-foreground">No approved leaves yet</p>
      ) : (
        <div className="space-y-4">
          {approvedLeaves.map((req) => (
            <Card key={req.leave_id} className="p-4 border-purple-200/50">
              <div className="flex items-start gap-4">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-purple-100 text-lg font-bold text-purple-700">
                  {req.employee_name.charAt(0)}
                </div>
                <div className="flex-1">
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="font-semibold">{req.employee_name}</h3>
                      {req.employee_position && (
                        <p className="text-sm text-muted-foreground">{req.employee_position}</p>
                      )}
                    </div>
                    <StatusBadge status={req.status} />
                  </div>

                  <div className="mt-3 grid grid-cols-2 gap-2 text-sm">
                    <div>
                      <span className="text-muted-foreground">Date: </span>
                      <span className="font-medium">{formatDate(req.leave_date)}</span>
                    </div>
                    <div>
                      <span className="text-muted-foreground">Time: </span>
                      <span className="font-medium">{formatTime(req.start_time)} - {formatTime(req.end_time)}</span>
                    </div>
                  </div>

                  <p className="mt-2 text-sm text-muted-foreground">{req.reason}</p>

                  <div className="mt-4">
                    <Button
                      variant="outline"
                      size="sm"
                      className="gap-1.5 border-amber-400 text-amber-700 hover:bg-amber-50"
                      disabled={actionLoading === req.leave_id}
                      onClick={() => handleRevoke(req.leave_id)}
                    >
                      {actionLoading === req.leave_id ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <Undo2 className="h-4 w-4" />
                      )}
                      Revoke Approval
                    </Button>
                    {user?.is_admin && (
                      <Button
                        variant="outline"
                        size="sm"
                        className="gap-1.5 border-red-300 text-red-600 hover:bg-red-50"
                        disabled={actionLoading === req.leave_id}
                        onClick={() => handleDelete(req.leave_id)}
                      >
                        {actionLoading === req.leave_id ? (
                          <Loader2 className="h-4 w-4 animate-spin" />
                        ) : (
                          <Trash2 className="h-4 w-4" />
                        )}
                        Delete
                      </Button>
                    )}
                  </div>
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* Reject Dialog */}
      <Dialog open={!!rejectId} onOpenChange={(o) => { if (!o) setRejectId(null) }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Reject Leave Request</DialogTitle>
            <DialogDescription>Provide a reason for rejection</DialogDescription>
          </DialogHeader>
          <Textarea
            placeholder="Enter rejection reason..."
            value={rejectReason}
            onChange={(e) => setRejectReason(e.target.value)}
            rows={3}
          />
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => { setRejectId(null); setRejectReason("") }}>
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={handleReject}
              disabled={!rejectReason.trim() || actionLoading === rejectId}
            >
              {actionLoading === rejectId ? <Loader2 className="h-4 w-4 animate-spin" /> : "Reject"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
