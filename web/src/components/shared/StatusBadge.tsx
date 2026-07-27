import { Badge } from "@/components/ui/badge"
import type { LeaveStatus } from "@/types"

const statusVariantMap: Record<LeaveStatus, "pending" | "approved" | "rejected" | "active" | "completed" | "cancelled"> = {
  pending: "pending",
  approved: "approved",
  rejected: "rejected",
  active: "active",
  completed: "completed",
  cancelled: "cancelled",
}

const statusLabelMap: Record<LeaveStatus, string> = {
  pending: "Pending",
  approved: "Approved",
  rejected: "Rejected",
  active: "Active",
  completed: "Completed",
  cancelled: "Cancelled",
}

export default function StatusBadge({ status }: { status: LeaveStatus }) {
  return <Badge variant={statusVariantMap[status]}>{statusLabelMap[status]}</Badge>
}
