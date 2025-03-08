// In a production environment, this would use a proper email service
// For now, we'll just log the emails to the console
export function sendEmail(notification) {
  console.log('Sending email:');
  console.log('To:', notification.to);
  console.log('Subject:', notification.subject);
  console.log('Body:', notification.body);
  console.log('---');
  
  // Simulate successful email sending
  return { Ok: null };
} 