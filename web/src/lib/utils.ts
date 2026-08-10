import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatDate(date: string | Date) {
  // Date-only strings ("YYYY-MM-DD") have no timezone — parse as local
  // midnight, otherwise `new Date("2026-08-10")` is treated as UTC and
  // shifts a day for negative-offset timezones.
  const isDateOnly = typeof date === "string" && /^\d{4}-\d{2}-\d{2}$/.test(date)
  const d = isDateOnly ? new Date(`${date}T00:00:00`) : new Date(date)
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  }).format(d)
}

export function formatTime(time: string) {
  const [h, m] = time.split(":").map(Number)
  const period = h >= 12 ? "PM" : "AM"
  const hour = h > 12 ? h - 12 : h === 0 ? 12 : h
  return `${hour.toString().padStart(2, "0")}:${m.toString().padStart(2, "0")} ${period}`
}

export function formatDateTime(date: string) {
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(date))
}

export const statusColors: Record<string, string> = {
  pending: "text-amber-600 bg-amber-50 border-amber-200",
  approved: "text-primary bg-blue-50 border-blue-200",
  rejected: "text-destructive bg-red-50 border-red-200",
  active: "text-emerald-600 bg-emerald-50 border-emerald-200",
  completed: "text-secondary bg-blue-50 border-blue-200",
  cancelled: "text-gray-600 bg-gray-50 border-gray-200",
}

export const statusLabels: Record<string, string> = {
  pending: "Pending",
  approved: "Approved",
  rejected: "Rejected",
  active: "Active",
  completed: "Completed",
  cancelled: "Cancelled",
}
