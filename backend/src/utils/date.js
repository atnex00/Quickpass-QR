function getLocalDateString(date = new Date()) {
  const d = date instanceof Date ? date : new Date(date)
  const offset = d.getTimezoneOffset()
  const adjusted = new Date(d.getTime() - offset * 60 * 1000)
  return adjusted.toISOString().split('T')[0]
}

module.exports = { getLocalDateString }
