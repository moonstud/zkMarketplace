;; ZK-Marketplace: Auction-Based Zero-Knowledge Proof Verification Platform
;; Verifiers bid on verification jobs in a competitive marketplace

;; ==============================================================================
;; CONSTANTS & ERROR CODES
;; ==============================================================================

(define-constant MARKETPLACE_OWNER tx-sender)
(define-constant ERR_FORBIDDEN (err u300))
(define-constant ERR_JOB_NOT_FOUND (err u301))
(define-constant ERR_INVALID_JOB (err u302))
(define-constant ERR_JOB_EXISTS (err u303))
(define-constant ERR_BID_TOO_LOW (err u304))
(define-constant ERR_VALIDATOR_NOT_FOUND (err u305))
(define-constant ERR_UNSUPPORTED_PROTOCOL (err u306))

;; ==============================================================================
;; DATA VARIABLES
;; ==============================================================================

(define-data-var minimum-bid uint u500000) ;; 0.5 STX in microSTX
(define-data-var job-sequence uint u1)
(define-data-var platform-enabled bool true)

;; ==============================================================================
;; DATA MAPS
;; ==============================================================================

;; Verification jobs posted by clients
(define-map verification-jobs
  { job-id: uint }
  {
    client: principal,
    protocol-type: (string-ascii 20),
    proof-data: (buff 32),
    input-parameters: (buff 1024),
    verification-key: (buff 512),
    max-budget: uint,
    winning-bid: uint,
    assigned-validator: (optional principal),
    is-completed: bool,
    result-verified: bool,
    posted-at: uint,
    bid-deadline: uint
  }
)

;; Market validators and their capabilities  
(define-map market-validators
  { validator: principal }
  {
    business-name: (string-ascii 56),
    expertise-areas: (list 12 (string-ascii 20)),
    success-rate: uint,
    jobs-completed: uint,
    average-rating: uint,
    is-available: bool
  }
)

;; Bid tracking for jobs
(define-map job-bids
  { job-id: uint, validator: principal }
  {
    bid-amount: uint,
    estimated-time: uint,
    bid-timestamp: uint
  }
)

;; Client marketplace activity
(define-map client-activity
  { client: principal }
  {
    jobs-posted: uint,
    successful-jobs: uint,
    total-spent: uint,
    last-activity: uint
  }
)

;; Protocol type definitions
(define-map protocol-configs
  { protocol: (string-ascii 20) }
  {
    minimum-fee: uint,
    complexity-rating: uint,
    avg-completion-time: uint,
    is-active: bool
  }
)

;; ==============================================================================
;; PRIVATE FUNCTIONS
;; ==============================================================================

(define-private (is-marketplace-owner)
  (is-eq tx-sender MARKETPLACE_OWNER)
)

(define-private (is-valid-protocol (protocol (string-ascii 20)))
  (is-some (map-get? protocol-configs { protocol: protocol }))
)

;; ==============================================================================
;; PUBLIC FUNCTIONS - MARKETPLACE SETUP
;; ==============================================================================

(define-public (initialize-marketplace)
  (begin
    (asserts! (is-marketplace-owner) ERR_FORBIDDEN)
    ;; Register common zk protocols
    (try! (add-protocol "stark" u600000 u8 u120))
    (try! (add-protocol "snark" u500000 u6 u100))
    (try! (add-protocol "bulletproof" u400000 u4 u80))
    (try! (add-protocol "sonic" u550000 u7 u110))
    (ok true)
  )
)

(define-public (add-protocol 
  (protocol (string-ascii 20))
  (minimum-fee uint)
  (complexity-rating uint)
  (avg-completion-time uint)
)
  (begin
    (asserts! (is-marketplace-owner) ERR_FORBIDDEN)
    (map-set protocol-configs
      { protocol: protocol }
      {
        minimum-fee: minimum-fee,
        complexity-rating: complexity-rating,
        avg-completion-time: avg-completion-time,
        is-active: true
      }
    )
    (ok true)
  )
)

