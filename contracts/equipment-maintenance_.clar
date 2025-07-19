;; Equipment Maintenance Contract
;; Ensures fire suppression systems functionality

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-INVALID-INPUT (err u301))
(define-constant ERR-NOT-FOUND (err u302))
(define-constant ERR-ALREADY-EXISTS (err u303))
(define-constant ERR-INVALID-STATUS (err u304))

;; Equipment types: 1=Sprinkler, 2=Fire Alarm, 3=Extinguisher, 4=Hydrant, 5=Emergency Lighting
(define-constant EQUIPMENT-SPRINKLER u1)
(define-constant EQUIPMENT-FIRE-ALARM u2)
(define-constant EQUIPMENT-EXTINGUISHER u3)
(define-constant EQUIPMENT-HYDRANT u4)
(define-constant EQUIPMENT-EMERGENCY-LIGHTING u5)

;; Status types: 1=Operational, 2=Needs Maintenance, 3=Under Maintenance, 4=Out of Service, 5=Replaced
(define-constant STATUS-OPERATIONAL u1)
(define-constant STATUS-NEEDS-MAINTENANCE u2)
(define-constant STATUS-UNDER-MAINTENANCE u3)
(define-constant STATUS-OUT-OF-SERVICE u4)
(define-constant STATUS-REPLACED u5)

;; Data Variables
(define-data-var next-equipment-id uint u1)
(define-data-var next-maintenance-id uint u1)

;; Data Maps
(define-map equipment
  { equipment-id: uint }
  {
    building-id: (string-ascii 50),
    equipment-type: uint,
    location: (string-ascii 100),
    manufacturer: (string-ascii 50),
    model: (string-ascii 50),
    serial-number: (string-ascii 50),
    installation-date: uint,
    last-maintenance: (optional uint),
    next-maintenance-due: uint,
    status: uint,
    warranty-expiry: (optional uint),
    created-by: principal,
    created-date: uint
  }
)

(define-map maintenance-records
  { maintenance-id: uint }
  {
    equipment-id: uint,
    technician: principal,
    maintenance-type: uint,
    scheduled-date: uint,
    actual-date: (optional uint),
    status: uint,
    findings: (string-ascii 1000),
    parts-replaced: (string-ascii 500),
    cost: (optional uint),
    next-maintenance-due: (optional uint),
    created-by: principal,
    created-date: uint
  }
)

(define-map authorized-technicians
  { technician: principal }
  {
    authorized: bool,
    specializations: (list 10 uint),
    certification-expiry: uint
  }
)

(define-map building-equipment-summary
  { building-id: (string-ascii 50) }
  {
    total-equipment: uint,
    operational-count: uint,
    maintenance-needed: uint,
    out-of-service: uint,
    last-updated: uint
  }
)

;; Authorization Functions
(define-public (authorize-technician
  (technician principal)
  (specializations (list 10 uint))
  (certification-expiry uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> certification-expiry (unwrap-panic (get-block-info? time (- block-height u1)))) ERR-INVALID-INPUT)
    (ok (map-set authorized-technicians
      { technician: technician }
      {
        authorized: true,
        specializations: specializations,
        certification-expiry: certification-expiry
      }))
  )
)

(define-public (revoke-technician (technician principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-technicians
      { technician: technician }
      {
        authorized: false,
        specializations: (list),
        certification-expiry: u0
      }))
  )
)

;; Equipment Management Functions
(define-public (register-equipment
  (building-id (string-ascii 50))
  (equipment-type uint)
  (location (string-ascii 100))
  (manufacturer (string-ascii 50))
  (model (string-ascii 50))
  (serial-number (string-ascii 50))
  (installation-date uint)
  (warranty-expiry (optional uint)))
  (let
    (
      (equipment-id (var-get next-equipment-id))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (next-maintenance (+ installation-date (get-maintenance-interval equipment-type)))
    )
    (begin
      (asserts! (> (len building-id) u0) ERR-INVALID-INPUT)
      (asserts! (and (>= equipment-type u1) (<= equipment-type u5)) ERR-INVALID-INPUT)
      (asserts! (> (len location) u0) ERR-INVALID-INPUT)
      (asserts! (> (len serial-number) u0) ERR-INVALID-INPUT)
      (asserts! (<= installation-date current-time) ERR-INVALID-INPUT)

      (map-set equipment
        { equipment-id: equipment-id }
        {
          building-id: building-id,
          equipment-type: equipment-type,
          location: location,
          manufacturer: manufacturer,
          model: model,
          serial-number: serial-number,
          installation-date: installation-date,
          last-maintenance: none,
          next-maintenance-due: next-maintenance,
          status: STATUS-OPERATIONAL,
          warranty-expiry: warranty-expiry,
          created-by: tx-sender,
          created-date: current-time
        }
      )

      (update-building-summary building-id)
      (var-set next-equipment-id (+ equipment-id u1))
      (ok equipment-id)
    )
  )
)

