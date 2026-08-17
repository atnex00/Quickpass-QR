import { describe, expect, it } from "vitest"
import { QR_SCAN_STYLE } from "../QrDisplay"

describe("QR_SCAN_STYLE", () => {
  it("keeps finder patterns black for screen scanning", () => {
    expect(QR_SCAN_STYLE.cornersSquareOptions.color).toBe("#000000")
    expect(QR_SCAN_STYLE.cornersDotOptions.color).toBe("#000000")
  })

  it("keeps data modules and background scanner-safe", () => {
    expect(QR_SCAN_STYLE.dotsOptions.color).toBe("#000000")
    expect(QR_SCAN_STYLE.backgroundOptions.color).toBe("#ffffff")
  })
})