(define-public (join-as-validator 
  (business-name (string-ascii 56))
  (expertise-areas (list 12 (string-ascii 20)))
)
  (begin
    (map-set market-validators
      { validator: tx-sender }
      {
        business-name: business-name,
        expertise-areas: expertise-areas,
        success-rate: u100, ;; Start at 100%
        jobs-completed: u0,
        average-rating: u0,
        is-available: true
      }
    )
    (ok true)
  )
)

;; ==============================================================================
;; PUBLIC FUNCTIONS - JOB MARKETPLACE
;; ==============================================================================

(define-public (post-verification-job
  (protocol-type (string-ascii 20))
  (proof-data (buff 32))
  (input-parameters (buff 1024))
  (verification-key (buff 512))
  (max-budget uint)
  (bidding-window uint)
)
  (let (
    (job-id (var-get job-sequence))
    (protocol-info (unwrap! (map-get? protocol-configs { protocol: protocol-type }) ERR_UNSUPPORTED_PROTOCOL))
    (min-required (get minimum-fee protocol-info))
  )
    (begin
      (asserts! (var-get platform-enabled) ERR_FORBIDDEN)
      (asserts! (>= max-budget min-required) ERR_BID_TOO_LOW)
      (asserts! (>= (stx-get-balance tx-sender) max-budget) ERR_BID_TOO_LOW)
      
      ;; Lock maximum budget
      (try! (stx-transfer? max-budget tx-sender (as-contract tx-sender)))
      
      ;; Create job posting
      (map-set verification-jobs
        { job-id: job-id }
        {
          client: tx-sender,
          protocol-type: protocol-type,
          proof-data: proof-data,
          input-parameters: input-parameters,
          verification-key: verification-key,
          max-budget: max-budget,
          winning-bid: u0,
          assigned-validator: none,
          is-completed: false,
          result-verified: false,
          posted-at: block-height,
          bid-deadline: (+ block-height bidding-window)
        }
      )
      
      ;; Update counters
      (var-set job-sequence (+ job-id u1))
      
      (ok job-id)
    )
  )
)

(define-public (submit-bid 
  (job-id uint)
  (bid-amount uint)
  (estimated-time uint)
)
  (let (
    (job-info (unwrap! (map-get? verification-jobs { job-id: job-id }) ERR_JOB_NOT_FOUND))
    (validator-info (unwrap! (map-get? market-validators { validator: tx-sender }) ERR_VALIDATOR_NOT_FOUND))
  )
    (begin
      (asserts! (get is-available validator-info) ERR_FORBIDDEN)
      (asserts! (< block-height (get bid-deadline job-info)) ERR_INVALID_JOB)
      (asserts! (not (get is-completed job-info)) ERR_JOB_EXISTS)
      (asserts! (<= bid-amount (get max-budget job-info)) ERR_BID_TOO_LOW)
      (asserts! (>= bid-amount (var-get minimum-bid)) ERR_BID_TOO_LOW)
      
      ;; Record bid
      (map-set job-bids
        { job-id: job-id, validator: tx-sender }
        {
          bid-amount: bid-amount,
          estimated-time: estimated-time,
          bid-timestamp: block-height
        }
      )
      
      (ok true)
    )
  )
)

(define-public (accept-bid 
  (job-id uint)
  (chosen-validator principal)
)
  (let (
    (job-info (unwrap! (map-get? verification-jobs { job-id: job-id }) ERR_JOB_NOT_FOUND))
    (bid-info (unwrap! (map-get? job-bids { job-id: job-id, validator: chosen-validator }) ERR_VALIDATOR_NOT_FOUND))
  )
    (begin
      (asserts! (is-eq tx-sender (get client job-info)) ERR_FORBIDDEN)
      (asserts! (< block-height (get bid-deadline job-info)) ERR_INVALID_JOB)
      (asserts! (not (get is-completed job-info)) ERR_JOB_EXISTS)
      
      ;; Assign job to validator
      (map-set verification-jobs
        { job-id: job-id }
        (merge job-info {
          assigned-validator: (some chosen-validator),
          winning-bid: (get bid-amount bid-info)
        })
      )
      
      (ok true)
    )
  )
)

