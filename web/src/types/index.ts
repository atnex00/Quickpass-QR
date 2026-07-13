export interface Employee {
  employee_id: string
  full_name: string
  position: string
  department_id: string
  department_name: string
  email: string
  is_supervisor: boolean
  is_admin: boolean
  is_security: boolean
  is_active: boolean
  profile_photo: string | null
  hire_date: string | null
}

export interface Department {
  department_id: string
  department_name: string
  department_code: string
  head_of_department: string
  is_active: boolean
}

export interface LeaveRequest {
  leave_id: string
  employee_id: string
  employee_name: string
  employee_position?: string
  employee_photo?: string
  department_id: string
  supervisor_id: string
  supervisor_name: string
  leave_date: string
  start_time: string
  end_time: string
  reason: string
  status: LeaveStatus
  out_qr_code: string | null
  in_qr_code: string | null
  out_qr_image: string | null
  in_qr_image: string | null
  out_scan_time: string | null
  in_scan_time: string | null
  rejection_reason: string | null
  created_at: string
  updated_at: string
}

export type LeaveStatus =
  | "pending"
  | "approved"
  | "rejected"
  | "active"
  | "completed"
  | "cancelled"

export interface ScanLog {
  log_id: number
  leave_id: string
  qr_type: "OUT" | "IN"
  scanned_by: string | null
  scan_time: string
  employee_name?: string
  employee_id?: string
  is_valid: boolean
  validation_message: string | null
}

export interface Pagination {
  total: number
  page: number
  limit: number
  pages: number
}

export interface ApiResponse<T> {
  success: boolean
  data: T
  message?: string
  pagination?: Pagination
}
