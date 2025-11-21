/////////////////////////////////////////////////////////////
// USERS & AUTHENTICATION
/////////////////////////////////////////////////////////////

Table User {
  id                    bigint [pk, increment]
  username              varchar(60) [unique]
  full_name             varchar(120)
  email                 varchar(150) [unique]
  phone_number          varchar(30) [null]
  password_hash         varchar(255)
  bio                   text [null]
  profile_photo_url     varchar(255) [null]
  is_active             boolean [default: true]
  email_verified        boolean [default: false]
  phone_verified        boolean [default: false]
  location_sharing_enabled boolean [default: false]
  location_update_interval int [default: 15] // minutes: 5, 15, 30, or 0 for manual
  availability_status   varchar(20) [default: 'available'] // available, busy, at_work, at_school, unavailable
  total_points          int [default: 0]
  created_at            datetime
  updated_at            datetime
  last_login_at         datetime [null]

  Indexes {
    (email)
    (username)
  }
}

/////////////////////////////////////////////////////////////
// ROLES (to distinguish user types: regular, organizer, venue_owner, admin)
/////////////////////////////////////////////////////////////

Table Role {
  id                    smallint [pk, increment]
  name                  varchar(50) [unique] // user, organizer, venue_owner, admin
  description           text [null]
  created_at            datetime
  updated_at            datetime
}

Table UserRole { // M:N User–Role (users can have multiple roles)
  user_id               bigint
  role_id               smallint
  assigned_at           datetime
  status                varchar(20) [default: 'active'] // active, revoked

  Indexes {
    (user_id, role_id) [pk]
    (role_id)
  }
}

Ref: UserRole.user_id > User.id [delete: cascade]
Ref: UserRole.role_id > Role.id [delete: cascade]

/////////////////////////////////////////////////////////////
// USER LOCATION TRACKING
/////////////////////////////////////////////////////////////

Table UserLocation { // Current location (not history)
  id                    bigint [pk, increment]
  user_id               bigint [unique]
  latitude              decimal(9,6)
  longitude             decimal(9,6)
  accuracy_m            float [null]
  updated_at            datetime

  Indexes {
    (user_id)
  }
}

Ref: UserLocation.user_id > User.id [delete: cascade]

Table UserLocationHistory { // Historical location data for travel visualization
  id                    bigint [pk, increment]
  user_id               bigint
  recorded_at           datetime
  latitude              decimal(9,6)
  longitude             decimal(9,6)
  altitude_m            decimal(8,2) [null]
  accuracy_m            float [null]
  speed_mps             float [null]
  heading_deg           float [null]
  source                varchar(20) [default: 'gps'] // gps, wifi, network, manual
  created_at            datetime

  Indexes {
    (user_id, recorded_at)
    (recorded_at)
  }
}

Ref: UserLocationHistory.user_id > User.id [delete: cascade]

/////////////////////////////////////////////////////////////
// FRIENDSHIPS
/////////////////////////////////////////////////////////////

Table Friendship {
  id                    bigint [pk, increment]
  user_id               bigint
  friend_id             bigint
  is_close_friend       boolean [default: false]
  created_at            datetime

  Indexes {
    (user_id, friend_id) [unique]
    (friend_id, user_id)
  }
}

Ref: Friendship.user_id > User.id [delete: cascade]
Ref: Friendship.friend_id > User.id [delete: cascade]

/////////////////////////////////////////////////////////////
// MEETINGS (user-initiated meetups, different from Events)
/////////////////////////////////////////////////////////////

Table Meeting {
  id                    bigint [pk, increment]
  organizer_id          bigint
  title                 varchar(200) [null]
  description           text [null]
  location_id           bigint [null] // Can be a Location or just coordinates
  latitude              decimal(9,6) [null]
  longitude             decimal(9,6) [null]
  address               varchar(255) [null]
  scheduled_at          datetime
  created_at            datetime
  updated_at            datetime
  status                varchar(20) [default: 'pending'] // pending, confirmed, cancelled, completed

  Indexes {
    (organizer_id)
    (scheduled_at)
    (status)
  }
}

