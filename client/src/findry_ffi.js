export function getWebSocketUrl() {
  return `ws://${window.location.host}/ws/findry`;
}

export function dispatch(msg) {
  // This will be replaced by Lustre's runtime
  console.log('Message dispatched:', msg);
}

export function getWindowWidth() {
  return window.innerWidth;
}

// Event handlers
export function onMouseDown(handler) {
  return {
    type: "event",
    name: "mousedown",
    handler: (event) => handler({
      $constructor: "MouseEvent",
      client_x: event.clientX,
      client_y: event.clientY
    })
  };
}

export function onTouchStart(handler) {
  return {
    type: "event",
    name: "touchstart",
    handler: (event) => handler({
      $constructor: "TouchEvent",
      touches: Array.from(event.touches).map(touch => ({
        $constructor: "Touch",
        client_x: touch.clientX,
        client_y: touch.clientY
      }))
    })
  };
}

export function onMouseMove(handler) {
  return {
    type: "event",
    name: "mousemove",
    handler: (event) => handler({
      $constructor: "MouseEvent",
      client_x: event.clientX,
      client_y: event.clientY
    })
  };
}

export function onTouchMove(handler) {
  return {
    type: "event",
    name: "touchmove",
    handler: (event) => handler({
      $constructor: "TouchEvent",
      touches: Array.from(event.touches).map(touch => ({
        $constructor: "Touch",
        client_x: touch.clientX,
        client_y: touch.clientY
      }))
    })
  };
}

export function onMouseUp(handler) {
  return {
    type: "event",
    name: "mouseup",
    handler: (event) => handler({
      $constructor: "MouseEvent",
      client_x: event.clientX,
      client_y: event.clientY
    })
  };
}

export function onTouchEnd(handler) {
  return {
    type: "event",
    name: "touchend",
    handler: (event) => handler({
      $constructor: "TouchEvent",
      touches: Array.from(event.touches).map(touch => ({
        $constructor: "Touch",
        client_x: touch.clientX,
        client_y: touch.clientY
      }))
    })
  };
}

export function onChange(handler) {
  return {
    type: "event",
    name: "change",
    handler: (event) => handler({
      $constructor: "FormEvent",
      target: {
        $constructor: "FormTarget",
        value: event.target.value,
        checked: event.target.checked
      }
    })
  };
}

export function onInput(handler) {
  return {
    type: "event",
    name: "input",
    handler: (event) => handler({
      $constructor: "FormEvent",
      target: {
        $constructor: "FormTarget",
        value: event.target.value,
        checked: event.target.checked
      }
    })
  };
}

// Log when the module is loaded
console.log('Findry FFI module loaded'); 