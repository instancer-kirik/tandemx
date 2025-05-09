// JavaScript version of email_service for SendGrid integration
// -------------------------------------------------------------------
// HOW TO USE THIS FILE:
// 1. Set SENDGRID_API_KEY environment variable
// 2. Change the target in gleam.toml to 'javascript'
// 3. Rename this file to email_service.gleam (replacing the Erlang version)
// 4. Run the server
// -------------------------------------------------------------------

import gleam/io

/// Email notification type
/// Used to represent an email to be sent
pub type EmailNotification {
  EmailNotification(to: String, subject: String, body: String, from: String)
}

/// Initialize the email service
/// This is a mock implementation for the Erlang target
pub fn init() -> Nil {
  io.println("Initializing email service (Erlang implementation)")
  io.println(
    "Email service is running in mock mode (no actual emails will be sent)",
  )

  Nil
}

/// Send an email notification (mock implementation)
pub fn send_email(notification: EmailNotification) -> Nil {
  // Log the email
  io.println("\nSending email (MOCK - not actually sent):")
  io.println("From: " <> notification.from)
  io.println("To: " <> notification.to)
  io.println("Subject: " <> notification.subject)
  io.println("Body:\n" <> notification.body)
  io.println("---")

  // Use Erlang's io:format for more advanced formatting
  erlang_format("Email ~s -> ~s: ~s", [
    notification.from,
    notification.to,
    notification.subject,
  ])

  Nil
}

/// Send a meeting invitation email (mock implementation)
pub fn send_meeting_invitation(notification: EmailNotification) -> Nil {
  // Log the email
  io.println("\nSending meeting invitation (MOCK - not actually sent):")
  io.println("From: " <> notification.from)
  io.println("To: " <> notification.to)
  io.println("Subject: " <> notification.subject)
  io.println("Body:\n" <> notification.body)
  io.println("---")

  // Use Erlang's io:format for more advanced formatting
  erlang_format("Meeting Invitation ~s -> ~s: ~s", [
    notification.from,
    notification.to,
    notification.subject,
  ])

  Nil
}

/// Wrapper for Erlang's io:format function
@external(erlang, "io", "format")
fn erlang_format(format: String, args: List(String)) -> Nil