Ref: Meeting.organizer_id > User.id [delete: cascade]
Ref: Meeting.location_id > Location.id [delete: set null]

Table MeetingParticipant {
  id                    bigint [pk, increment]
  meeting_id            bigint
  user_id               bigint
  status                varchar(20) [default: 'pending'] // pending, accepted, declined
  confirmed_at          datetime [null] // When user confirmed attendance in real life
  created_at            datetime
  updated_at            datetime

  Indexes {
    (meeting_id, user_id) [unique]
    (user_id)
  }
}

Ref: MeetingParticipant.meeting_id > Meeting.id [delete: cascade]
Ref: MeetingParticipant.user_id > User.id [delete: cascade]

/////////////////////////////////////////////////////////////
// GROUPS
/////////////////////////////////////////////////////////////

Table Group {
  id                    bigint [pk, increment]
  name                  varchar(100)
  description           text [null]
  created_by_user_id    bigint
  created_at            datetime
  updated_at            datetime

  Indexes {
    (created_by_user_id)
  }
}

Ref: Group.created_by_user_id > User.id [delete: cascade]

Table GroupMember {
  id                    bigint [pk, increment]
  group_id              bigint
  user_id               bigint
  role                  varchar(20) [default: 'member'] // admin, member
  joined_at             datetime

  Indexes {
    (group_id, user_id) [unique]
    (user_id)
  }
}

Ref: GroupMember.group_id > Group.id [delete: cascade]
Ref: GroupMember.user_id > User.id [delete: cascade]

/////////////////////////////////////////////////////////////
// POINTS & GAMIFICATION
/////////////////////////////////////////////////////////////

Table PointsTransaction {
  id                    bigint [pk, increment]
  user_id               bigint
  points                int // Can be positive (earned) or negative (spent)
  transaction_type      varchar(30) // meeting_confirmed, mission_completed, event_participation, store_purchase
  reference_id          bigint [null] // ID of related entity (meeting_id, mission_id, etc.)
  description           varchar(255) [null]
  created_at            datetime

  Indexes {
    (user_id, created_at)
    (transaction_type)
  }
}

Ref: PointsTransaction.user_id > User.id [delete: cascade]

Table Mission {
  id                    bigint [pk, increment]
  title                 varchar(200)
  description           text
  mission_type          varchar(30) // meet_friends, visit_location, complete_meetings
  points_reward         int
  criteria_json         text [null] // JSON with mission criteria
  is_active             boolean [default: true]
  created_at            datetime
  updated_at            datetime

  Indexes {
    (is_active)
  }
}

Table UserMission {
  id                    bigint [pk, increment]
  user_id               bigint
  mission_id            bigint
  status                varchar(20) [default: 'in_progress'] // in_progress, completed, failed
  progress_json         text [null] // JSON with current progress
  completed_at          datetime [null]
  created_at            datetime
  updated_at            datetime

  Indexes {
    (user_id, mission_id) [unique]
    (status)
  }
}

Ref: UserMission.user_id > User.id [delete: cascade]
Ref: UserMission.mission_id > Mission.id [delete: cascade]

Table StoreItem {
  id                    bigint [pk, increment]
  name                  varchar(200)
  description           text [null]
  points_cost           int
  item_type             varchar(30) // feature_unlock, badge, discount
  metadata_json         text [null] // JSON with item-specific data
  is_active             boolean [default: true]
  created_at            datetime
  updated_at            datetime

  Indexes {
    (is_active)
  }
}

Table UserPurchase {
  id                    bigint [pk, increment]
  user_id               bigint
  store_item_id         bigint
  purchased_at          datetime

  Indexes {
    (user_id)
    (store_item_id)
  }
}

Ref: UserPurchase.user_id > User.id [delete: cascade]
Ref: UserPurchase.store_item_id > StoreItem.id [delete: cascade]

