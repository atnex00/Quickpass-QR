import { useEffect, useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import api from "@/lib/api"
import { downloadCsv } from "@/lib/download"
import { toast } from "sonner"
import { Loader2, Download } from "lucide-react"
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from "recharts"
import { format } from "date-fns"

const COLORS = ["#f59e0b", "#0d9488", "#dc2626", "#fbbf24", "#a8a29e"]

const TYPES = [
  { label: "Department", value: "department" },
  { label: "Summary", value: "summary" },
  { label: "Daily", value: "daily" },
]

export default function ReportsPage() {
  const [deptData, setDeptData] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [type, setType] = useState<"department" | "summary" | "daily">("department")
  const [startDate, setStartDate] = useState("")
  const [endDate, setEndDate] = useState("")
  const [exporting, setExporting] = useState(false)

  const load = () => {
    setLoading(true)
    const params: Record<string, string> = { type }
    if (startDate) params.start_date = startDate
    if (endDate) params.end_date = endDate
    api.get("/admin/reports", { params })
      .then((res) => setDeptData(res.data.data || []))
      .catch(() => {})
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [type])

  const handleExport = async () => {
    setExporting(true)
    try {
      const params = new URLSearchParams({ resource: "reports", type })
      if (startDate) params.set("start_date", startDate)
      if (endDate) params.set("end_date", endDate)
      await downloadCsv(`/admin/export?${params.toString()}`, "leave_report.csv")
    } catch {
      toast.error("Could not export CSV")
    }
    setExporting(false)
  }

  const pieData = deptData.flatMap((d) => [
    { name: `${d.department_name} - Pending`, value: parseInt(d.pending || 0) },
    { name: `${d.department_name} - Approved`, value: parseInt(d.approved || 0) },
    { name: `${d.department_name} - Rejected`, value: parseInt(d.rejected || 0) },
    { name: `${d.department_name} - Completed`, value: parseInt(d.completed || 0) },
  ]).filter((d) => d.value > 0)

  const barData = deptData.map((d) => ({
    name: d.department_code || d.department_name,
    Pending: parseInt(d.pending || 0),
    Approved: parseInt(d.approved || 0),
    Rejected: parseInt(d.rejected || 0),
    Completed: parseInt(d.completed || 0),
  }))

  return (
    <div className="page-enter space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">Reports</h1>
          <p className="text-muted-foreground">Department-wise leave statistics</p>
        </div>
        <Button variant="outline" size="sm" onClick={handleExport} disabled={exporting}>
          {exporting ? <Loader2 className="h-4 w-4 animate-spin" /> : <Download className="h-4 w-4" />}
          Export CSV
        </Button>
      </div>

      <div className="flex flex-wrap items-center gap-3">
        <div className="inline-flex rounded-lg border border-border bg-card p-1">
          {TYPES.map((t) => (
            <button
              key={t.value}
              onClick={() => setType(t.value as any)}
              className={`rounded-md px-3 py-1.5 text-sm font-medium transition-colors ${
                type === t.value ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:bg-accent"
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>
        <input
          type="date"
          value={startDate}
          onChange={(e) => setStartDate(e.target.value)}
          className="h-9 rounded-md border border-input bg-card px-3 text-sm text-foreground"
        />
        <input
          type="date"
          value={endDate}
          onChange={(e) => setEndDate(e.target.value)}
          className="h-9 rounded-md border border-input bg-card px-3 text-sm text-foreground"
        />
        <Button variant="secondary" size="sm" onClick={load}>Apply</Button>
      </div>

      {loading ? (
        <div className="flex justify-center py-16">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
      ) : (
        <div className="space-y-4">
          {type === "department" && (
            <div className="grid gap-6 lg:grid-cols-2">
              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">Leave Requests by Department</CardTitle>
                </CardHeader>
                <CardContent>
                  <ResponsiveContainer width="100%" height={350}>
                    <BarChart data={barData}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#44403c" />
                      <XAxis dataKey="name" tick={{ fontSize: 12 }} />
                      <YAxis />
                      <Tooltip />
                      <Bar dataKey="Pending" fill="#f59e0b" radius={[4, 4, 0, 0]} />
                      <Bar dataKey="Approved" fill="#0d9488" radius={[4, 4, 0, 0]} />
                      <Bar dataKey="Rejected" fill="#dc2626" radius={[4, 4, 0, 0]} />
                      <Bar dataKey="Completed" fill="#fbbf24" radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-lg">Status Distribution</CardTitle>
                </CardHeader>
                <CardContent>
                  <ResponsiveContainer width="100%" height={350}>
                    <PieChart>
                      <Pie
                        data={pieData}
                        cx="50%"
                        cy="50%"
                        innerRadius={60}
                        outerRadius={100}
                        paddingAngle={2}
                        dataKey="value"
                      >
                        {pieData.map((_, i) => (
                          <Cell key={i} fill={COLORS[i % COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip />
                      <Legend />
                    </PieChart>
                  </ResponsiveContainer>
                </CardContent>
              </Card>
            </div>
          )}

          <Card>
            <CardHeader>
              <CardTitle className="text-lg">
                {type === "daily" ? "Daily Leave Requests" : type === "summary" ? "Leave Summary" : "Department Summary"}
              </CardTitle>
            </CardHeader>
            <CardContent>
              {deptData.length === 0 ? (
                <p className="py-8 text-center text-sm text-muted-foreground">No data found for the selected range</p>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b text-left">
                        <th className="pb-3 font-semibold">
                          {type === "daily" || type === "summary" ? "Employee" : "Department"}
                        </th>
                        {type !== "department" && (
                          <th className="pb-3 font-semibold">Date</th>
                        )}
                        <th className="pb-3 font-semibold">Total</th>
                        <th className="pb-3 font-semibold">Pending</th>
                        <th className="pb-3 font-semibold">Approved</th>
                        <th className="pb-3 font-semibold">Rejected</th>
                        <th className="pb-3 font-semibold">Completed</th>
                      </tr>
                    </thead>
                    <tbody>
                      {deptData.map((d: any, i: number) => (
                        <tr key={d.leave_id || d.department_id || i} className="border-b last:border-0">
                          <td className="py-3 font-medium">
                            {type === "daily" || type === "summary"
                              ? `${d.employee_name} (${d.employee_id})`
                              : d.department_name}
                          </td>
                          {type !== "department" && (
                            <td className="py-3">{d.leave_date}</td>
                          )}
                          <td className="py-3">{d.total_requests ?? 1}</td>
                          <td className="py-3 text-[#f59e0b]">{d.pending || 0}</td>
                          <td className="py-3 text-[#0d9488]">{d.approved || 0}</td>
                          <td className="py-3 text-destructive">{d.rejected || 0}</td>
                          <td className="py-3 text-[#fbbf24]">{d.completed || 0}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  )
}
