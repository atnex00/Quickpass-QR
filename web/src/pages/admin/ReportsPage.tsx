import { useEffect, useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import api from "@/lib/api"
import { Loader2 } from "lucide-react"
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

const COLORS = ["#F59E0B", "#8B5CF6", "#EF4444", "#10B981", "#3B82F6"]

export default function ReportsPage() {
  const [deptData, setDeptData] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.get("/admin/reports", { params: { type: "department" } })
      .then((res) => setDeptData(res.data.data || []))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

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

  if (loading) {
    return (
      <div className="flex justify-center py-16">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Reports</h1>
        <p className="text-muted-foreground">Department-wise leave statistics</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Leave Requests by Department</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={350}>
              <BarChart data={barData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis dataKey="name" tick={{ fontSize: 12 }} />
                <YAxis />
                <Tooltip />
                <Bar dataKey="Pending" fill="#F59E0B" radius={[4, 4, 0, 0]} />
                <Bar dataKey="Approved" fill="#8B5CF6" radius={[4, 4, 0, 0]} />
                <Bar dataKey="Rejected" fill="#EF4444" radius={[4, 4, 0, 0]} />
                <Bar dataKey="Completed" fill="#10B981" radius={[4, 4, 0, 0]} />
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

      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Department Summary</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b text-left">
                  <th className="pb-3 font-semibold">Department</th>
                  <th className="pb-3 font-semibold">Total</th>
                  <th className="pb-3 font-semibold">Pending</th>
                  <th className="pb-3 font-semibold">Approved</th>
                  <th className="pb-3 font-semibold">Rejected</th>
                  <th className="pb-3 font-semibold">Completed</th>
                </tr>
              </thead>
              <tbody>
                {deptData.map((d: any) => (
                  <tr key={d.department_id} className="border-b last:border-0">
                    <td className="py-3 font-medium">{d.department_name}</td>
                    <td className="py-3">{d.total_requests}</td>
                    <td className="py-3 text-orange-600">{d.pending || 0}</td>
                    <td className="py-3 text-purple-600">{d.approved || 0}</td>
                    <td className="py-3 text-red-600">{d.rejected || 0}</td>
                    <td className="py-3 text-emerald-600">{d.completed || 0}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