/////////////////////////////////////////////////////////////
// EVENTS (public/private events organized by organizers)
/////////////////////////////////////////////////////////////

Table Event {
  id                    bigint [pk, increment]
  title                 varchar(150)
  description           text
  organizer_user_id     bigint
  location_id           bigint [null]
  latitude              decimal(9,6) [null]
  longitude             decimal(9,6) [null]
  address               varchar(255) [null]
  visibility            varchar(20) [default: 'public'] // public, private
  status                varchar(20) [default: 'draft'] // draft, active, ended, cancelled
  start_at              datetime
  end_at                datetime [null]
  capacity              int [null]
  bonus_points          int [default: 0]
  eligibility_criteria_json text [null] // JSON with eligibility rules
  created_at            datetime
  updated_at            datetime

  Indexes {
    (organizer_user_id)
    (start_at)
    (status)
    (visibility)
  }
}

Ref: Event.organizer_user_id > User.id [delete: cascade]
Ref: Event.location_id > Location.id [delete: set null]

Table EventParticipant {
  id                    bigint [pk, increment]
  event_id              bigint
  user_id               bigint
  status                varchar(20) [default: 'invited'] // invited, accepted, declined, attended
  invited_at            datetime
  responded_at          datetime [null]
  attended_at           datetime [null]

  Indexes {
    (event_id, user_id) [unique]
    (user_id)
    (status)
  }
}

Ref: EventParticipant.event_id > Event.id [delete: cascade]
Ref: EventParticipant.user_id > User.id [delete: cascade]

/////////////////////////////////////////////////////////////
// LOCATIONS (venues)
/////////////////////////////////////////////////////////////

Table Location {
  id                    bigint [pk, increment]
  name                  varchar(150)
  description           text [null]
  owner_user_id         bigint [null] // If registered by a venue owner
  address_line1         varchar(200)
  address_line2         varchar(200) [null]
  city                  varchar(100)
  postal_code           varchar(20) [null]
  country               varchar(100)
  latitude              decimal(9,6)
  longitude             decimal(9,6)
  place_type            varchar(40) [null] // cafe, restaurant, park, etc.
  phone_number          varchar(30) [null]
  website_url           varchar(255) [null]
  opening_hours_json    text [null] // JSON with opening hours
  is_poi                boolean [default: false] // Point of Interest for missions/events
  average_rating        decimal(3,2) [default: 0.00]
  total_reviews         int [default: 0]
  created_at            datetime
  updated_at            datetime

  Indexes {
    (city)
    (is_poi)
    (owner_user_id)
  }
}

Ref: Location.owner_user_id > User.id [delete: set null]

Table LocationReview {
  id                    bigint [pk, increment]
  location_id           bigint
  user_id               bigint
  rating                int // 1-5
  comment               text [null]
  created_at            datetime
  updated_at            datetime

  Indexes {
    (location_id)
    (user_id)
  }
}

Ref: LocationReview.location_id > Location.id [delete: cascade]
Ref: LocationReview.user_id > User.id [delete: cascade]

Table LocationCampaign {
  id                    bigint [pk, increment]
  location_id           bigint
  title                 varchar(200)
  description           text [null]
  offer_details         text [null]
  start_at              datetime
  end_at                datetime [null]
  is_active             boolean [default: true]
  created_at            datetime
  updated_at            datetime

  Indexes {
    (location_id)
    (is_active)
  }
}

Ref: LocationCampaign.location_id > Location.id [delete: cascade]

/////////////////////////////////////////////////////////////
// AVAILABILITY SCHEDULE
/////////////////////////////////////////////////////////////

Table AvailabilitySchedule {
  id                    bigint [pk, increment]
  user_id               bigint
  day_of_week           int // 0=Monday, 6=Sunday
  start_time            time
  end_time              time
  is_active             boolean [default: true]
  created_at            datetime
  updated_at            datetime

  Indexes {
    (user_id, day_of_week)
  }
}

Ref: AvailabilitySchedule.user_id > User.id [delete: cascade]

