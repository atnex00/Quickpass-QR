import { useAuthStore } from "@/stores/authStore"
import { BookOpen, ChevronDown } from "lucide-react"
import { useState } from "react"
import type { Employee } from "@/types"

type GuideUser = Pick<Employee, "is_security" | "is_admin" | "is_supervisor">

const guides = [
  {
    role: "For All Employees",
    show: () => true,
    items: [
      {
        title: "How to Request Leave",
        steps: [
          'Go to "Request Leave" in the sidebar.',
          "Set your start time (when you'll leave) and end time (when you'll return).",
          "Enter a reason for your leave (at least 5 characters).",
          'Click "Submit Request" — it will be sent to your supervisor for approval.',
          "Wait for your supervisor to approve. You'll see the status change on your dashboard.",
        ],
      },
      {
        title: "How to View Your QR Pass",
        steps: [
          "After your leave is approved, go to your Dashboard.",
          'Click on the leave request in "Recent Requests."',
          "The Gate Pass page shows your EXIT and ENTRY QR codes.",
          "QR codes appear only after a supervisor approves your request.",
          "EXIT QR is valid 15 minutes before and after your scheduled start time.",
          "Security will scan these at the gate when you leave and return.",
        ],
      },
      {
        title: "How to Check Leave History",
        steps: [
          'Go to "Leave History" in the sidebar.',
          "Use the filter buttons to view Pending, Approved, Rejected, or Completed requests.",
          "Click any entry to view its QR pass.",
        ],
      },
    ],
  },
  {
    role: "For Security Guards",
    show: (u: GuideUser | null) => u?.is_security || u?.is_admin,
    items: [
      {
        title: "How to Scan a QR Code",
        steps: [
          'Go to "Gate Scanner" in the sidebar (or log in as Security to land there automatically).',
          'Click "Start Camera" to activate the scanner.',
          "Point the camera at the employee's QR code (phone screen or printed).",
          "Hold steady — the scanner will detect and validate the code automatically.",
          "Green checkmark = valid scan. Red X = invalid or expired.",
          "If the camera isn't working, paste the QR data manually in the text field.",
        ],
      },
      {
        title: "How to View Scan History",
        steps: [
          'Go to "Scan History" in the sidebar.',
          "See a list of all recent scans with timestamps and validity status.",
          "Green badges show successful scans, red badges show failed attempts.",
        ],
      },
    ],
  },
  {
    role: "For Supervisors",
    show: (u: GuideUser | null) => u?.is_supervisor || u?.is_admin,
    items: [
      {
        title: "How to Approve or Reject a Leave",
        steps: [
          'Go to "Pending" in the sidebar under Management.',
          "Review the employee's name, date, time, and reason.",
          'Click the green "Approve" button to generate QR codes and approve the leave.',
          'Click the red "Reject" button to decline — you must provide a reason.',
          "Approved leaves appear in the Approved section below, where you can revoke if needed.",
          "Once approved, the employee can view their QR pass on their dashboard.",
        ],
      },
      {
        title: "How to Revoke an Approval",
        steps: [
          "Scroll to the Approved Leaves section on the Pending page.",
          'Click "Revoke Approval" to move the request back to pending.',
          "This clears the QR codes — the employee will need to be re-approved.",
        ],
      },
    ],
  },
  {
    role: "For Administrators",
    show: (u: GuideUser | null) => u?.is_admin,
    items: [
      {
        title: "How to Manage Employees",
        steps: [
          'Go to "Employees" in the sidebar under Admin.',
          "Use the search bar to find employees by name or ID.",
          "Filter by department, status, or role using the dropdowns.",
          'Click the edit icon to update employee details.',
          "Use the toggle buttons to grant admin, supervisor, or security roles.",
          "The active/inactive toggle lets you deactivate accounts without deleting them.",
        ],
      },
      {
        title: "How to Manage Departments",
        steps: [
          'Go to "Departments" in the sidebar under Admin.',
          "View all departments in the organization.",
          'Click "Add Department" to create a new one.',
          "Hover over a department card and click the trash icon to delete it.",
        ],
      },
      {
        title: "How to View Reports",
        steps: [
          'Go to "Reports" in the sidebar under Admin.',
          "View the bar chart showing leave requests by department and status.",
          "The pie chart shows the overall status distribution.",
          "The summary table breaks down counts per department.",
        ],
      },
    ],
  },
]

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  const [open, setOpen] = useState(true)
  return (
    <div className="panel-card">
      <button
        onClick={() => setOpen(!open)}
        className="panel-card-header flex w-full items-center justify-between text-left cursor-pointer"
      >
        <h3>{title}</h3>
        <ChevronDown className={`h-3.5 w-3.5 text-muted-foreground/50 transition-transform ${open ? "" : "-rotate-90"}`} />
      </button>
      {open && <div className="panel-card-body space-y-4">{children}</div>}
    </div>
  )
}

function GuideItem({ title, steps }: { title: string; steps: string[] }) {
  return (
    <div>
      <p className="text-sm font-semibold text-foreground mb-2">{title}</p>
      <ol className="space-y-1.5">
        {steps.map((step, i) => (
          <li key={i} className="flex items-start gap-2 text-xs text-muted-foreground">
            <span className="flex h-4 w-4 shrink-0 items-center justify-center rounded-full bg-primary/15 text-[9px] font-bold text-primary mt-0.5">
              {i + 1}
            </span>
            {step}
          </li>
        ))}
      </ol>
    </div>
  )
}

export default function GuidesPage() {
  const { user } = useAuthStore()

  return (
    <div className="page-enter space-y-4">
      <div className="flex items-center gap-3">
        <div className="flex h-9 w-9 items-center justify-center rounded border border-border bg-muted">
          <BookOpen className="h-4 w-4 text-muted-foreground" />
        </div>
        <div>
          <h1 className="text-xl font-bold font-display">User Guide</h1>
          <p className="text-xs text-muted-foreground">How to use ZANECO QuickPass</p>
        </div>
      </div>

      <div className="space-y-4">
        {guides
          .filter((g) => g.show(user))
          .map((group) => (
            <Section key={group.role} title={group.role}>
              {group.items.map((item) => (
                <GuideItem key={item.title} title={item.title} steps={item.steps} />
              ))}
            </Section>
          ))}
      </div>
    </div>
  )
}
