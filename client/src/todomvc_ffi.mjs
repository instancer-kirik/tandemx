export function focus(selector) {
  requestAnimationFrame(() => {
    const el = document.querySelector(selector)
    if (el) el.focus()
  })
  return null
}

export function after_render(callback) {
  requestAnimationFrame(() => {
    callback()
  })
  return null
}
