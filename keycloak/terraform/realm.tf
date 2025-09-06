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
  
  # SMTP configuration
  smtp_server {
    host = var.smtp_host
    port = var.smtp_port
    from = var.smtp_from_email
    from_display_name = var.smtp_from_display_name
    ssl = var.smtp_port == "465" ? true : false
    starttls = var.smtp_port == "587" ? true : false
    auth {
      username = var.smtp_from_email
      password = var.smtp_from_password
    }
  }
  
  # Security defenses including brute force protection
  security_defenses {
    headers {
      x_frame_options                     = "DENY"
      content_security_policy             = "frame-src 'self'; frame-ancestors 'self' http://localhost:8090 https://localhost:8090 http://www.localhost:8090 https://www.localhost:8090 http://ticketly.test:8090 https://ticketly.test:8090 https://ticketly.dpiyumal.me; object-src 'none';"
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


resource "keycloak_oidc_identity_provider" "google" {
  # Link to the realm created in your other file
  realm                = keycloak_realm.event_ticketing.id
  alias                = "google"
  display_name         = "Google"
  enabled              = true
  client_id            = var.google_oauth_client_id
  client_secret        = var.google_oauth_client_secret
  authorization_url    = "https://accounts.google.com/o/oauth2/auth"
  token_url            = "https://oauth2.googleapis.com/token"
  user_info_url        = "https://www.googleapis.com/oauth2/v3/userinfo"
  default_scopes       = "openid profile email"
  sync_mode            = "IMPORT"
  jwks_url             = "https://www.googleapis.com/oauth2/v3/certs"
  gui_order            = "1"
  hide_on_login_page   = false
  first_broker_login_flow_alias = "first broker login"
}