(define-public (schedule-maintenance
  (equipment-id uint)
  (technician principal)
  (maintenance-type uint)
  (scheduled-date uint))
  (let
    (
      (maintenance-id (var-get next-maintenance-id))
      (equipment-info (unwrap! (map-get? equipment { equipment-id: equipment-id }) ERR-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (technician-info (unwrap! (map-get? authorized-technicians { technician: technician }) ERR-NOT-AUTHORIZED))
    )
    (begin
      (asserts! (get authorized technician-info) ERR-NOT-AUTHORIZED)
      (asserts! (and (>= maintenance-type u1) (<= maintenance-type u4)) ERR-INVALID-INPUT)
      (asserts! (> scheduled-date current-time) ERR-INVALID-INPUT)
      (asserts! (> (get certification-expiry technician-info) current-time) ERR-NOT-AUTHORIZED)

      (map-set maintenance-records
        { maintenance-id: maintenance-id }
        {
          equipment-id: equipment-id,
          technician: technician,
          maintenance-type: maintenance-type,
          scheduled-date: scheduled-date,
          actual-date: none,
          status: STATUS-NEEDS-MAINTENANCE,
          findings: "",
          parts-replaced: "",
          cost: none,
          next-maintenance-due: none,
          created-by: tx-sender,
          created-date: current-time
        }
      )

      (map-set equipment
        { equipment-id: equipment-id }
        (merge equipment-info { status: STATUS-NEEDS-MAINTENANCE })
      )

      (var-set next-maintenance-id (+ maintenance-id u1))
      (ok maintenance-id)
    )
  )
)

(define-public (complete-maintenance
  (maintenance-id uint)
  (findings (string-ascii 1000))
  (parts-replaced (string-ascii 500))
  (cost uint))
  (let
    (
      (maintenance-record (unwrap! (map-get? maintenance-records { maintenance-id: maintenance-id }) ERR-NOT-FOUND))
      (equipment-info (unwrap! (map-get? equipment { equipment-id: (get equipment-id maintenance-record) }) ERR-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (next-maintenance (+ current-time (get-maintenance-interval (get equipment-type equipment-info))))
    )
    (begin
      (asserts! (is-eq tx-sender (get technician maintenance-record)) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get status maintenance-record) STATUS-NEEDS-MAINTENANCE) ERR-INVALID-STATUS)

      (map-set maintenance-records
        { maintenance-id: maintenance-id }
        (merge maintenance-record {
          actual-date: (some current-time),
          status: STATUS-OPERATIONAL,
          findings: findings,
          parts-replaced: parts-replaced,
          cost: (some cost),
          next-maintenance-due: (some next-maintenance)
        })
      )

      (map-set equipment
        { equipment-id: (get equipment-id maintenance-record) }
        (merge equipment-info {
          last-maintenance: (some current-time),
          next-maintenance-due: next-maintenance,
          status: STATUS-OPERATIONAL
        })
      )

      (update-building-summary (get building-id equipment-info))
      (ok true)
    )
  )
)

;; Private Functions
(define-private (get-maintenance-interval (equipment-type uint))
  (if (is-eq equipment-type EQUIPMENT-SPRINKLER)
    u31536000  ;; 1 year
    (if (is-eq equipment-type EQUIPMENT-FIRE-ALARM)
      u15768000  ;; 6 months
      (if (is-eq equipment-type EQUIPMENT-EXTINGUISHER)
        u31536000  ;; 1 year
        (if (is-eq equipment-type EQUIPMENT-HYDRANT)
          u63072000  ;; 2 years
          u31536000  ;; 1 year default
        )
      )
    )
  )
)

(define-private (update-building-summary (building-id (string-ascii 50)))
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    ;; This is a simplified version - in practice, you'd iterate through all equipment
    (map-set building-equipment-summary
      { building-id: building-id }
      {
        total-equipment: u1,  ;; Simplified
        operational-count: u1,
        maintenance-needed: u0,
        out-of-service: u0,
        last-updated: current-time
      }
    )
  )
)

;; Read-only Functions
(define-read-only (get-equipment (equipment-id uint))
  (map-get? equipment { equipment-id: equipment-id })
)

(define-read-only (get-maintenance-record (maintenance-id uint))
  (map-get? maintenance-records { maintenance-id: maintenance-id })
)

(define-read-only (get-building-summary (building-id (string-ascii 50)))
  (map-get? building-equipment-summary { building-id: building-id })
)

(define-read-only (is-authorized-technician (technician principal))
  (default-to false (get authorized (map-get? authorized-technicians { technician: technician })))
)

(define-read-only (get-next-equipment-id)
  (var-get next-equipment-id)
)

(define-read-only (get-next-maintenance-id)
  (var-get next-maintenance-id)
)
