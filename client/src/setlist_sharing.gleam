// Setlist Sharing Module
//
// This module handles all functionality related to sharing setlists:
// - Generate shareable links
// - Export setlists to different formats (PDF, text)
// - Integration with messaging platforms
// - QR code generation for quick sharing
// - Permissions management
// - Real-time collaboration features
//
// Author: TandemX Team
// License: MIT
// Version: 1.0.0

import gleam/dynamic/decode

import gleam/list
import gleam/option.{type Option, None, Some}

import lustre/attribute.{class}
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type ShareFormat {
  PDF
  PlainText
  JSON
  CSV
}

pub type SharePermission {
  ReadOnly
  ReadWrite
  Owner
}

pub type ShareTarget {
  Email(String)
  SMS(String)
  Link
  QRCode
}

pub type ShareMsg {
  GenerateShareLink(String)
  ExportSetlist(String, ShareFormat)
  ShareVia(String, ShareTarget)
  UpdatePermissions(String, SharePermission)
  InviteCollaborator(String)
  CopyToClipboard(String)
  ShareLinkGenerated(String, String)
  ExportCompleted(String)
  ShareError(String)
}

pub type ShareModel {
  ShareModel(
    shared_setlists: List(String),
    current_share_link: Option(String),
    exported_files: List(String),
    collaborators: List(String),
    permissions: List(#(String, SharePermission)),
  )
}

@external(javascript, "./setlist_sharing_ffi.js", "generateShareLink")
fn generate_share_link(setlist_id: String) -> String

@external(javascript, "./setlist_sharing_ffi.js", "exportSetlist")
fn export_setlist(setlist_id: String, format: String) -> String

@external(javascript, "./setlist_sharing_ffi.js", "shareViaEmail")
fn share_via_email(setlist_id: String, email: String) -> Bool

@external(javascript, "./setlist_sharing_ffi.js", "generateQRCode")
fn generate_qr_code(link: String) -> String

@external(javascript, "./setlist_sharing_ffi.js", "copyToClipboard")
fn copy_to_clipboard(text: String) -> Bool

pub fn init() -> #(ShareModel, effect.Effect(ShareMsg)) {
  #(
    ShareModel(
      shared_setlists: [],
      current_share_link: None,
      exported_files: [],
      collaborators: [],
      permissions: [],
    ),
    effect.none(),
  )
}

pub fn update(
  model: ShareModel,
  msg: ShareMsg,
) -> #(ShareModel, effect.Effect(ShareMsg)) {
  case msg {
    GenerateShareLink(setlist_id) -> {
      let link = generate_share_link(setlist_id)
      #(
        ShareModel(..model, current_share_link: Some(link)),
        effect.map(effect.none(), fn(_) { ShareLinkGenerated(setlist_id, link) }),
      )
    }

    ExportSetlist(setlist_id, format) -> {
      let format_str = case format {
        PDF -> "pdf"
        PlainText -> "txt"
        JSON -> "json"
        CSV -> "csv"
      }
      let file_path = export_setlist(setlist_id, format_str)
      let updated_files = list.append(model.exported_files, [file_path])
      #(
        ShareModel(..model, exported_files: updated_files),
        effect.map(effect.none(), fn(_) { ExportCompleted(file_path) }),
      )
    }

    ShareVia(setlist_id, target) -> {
      case target {
        Email(email) -> {
          let success = share_via_email(setlist_id, email)
          case success {
            True -> {
              let updated_shared =
                list.append(model.shared_setlists, [setlist_id])
              #(
                ShareModel(..model, shared_setlists: updated_shared),
                effect.none(),
              )
            }
            False -> #(
              model,
              effect.map(effect.none(), fn(_) {
                ShareError("Failed to share via email")
              }),
            )
          }
        }
        SMS(_phone) -> {
          // SMS sharing would be implemented here
          #(
            model,
            effect.map(effect.none(), fn(_) {
              ShareError("SMS sharing not implemented yet")
            }),
          )
        }
        Link -> {
          let link = generate_share_link(setlist_id)
          let _ = copy_to_clipboard(link)
          #(
            ShareModel(..model, current_share_link: Some(link)),
            effect.map(effect.none(), fn(_) {
              ShareLinkGenerated(setlist_id, link)
            }),
          )
        }
        QRCode -> {
          let link = generate_share_link(setlist_id)
          let _qr_code = generate_qr_code(link)
          #(
            ShareModel(..model, current_share_link: Some(link)),
            effect.map(effect.none(), fn(_) {
              ShareLinkGenerated(setlist_id, link)
            }),
          )
        }
      }
    }

    UpdatePermissions(setlist_id, permission) -> {
      let updated_permissions =
        list.filter(model.permissions, fn(p) {
          let #(id, _) = p
          id != setlist_id
        })
      let new_permissions =
        list.append(updated_permissions, [#(setlist_id, permission)])
      #(ShareModel(..model, permissions: new_permissions), effect.none())
    }

    InviteCollaborator(email) -> {
      let updated_collaborators = list.append(model.collaborators, [email])
      #(
        ShareModel(..model, collaborators: updated_collaborators),
        effect.none(),
      )
    }

    CopyToClipboard(text) -> {
      let _ = copy_to_clipboard(text)
      #(model, effect.none())
    }

    ShareLinkGenerated(_, _) -> #(model, effect.none())
    ExportCompleted(_) -> #(model, effect.none())
    ShareError(_) -> #(model, effect.none())
  }
}

