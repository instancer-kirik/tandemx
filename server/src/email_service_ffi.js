// Email service using SendGrid
import sgMail from '@sendgrid/mail';

// Get an environment variable
export function getEnvVar(name) {
  return process.env[name] || '';
}

// Initialize SendGrid with API key
export function initSendGrid(apiKey) {
  // Don't initialize if the API key is empty
  if (!apiKey) {
    console.log('Warning: Empty SendGrid API key provided');
    return { Ok: null };
  }
  
  sgMail.setApiKey(apiKey);
  console.log('SendGrid initialized with API key');
  return { Ok: null };
}

// Send an email using SendGrid
export function sendEmail(notification) {
  const msg = {
    to: notification.to,
    from: notification.from || 'instance.select@gmail.com', // Default sender
    subject: notification.subject,
    text: notification.body,
    // Can add HTML version later if needed
  };

  return sgMail.send(msg)
    .then(() => {
      console.log('Email sent successfully to:', notification.to);
      return { Ok: null };
    })
    .catch((error) => {
      console.error('Error sending email:', error);
      // Return an error result that Gleam can handle
      return { Error: error.toString() };
    });
}

// Send a meeting invitation email with HTML formatting
export function sendMeetingInvitation(notification) {
  const msg = {
    to: notification.to,
    from: notification.from || 'instance.select@gmail.com',
    subject: notification.subject,
    text: notification.body,
    html: formatEmailHtml(notification.body),
  };

  return sgMail.send(msg)
    .then(() => {
      console.log('Meeting invitation sent successfully to:', notification.to);
      return { Ok: null };
    })
    .catch((error) => {
      console.error('Error sending meeting invitation:', error);
      return { Error: error.toString() };
    });
}

// Format plain text email as HTML
function formatEmailHtml(plainText) {
  // Simple conversion of plain text to HTML
  return plainText
    .replace(/\n\n/g, '</p><p>')
    .replace(/\n/g, '<br>')
    .replace(/^/, '<p>')
    .replace(/$/, '</p>');
} 