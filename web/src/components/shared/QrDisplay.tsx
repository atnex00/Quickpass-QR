import { useRef, useEffect, useState } from "react"
import QRCodeStyling from "qr-code-styling"
import { Clock, TimerOff, CheckCircle, User } from "lucide-react"
import { cn } from "@/lib/utils"

interface Props {
  qrData: string
  label: string
  color: "blue" | "green"
  date: string
  time: string
  scanTime?: string | null
  employeeName?: string
  employeePosition?: string
  isOut: boolean
}

function formatTime(secs: number) {
  const m = Math.floor(secs / 60).toString().padStart(2, "0")
  const s = (secs % 60).toString().padStart(2, "0")
  return `${m}:${s}`
}

function makeLogoSvg(): string {
  const s = 64, q = Math.round(s * 0.5), f = Math.round(s * 0.22)
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${s}" height="${s}" viewBox="0 0 ${s} ${s}">
    <rect width="${s}" height="${s}" rx="${Math.round(s * 0.2)}" fill="white"/>
    <g transform="translate(${(s - q) / 2}, ${(s - q) / 2 - f * 0.1})">
      <rect x="0" y="0" width="${Math.round(q * 0.38)}" height="${Math.round(q * 0.38)}" rx="3" fill="#8B5CF6"/>
      <rect x="${Math.round(q * 0.62)}" y="0" width="${Math.round(q * 0.38)}" height="${Math.round(q * 0.38)}" rx="3" fill="#8B5CF6"/>
      <rect x="0" y="${Math.round(q * 0.62)}" width="${Math.round(q * 0.38)}" height="${Math.round(q * 0.38)}" rx="3" fill="#8B5CF6"/>
      <line x1="${Math.round(q * 0.9)}" y1="${Math.round(q * 0.62)}" x2="${Math.round(q * 0.9)}" y2="${Math.round(q * 1.0)}" stroke="#8B5CF6" stroke-width="4" stroke-linecap="round"/>
      <line x1="${Math.round(q * 0.62)}" y1="${Math.round(q * 1.0)}" x2="${Math.round(q * 1.0)}" y2="${Math.round(q * 1.0)}" stroke="#8B5CF6" stroke-width="4" stroke-linecap="round"/>
      <line x1="${Math.round(q * 0.62)}" y1="${Math.round(q * 0.62)}" x2="${Math.round(q * 0.62)}" y2="${Math.round(q * 0.7)}" stroke="#8B5CF6" stroke-width="3" stroke-linecap="round"/>
      <line x1="${Math.round(q * 0.74)}" y1="${Math.round(q * 0.62)}" x2="${Math.round(q * 0.74)}" y2="${Math.round(q * 0.82)}" stroke="#8B5CF6" stroke-width="3" stroke-linecap="round"/>
    </g>
    <text x="${s / 2}" y="${s - f * 0.3}" text-anchor="middle" font-family="system-ui,sans-serif" font-weight="700" font-size="${f}" fill="#1E293B">PL</text>
  </svg>`
}

export default function QrDisplay({ qrData, label, color, date, time, scanTime, employeeName, employeePosition, isOut }: Props) {
  const canvasRef = useRef<HTMLDivElement>(null)
  const [windowState, setWindowState] = useState<'before' | 'during' | 'after'>('during')
  const [remaining, setRemaining] = useState(0)

  const isUsed = !!scanTime
  const accent = color === "blue" ? "#8B5CF6" : "#10B981"

  // Create QR on mount
  useEffect(() => {
    if (!canvasRef.current) return

    const svg = `data:image/svg+xml,${encodeURIComponent(makeLogoSvg())}`

    const qr = new QRCodeStyling({
      width: 450,
      height: 450,
      margin: 8,
      data: qrData,
      image: svg,
      qrOptions: { errorCorrectionLevel: "H" },
      imageOptions: { hideBackgroundDots: true, imageSize: 0.28, margin: 4 },
      dotsOptions: { type: "dots", color: "#000000" },
      cornersSquareOptions: { type: "extra-rounded", color: accent },
      cornersDotOptions: { type: "dot", color: accent },
      backgroundOptions: { color: "#ffffff" },
    })

    qr.append(canvasRef.current)

    return () => {
      if (canvasRef.current) canvasRef.current.innerHTML = ""
    }
  }, [qrData, accent])

  // Timer countdown
  useEffect(() => {
    let target = NaN
    try {
      const raw = atob(qrData)
      const parsed = JSON.parse(raw)
      if (parsed.timestamp) target = new Date(parsed.timestamp).getTime()
    } catch (_) {}
    if (isNaN(target)) {
      const fallback = `${date}T${time}`
      target = new Date(fallback).getTime()
    }
    if (isNaN(target)) return

    const windowStart = target - 15 * 60 * 1000
    const windowEnd = target + 15 * 60 * 1000

    const tick = () => {
      const now = Date.now()
      if (isOut) {
        if (now < windowStart) {
          setWindowState('before')
          setRemaining(Math.floor((windowStart - now) / 1000))
        } else if (now <= windowEnd) {
          setWindowState('during')
          setRemaining(Math.floor((windowEnd - now) / 1000))
        } else {
          setWindowState('after')
          setRemaining(0)
        }
      } else {
        if (now < windowStart) {
          setWindowState('before')
          setRemaining(Math.floor((windowStart - now) / 1000))
        } else {
          setWindowState('during')
          setRemaining(86400)
        }
      }
    }

    tick()
    const id = setInterval(tick, 1000)
    return () => clearInterval(id)
  }, [date, time, isOut, qrData])

  return (
    <div className={cn(
      "overflow-hidden rounded-xl border-2",
      color === "blue"
        ? "border-purple-200 bg-purple-50/50"
        : "border-emerald-200 bg-emerald-50/50"
    )}>
      <div className="p-5">
        <div className="mb-4 flex items-center justify-between">
          <span className={cn(
            "rounded-full px-3 py-1 text-xs font-bold tracking-wider uppercase",
            color === "blue"
              ? "bg-purple-100 text-purple-700"
              : "bg-emerald-100 text-emerald-700"
          )}>
            {label}
          </span>
          {isUsed && (
            <span className="flex items-center gap-1 text-xs text-gray-400">
              <CheckCircle className="h-3.5 w-3.5" /> Scanned
            </span>
          )}
        </div>

        {isUsed ? (
          <div className="flex flex-col items-center gap-3 py-8 text-gray-400">
            <CheckCircle className="h-14 w-14" />
            <span className="text-sm font-medium">Already Scanned</span>
          </div>
        ) : isOut && windowState === 'after' ? (
          <div className="flex flex-col items-center gap-3 py-8 text-gray-400">
            <TimerOff className="h-14 w-14" />
            <span className="text-sm font-medium">QR Code Expired</span>
            <span className="text-xs">The 15-minute validity window has passed</span>
          </div>
        ) : (
          <>
            <div className="flex justify-center">
              <div ref={canvasRef} />
            </div>
            <div className="mt-4 flex items-center justify-center gap-2">
              {isOut ? (
                <>
                  <Clock className={cn("h-4 w-4", windowState === 'before' ? "text-blue-500" : remaining > 300 ? "text-emerald-500" : "text-amber-500")} />
                  <span className={cn("font-mono text-lg font-bold", windowState === 'before' ? "text-blue-600" : remaining > 300 ? "text-emerald-600" : "text-amber-600")}>
                    {windowState === 'before' ? "Opens in " : "Expires in "}{formatTime(remaining)}
                  </span>
                </>
              ) : (
                <>
                  <Clock className="h-4 w-4 text-emerald-500" />
                  <span className="font-mono text-lg font-bold text-emerald-600">Ready to scan</span>
                </>
              )}
            </div>
          </>
        )}
      </div>

      {(employeeName || employeePosition) && (
        <div className={cn("flex items-center gap-3 border-t px-5 py-3", color === "blue" ? "border-purple-100" : "border-emerald-100")}>
          <div className={cn("flex h-9 w-9 items-center justify-center rounded-full text-sm font-bold text-white", color === "blue" ? "bg-purple-500" : "bg-emerald-500")}>
            {employeeName ? employeeName.charAt(0).toUpperCase() : <User className="h-4 w-4" />}
          </div>
          <div className="min-w-0 flex-1">
            {employeeName && <p className="truncate text-sm font-medium">{employeeName}</p>}
            {employeePosition && <p className="truncate text-xs text-muted-foreground">{employeePosition}</p>}
          </div>
        </div>
      )}
    </div>
  )
}