// View functions would be defined here
pub fn view_share_panel(
  model: ShareModel,
  setlist_id: String,
) -> Element(ShareMsg) {
  html.div([class("share-panel")], [
    html.h2([], [html.text("Share Setlist")]),
    // Share link section
    html.div([class("share-section")], [
      html.h3([], [html.text("Share Link")]),
      html.div([class("share-actions")], [
        html.button(
          [event.on("click", decode.success(GenerateShareLink(setlist_id)))],
          [html.text("Generate Link")],
        ),
        case model.current_share_link {
          Some(link) ->
            html.div([class("share-link-container")], [
              html.input([
                attribute.type_("text"),
                attribute.value(link),
                attribute.readonly(True),
                class("share-link-input"),
              ]),
              html.button(
                [event.on("click", decode.success(CopyToClipboard(link)))],
                [html.text("Copy")],
              ),
            ])
          None -> html.div([], [])
        },
      ]),
    ]),
    // Export section
    html.div([class("share-section")], [
      html.h3([], [html.text("Export")]),
      html.div([class("export-formats")], [
        html.button(
          [event.on("click", decode.success(ExportSetlist(setlist_id, PDF)))],
          [html.text("PDF")],
        ),
        html.button(
          [
            event.on(
              "click",
              decode.success(ExportSetlist(setlist_id, PlainText)),
            ),
          ],
          [html.text("Text")],
        ),
        html.button(
          [event.on("click", decode.success(ExportSetlist(setlist_id, JSON)))],
          [html.text("JSON")],
        ),
        html.button(
          [event.on("click", decode.success(ExportSetlist(setlist_id, CSV)))],
          [html.text("CSV")],
        ),
      ]),
    ]),
    // Share via section
    html.div([class("share-section")], [
      html.h3([], [html.text("Share via")]),
      html.div([class("share-via-container")], [
        html.div([class("share-via-email")], [
          html.input([
            attribute.type_("email"),
            attribute.placeholder("Enter email address"),
            class("email-input"),
            event.on("input", decode.success(InviteCollaborator(""))),
          ]),
          html.button(
            [
              event.on(
                "click",
                decode.success(ShareVia(
                  setlist_id,
                  Email("collaborator@example.com"),
                )),
              ),
            ],
            [html.text("Share via Email")],
          ),
        ]),
        html.button(
          [event.on("click", decode.success(ShareVia(setlist_id, Link)))],
          [html.text("Copy Link")],
        ),
        html.button(
          [event.on("click", decode.success(ShareVia(setlist_id, QRCode)))],
          [html.text("QR Code")],
        ),
      ]),
    ]),
    // Permissions section
    html.div([class("share-section")], [
      html.h3([], [html.text("Permissions")]),
      html.div([class("permissions-container")], [
        html.select(
          [
            event.on(
              "change",
              decode.success(UpdatePermissions(setlist_id, ReadOnly)),
            ),
          ],
          [
            html.option([attribute.value("readonly")], "Read Only"),
            html.option([attribute.value("readwrite")], "Read/Write"),
            html.option([attribute.value("owner")], "Owner"),
          ],
        ),
      ]),
    ]),
  ])
}