(define-public (complete-verification 
  (job-id uint)
  (verification-successful bool)
)
  (let (
    (job-info (unwrap! (map-get? verification-jobs { job-id: job-id }) ERR_JOB_NOT_FOUND))
    (validator-info (unwrap! (map-get? market-validators { validator: tx-sender }) ERR_VALIDATOR_NOT_FOUND))
  )
    (begin
      (asserts! (is-eq (some tx-sender) (get assigned-validator job-info)) ERR_FORBIDDEN)
      (asserts! (not (get is-completed job-info)) ERR_JOB_EXISTS)
      
      ;; Mark job as completed
      (map-set verification-jobs
        { job-id: job-id }
        (merge job-info {
          is-completed: true,
          result-verified: verification-successful
        })
      )
      
      ;; Update validator stats
      (map-set market-validators
        { validator: tx-sender }
        (merge validator-info {
          jobs-completed: (+ (get jobs-completed validator-info) u1),
          success-rate: (if verification-successful 
            (get success-rate validator-info)
            (- (get success-rate validator-info) u5)
          )
        })
      )
      
      ;; Handle payments - pay validator and refund client
      (let (
        (winning-amount (get winning-bid job-info))
        (refund-amount (- (get max-budget job-info) winning-amount))
      )
        (try! (as-contract (stx-transfer? winning-amount tx-sender tx-sender)))
        (if (> refund-amount u0)
          (as-contract (stx-transfer? refund-amount tx-sender (get client job-info)))
          (ok verification-successful)
        )
      )
    )
  )
)

;; ==============================================================================
;; QUERY FUNCTIONS
;; ==============================================================================

(define-read-only (get-job-details (job-id uint))
  (map-get? verification-jobs { job-id: job-id })
)

(define-read-only (get-validator-profile (validator principal))
  (map-get? market-validators { validator: validator })
)

(define-read-only (get-bid-info (job-id uint) (validator principal))
  (map-get? job-bids { job-id: job-id, validator: validator })
)

(define-read-only (get-client-stats (client principal))
  (map-get? client-activity { client: client })
)

(define-read-only (get-protocol-details (protocol (string-ascii 20)))
  (map-get? protocol-configs { protocol: protocol })
)

(define-read-only (get-minimum-bid-amount)
  (var-get minimum-bid)
)

(define-read-only (is-job-verified (job-id uint))
  (match (map-get? verification-jobs { job-id: job-id })
    job-data (and (get is-completed job-data) (get result-verified job-data))
    false
  )
)

;; ==============================================================================
;; UTILITY FUNCTIONS
;; ==============================================================================

(define-public (withdraw-expired-job (job-id uint))
  (let (
    (job-info (unwrap! (map-get? verification-jobs { job-id: job-id }) ERR_JOB_NOT_FOUND))
  )
    (begin
      (asserts! (is-eq tx-sender (get client job-info)) ERR_FORBIDDEN)
      (asserts! (> block-height (get bid-deadline job-info)) ERR_INVALID_JOB)
      (asserts! (is-none (get assigned-validator job-info)) ERR_JOB_EXISTS)
      
      ;; Return locked funds to client
      (as-contract (stx-transfer? (get max-budget job-info) tx-sender (get client job-info)))
    )
  )
)

;; ==============================================================================
;; ADMIN FUNCTIONS
;; ==============================================================================

(define-public (update-minimum-bid (new-minimum uint))
  (begin
    (asserts! (is-marketplace-owner) ERR_FORBIDDEN)
    (var-set minimum-bid new-minimum)
    (ok true)
  )
)

(define-public (disable-marketplace)
  (begin
    (asserts! (is-marketplace-owner) ERR_FORBIDDEN)
    (var-set platform-enabled false)
    (ok true)
  )
)

(define-public (enable-marketplace)
  (begin
    (asserts! (is-marketplace-owner) ERR_FORBIDDEN)
    (var-set platform-enabled true)
    (ok true)
  )
)

(define-public (withdraw-platform-earnings (amount uint))
  (begin
    (asserts! (is-marketplace-owner) ERR_FORBIDDEN)
    (as-contract (stx-transfer? amount tx-sender MARKETPLACE_OWNER))
  )
)