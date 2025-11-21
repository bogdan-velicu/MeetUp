/////////////////////////////////////////////////////////////
// USERS & ROLES
/////////////////////////////////////////////////////////////

Table User {
  id                    bigint [pk, increment]
  username              varchar(60) [unique]
  full_name             varchar(120)
  email                 varchar(150) [unique]
  phone_number          varchar(30)
  password_hash         varchar(255)
  bio                   text
  gender                varchar(20)
  birth_date            date
  profile_photo_url     varchar(255)
  is_active             boolean
  email_verified        boolean
  phone_verified        boolean
  language_code         varchar(10)   // e.g., en, ro
  country_code          varchar(2)    // ISO-2
  created_at            datetime
  updated_at            datetime
  last_login_at         datetime
  marketing_consent     boolean
  preferences_json      text
}

Table Role {
  id                    smallint [pk, increment]
  name                  varchar(50) [unique] // admin, organizer, user
  description           text
  scope                 varchar(50)  // global, tenant, event
  permissions_json      text
  created_at            datetime
  updated_at            datetime
}

Table UserRole { // M:N User–Role
  user_id               bigint
  role_id               smallint
  assigned_at           datetime
  assigned_by_user_id   bigint
  status                varchar(20)  // active, revoked, pending

  Indexes {
    (user_id, role_id) [pk]
    (role_id)
    (assigned_by_user_id)
  }
}

Ref: UserRole.user_id > User.id
Ref: UserRole.role_id > Role.id
// no FK for assigned_by_user_id (informational only)


/////////////////////////////////////////////////////////////
// USER LOCATION HISTORY (one-to-many from User)
/////////////////////////////////////////////////////////////

Table UserLocationHistory {
  id                    bigint [pk, increment]
  user_id               bigint
  recorded_at           datetime
  latitude              decimal(9,6)
  longitude             decimal(9,6)
  altitude_m            decimal(8,2)
  accuracy_m            float
  speed_mps             float
  heading_deg           float
  source                varchar(20)  // gps / wifi / manual
  device_id             varchar(80)
  app_version           varchar(30)
  created_at            datetime

  Indexes {
    (user_id, recorded_at)
    (recorded_at)
  }
}

Ref: UserLocationHistory.user_id > User.id


/////////////////////////////////////////////////////////////
// LOCATIONS (venues) — no relation object, coords inline
/////////////////////////////////////////////////////////////

Table Location {
  id                    bigint [pk, increment]
  name                  varchar(150)
  description           text
  address_line1         varchar(200)
  address_line2         varchar(200)
  city                  varchar(100)
  state_region          varchar(100)
  postal_code           varchar(20)
  country               varchar(100)
  country_code          varchar(2)
  timezone              varchar(50)
  place_type            varchar(40)  // club, bar, park, arena
  phone_number          varchar(30)
  website_url           varchar(255)
  email_contact         varchar(150)
  capacity              int
  latitude              decimal(9,6)
  longitude             decimal(9,6)
  created_at            datetime
  updated_at            datetime

  Indexes {
    (city)
    (country_code)
  }
}


/////////////////////////////////////////////////////////////
// EVENTS — no direct FK to Location, no enforced FK to User
/////////////////////////////////////////////////////////////

Table Event {
  id                    bigint [pk, increment]
  title                 varchar(150)
  slug                  varchar(160) [unique]
  description           text
  category              varchar(60)  // party, concert, meetup
  tags                  text         // comma-separated
  type                  varchar(20)  // local / national
  visibility            varchar(20)  // public / private
  status                varchar(20)  // draft / active / ended / cancelled
  start_at              datetime
  end_at                datetime
  door_open_at          datetime
  age_limit             int
  price_amount          decimal(10,2)
  price_currency        varchar(3)   // ISO-4217
  capacity              int
  requires_approval     boolean
  cover_image_url       varchar(255)
  organizer_contact     varchar(150)
  creator_user_id       bigint [null] // informational only, NOT FK
  created_at            datetime
  updated_at            datetime

  Indexes {
    (start_at)
    (status)
    (creator_user_id)
  }
}
// no Ref for Event.creator_user_id by request


/////////////////////////////////////////////////////////////
// TERNARY ENTITY: Event–User–Location
/////////////////////////////////////////////////////////////

Table EventUserLocation {
  event_id              bigint
  user_id               bigint
  location_id           bigint
  role_in_event         varchar(30)  // host, staff, attendee, moderator
  rsvp_status           varchar(20)  // going, interested, declined, none
  ticket_type           varchar(30)  // free, vip, standard
  ticket_price          decimal(10,2)
  checkin_code          varchar(40)
  checked_in_at         datetime
  checked_out_at        datetime
  rating_score          int          // 1-5 optional feedback
  notes                 text
  created_at            datetime
  updated_at            datetime

  Indexes {
    (event_id, user_id, location_id) [pk]
    (user_id, event_id)
    (event_id, location_id)
    (rsvp_status)
  }
}

Ref: EventUserLocation.event_id    > Event.id
Ref: EventUserLocation.user_id     > User.id
Ref: EventUserLocation.location_id > Location.id
