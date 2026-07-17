import api from "@/lib/api"

export async function downloadCsv(url: string, filename: string) {
  const res = await api.get(url, { responseType: "blob" })
  const blob = res.data
  const href = window.URL.createObjectURL(blob)
  const a = document.createElement("a")
  a.href = href
  a.download = filename
  document.body.appendChild(a)
  a.click()
  a.remove()
  window.URL.revokeObjectURL(href)
}
