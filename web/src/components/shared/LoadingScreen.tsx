import { Loader2 } from "lucide-react"
import { Card, CardContent } from "@/components/ui/card"

interface LoadingScreenProps {
  message?: string
  fullPage?: boolean
}

export default function LoadingScreen({ message, fullPage = true }: LoadingScreenProps) {
  const inner = (
    <div className="flex flex-col items-center gap-3">
      <Loader2 className="h-6 w-6 animate-spin text-primary" />
      {message && <p className="text-sm text-muted-foreground">{message}</p>}
    </div>
  )

  if (fullPage) {
    return (
      <div className="flex h-64 items-center justify-center">
        {inner}
      </div>
    )
  }

  return (
    <Card className="px-6 py-4 flex flex-col items-center gap-3">
      <Loader2 className="h-5 w-5 animate-spin text-primary" />
      {message && <p className="text-sm text-muted-foreground">{message}</p>}
    </Card>
  )
}
