# Create the realm with comprehensive configuration
resource "keycloak_realm" "event_ticketing" {
  realm             = "event-ticketing"
  enabled           = true
  display_name      = "Event Ticketing Platform"
  
  # Registration and login settings
  registration_allowed           = true
  registration_email_as_username = true
  remember_me                   = true
  verify_email                  = true
  login_with_email_allowed      = true
  duplicate_emails_allowed      = false
  reset_password_allowed        = true
  edit_username_allowed         = false
  
#   # SMTP configuration
#   smtp_server {
#     host = "smtp.gmail.com"
#     port = "587"
#     from = "noreply@eventtickets.local"
#     from_display_name = "Event Ticketing Platform"
#     ssl = false
#     starttls = true
#     auth {
#       username = ""
#       password = ""
#     }
#   }
  
  # Security defenses including brute force protection
  security_defenses {
    headers {
      x_frame_options                     = "DENY"
      content_security_policy             = "frame-src 'self'; frame-ancestors 'self'; object-src 'none';"
      content_security_policy_report_only = ""
      x_content_type_options              = "nosniff"
      x_robots_tag                        = "none"
      x_xss_protection                    = "1; mode=block"
      strict_transport_security           = "max-age=31536000; includeSubDomains"
    }
    brute_force_detection {
      permanent_lockout                 = false
      max_login_failures                = 30
      wait_increment_seconds            = 60
      quick_login_check_milli_seconds   = 1000
      minimum_quick_login_wait_seconds  = 60
      max_failure_wait_seconds          = 900
      failure_reset_time_seconds        = 43200
    }
  }
}