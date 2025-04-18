export function getWindowSelection() {
  const selection = window.getSelection();
  if (!selection || !selection.toString()) {
    return { Ok: false };
  }

  const range = selection.getRangeAt(0);
  const text = selection.toString();
  const start = range.startOffset;
  const end = range.endOffset;

  return {
    Ok: {
      text,
      start,
      end
    }
  };
}

export function getSurroundingContext(text, selection) {
  const contextSize = 100; // Number of characters before and after selection
  const start = Math.max(0, selection.start - contextSize);
  const end = Math.min(text.length, selection.end + contextSize);
  
  let context = '';
  if (start > 0) {
    context += '...' + text.substring(start, selection.start);
  } else {
    context += text.substring(0, selection.start);
  }
  
  if (end < text.length) {
    context += text.substring(selection.end, end) + '...';
  } else {
    context += text.substring(selection.end);
  }
  
  return context;
} 